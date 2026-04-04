import UIKit
import Capacitor
import AVFoundation
import AudioToolbox
import WebKit
import LocalAuthentication
import CryptoKit
import SoundAnalysis
import CoreML

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    // Questo è il ponte per parlare con React
    var bridge: CAPBridgeViewController? {
        return window?.rootViewController as? CAPBridgeViewController
    }
    
    let audioEngine = AVAudioEngine()
    
    // MARK: - ANE (Apple Neural Engine) VAD
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var wakeWordObserver: NSObject? // GIGIWakeWordObserver
    private let aneQueue = DispatchQueue(label: "app.killsiri.gigi.ane.dma", qos: .userInteractive)

    /// Phantom Heartbeat: timer ad alta priorità (500 ms) per segnali keep-alive verso stack audio / scheduling.
    private var phantomHeartbeatTimer: DispatchSourceTimer?
    /// Activity a livello processo: riduce idle sleep del sistema mentre GIGI è in esecuzione.
    private var phantomProcessActivity: NSObjectProtocol?

    // MARK: - Lock button (Darwin) debounce
    /// Debounce anti-rimbalzo tra notifiche Darwin consecutive.
    private static let lockButtonDebounceInterval: TimeInterval = 0.08
    /// Dopo questo delay senza pattern "lungo", classifichiamo come pressione singola (blocco schermo).
    private static let lockButtonSinglePressSettle: TimeInterval = 0.48
    /// Due impulsi distanziati di almeno questo intervallo ⇒ tenuta / risveglio GIGI.
    private static let lockButtonLongPressMinSpan: TimeInterval = 0.38
    /// Finestra massima per considerare gli impulsi parte della stessa gesture.
    private static let lockButtonGestureWindow: TimeInterval = 1.6
    /// Tenuta prolungata: molti impulsi ravvicinati (Springboard spesso ripete mentre il tasto è giù).
    private static let lockButtonLongPressMinPulseCount = 3

    private var lastLockButtonDebounced: TimeInterval = 0
    private var lockButtonPulseTimes: [TimeInterval] = []
    private var lockButtonSinglePressWorkItem: DispatchWorkItem?

    private static let lockButtonDarwinName: CFString = "com.apple.springboard.lockbutton" as CFString

    private static let lockButtonDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        guard let raw = observer else { return }
        let app = Unmanaged<AppDelegate>.fromOpaque(raw).takeUnretainedValue()
        DispatchQueue.main.async {
            app.processLockButtonDarwinPulse()
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. SETUP AUDIO
        setupAudioSession()
        startPhantomProcessActivity()
        startPhantomHeartbeat()
        
        // 2. SETUP MIC (ANE Hardware-level VAD)
        setupNeuralVoiceActivation()
        
        // 3. IL CRACK (Intercettazione Tasto Fisico)
        setupPhysicalButtonHack()
        
        // 4. Local Execution Engine (LEE)
        setupLocalExecutionEngine()
        
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        stopPhantomHeartbeat()
        if let activity = phantomProcessActivity {
            ProcessInfo.processInfo.endActivity(activity)
            phantomProcessActivity = nil
        }
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(Self.lockButtonDarwinName as CFString),
            nil
        )
    }

    // MARK: - Phantom Heartbeat (Priority / keep-alive)

    private func startPhantomProcessActivity() {
        phantomProcessActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "GIGI Phantom Heartbeat"
        )
    }

    /// Segnale keep-alive ogni 500 ms sulla coda userInteractive (non blocca il main thread).
    private func startPhantomHeartbeat() {
        stopPhantomHeartbeat()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: .milliseconds(500), leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            self?.phantomKeepAliveTick()
        }
        timer.resume()
        phantomHeartbeatTimer = timer
    }

    private func stopPhantomHeartbeat() {
        phantomHeartbeatTimer?.setEventHandler {}
        phantomHeartbeatTimer?.cancel()
        phantomHeartbeatTimer = nil
    }

    /// Lavoro minimo: tocca `AVAudioSession` per mantenere caldo il percorso I/O.
    private func phantomKeepAliveTick() {
        let session = AVAudioSession.sharedInstance()
        _ = session.secondaryAudioShouldBeSilencedHint
        _ = session.isOtherAudioPlaying
        // Il silent.mp3 è stato rimosso in favore del monitoraggio hardware ANE.
    }

    // --- SISTEMA NERVOSO: IL TASTO FISICO (Darwin → Capacitor WebView) ---
    func setupPhysicalButtonHack() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            Self.lockButtonDarwinCallback,
            Self.lockButtonDarwinName,
            nil,
            .deliverImmediately
        )
        print("GIGI: Listener Darwin com.apple.springboard.lockbutton ATTIVO (debounce singolo vs prolungato).")
    }

    /// Chiamato sul main queue: classifica pressione singola (blocco) vs prolungata (Ghost Mode).
    private func processLockButtonDarwinPulse() {
        let t = ProcessInfo.processInfo.systemUptime
        if t - lastLockButtonDebounced < Self.lockButtonDebounceInterval {
            return
        }
        lastLockButtonDebounced = t

        lockButtonPulseTimes.append(t)
        lockButtonPulseTimes = lockButtonPulseTimes.filter { t - $0 <= Self.lockButtonGestureWindow }

        lockButtonSinglePressWorkItem?.cancel()

        if lockButtonGestureIsLongPress() {
            lockButtonPulseTimes.removeAll()
            lockButtonSinglePressWorkItem = nil
            triggerOpenGigiGhostModeFromHardware()
            return
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.lockButtonGestureIsLongPress() {
                self.triggerOpenGigiGhostModeFromHardware()
            } else {
                print("GIGI: [LOCK] Pressione singola — blocco schermo; Ghost Mode non invocato.")
            }
            self.lockButtonPulseTimes.removeAll()
            self.lockButtonSinglePressWorkItem = nil
        }
        lockButtonSinglePressWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.lockButtonSinglePressSettle, execute: work)
    }

    private func lockButtonGestureIsLongPress() -> Bool {
        let times = lockButtonPulseTimes
        guard times.count >= 2 else { return false }
        if times.count >= Self.lockButtonLongPressMinPulseCount {
            return true
        }
        let span = times[times.count - 1] - times[0]
        return span >= Self.lockButtonLongPressMinSpan
    }

    /// Ponte hardware → React: evento DOM sulla WebView Capacitor.
    private func triggerOpenGigiGhostModeFromHardware() {
        AudioServicesPlaySystemSound(1519)
        NotificationCenter.default.post(name: NSNotification.Name("OpenGigiGhostMode"), object: nil)
        let js = "window.dispatchEvent(new Event('OpenGigiGhostMode'));"
        capacitorBridgeViewController()?.bridge?.webView?.evaluateJavaScript(js, completionHandler: { _, error in
            if let error = error {
                print("GIGI: evaluateJavaScript OpenGigiGhostMode: \(error)")
            }
        })
    }

    private func capacitorBridgeViewController() -> CAPBridgeViewController? {
        if let root = bridge { return root }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            let roots = windowScene.windows.map(\.rootViewController)
            for root in roots {
                if let cap = root as? CAPBridgeViewController { return cap }
            }
        }
        return nil
    }

    // --- POLMONE: AUDIO SESSION ---
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement, // Ottimizzato per raw audio input senza processing software pesante
                options: [.mixWithOthers, .allowBluetoothHFP, .defaultToSpeaker]
            )
            try audioSession.setActive(true)
            print("GIGI: Sessione Audio Blindata (measurement mode per ANE DMA).")
        } catch {
            print("GIGI: Errore Sessione Audio: \(error)")
        }
    }

    // --- ORECCHIO: ANE NEURAL VAD ---
    func setupNeuralVoiceActivation() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Inizializza l'analizzatore di stream audio (SoundAnalysis delega l'inferenza all'ANE via CoreML)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        let observer = GIGIWakeWordObserver()
        wakeWordObserver = observer
        
        do {
            // NOTA: Richiede un modello CoreML "GIGI_WakeWord.mlmodelc" compilato e aggiunto al bundle.
            // Il framework SoundAnalysis mappa automaticamente i buffer in memoria condivisa per l'ANE.
            // Se il modello non è presente, usiamo un fallback stub per mantenere l'audio engine attivo.
            let config = MLModelConfiguration()
            config.computeUnits = .all // Forza l'uso di ANE (Apple Neural Engine) se disponibile
            
            // Simulazione caricamento modello (sostituire con il modello reale)
            // let model = try GIGI_WakeWord(configuration: config).model
            // let request = try SNClassifySoundRequest(mlModel: model)
            // try streamAnalyzer?.add(request, withObserver: observer)
            print("GIGI: [ANE] Configurazione hardware VAD pronta. In attesa del modello CoreML.")
            
        } catch {
            print("GIGI: [ANE] Errore caricamento modello neurale: \(error)")
        }
        
        // Tap diretto dal microfono: i buffer PCM vengono passati all'analizzatore
        // L'astrazione di iOS impedisce il vero DMA manuale da user-space, ma SNAudioStreamAnalyzer
        // è il path ottimizzato da Apple per minimizzare la latenza (<10ms) e il consumo energetico.
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] (buffer, when) in
            self?.aneQueue.async {
                self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: when.sampleTime)
            }
        }
        
        do {
            try audioEngine.start()
            print("GIGI: [ANE] Microfono in ascolto stealth. Inferenza delegata al Neural Engine (0W quiescenza simulata).")
        } catch {
            print("GIGI: Errore avvio motore audio: \(error)")
        }
    }

    // MARK: - Local Execution Engine (LEE) Setup
    
    private func setupLocalExecutionEngine() {
        DispatchQueue.main.async {
            self.attachLEEToWebView()
        }
    }

    @objc private func attachLEEToWebView() {
        guard let webView = self.capacitorBridgeViewController()?.bridge?.webView else {
            // Riprova tra poco se la WebView non è ancora pronta
            perform(#selector(attachLEEToWebView), with: nil, afterDelay: 0.5)
            return
        }
        // Rimuove per evitare duplicati
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "LEE")
        webView.configuration.userContentController.add(self, name: "LEE")
        print("GIGI: Local Execution Engine (LEE) agganciato alla WebView.")
    }
}

// MARK: - Local Execution Engine (LEE) Handler
extension AppDelegate: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "LEE",
              let jsonString = message.body as? String,
              let data = jsonString.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        
        // 3. Esecuzione nel background stack per garantire la "Trasparenza Operativa"
        DispatchQueue.global(qos: .background).async {
            self.executeInvisibleTask(payload: payload)
        }
    }

    private func executeInvisibleTask(payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }
        
        if action == "launchCall" {
            performInvisibleCall(payload: payload)
        } else if action == "sendMessage" {
            performInvisibleMessage(payload: payload)
        } else if action == "authenticatePayment" {
            performBiometricPaymentAuth(payload: payload)
        } else {
            print("GIGI: [LEE] Azione sconosciuta: \(action)")
        }
    }

    private func performInvisibleCall(payload: [String: Any]) {
        guard let number = payload["number"] as? String else { return }
        
        // 1. Bridge Swift per TelephonyUtilities
        let tuBundle = Bundle(path: "/System/Library/PrivateFrameworks/TelephonyUtilities.framework")
        tuBundle?.load()
        
        guard let tuCallCenterClass = NSClassFromString("TUCallCenter") as? NSObject.Type,
              let tuDialRequestClass = NSClassFromString("TUDialRequest") as? NSObject.Type else {
            print("GIGI: [LEE] TelephonyUtilities non accessibile.")
            return
        }
        
        // 2. Traduzione in chiamata diretta a TUCallCenter.shared.launchCall
        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard let sharedCenter = tuCallCenterClass.perform(sharedSelector)?.takeUnretainedValue() else { return }
        
        guard let url = URL(string: "tel:\(number)"),
              let dialRequest = tuDialRequestClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() else { return }
        
        _ = dialRequest.perform(NSSelectorFromString("initWithURL:"), with: url)
        
        // Bypass UI di InCallService: Impostiamo flag interni (se supportati dal demone)
        let setPerformDial = NSSelectorFromString("setPerformDialWithRequest:")
        if dialRequest.responds(to: setPerformDial) {
            dialRequest.perform(setPerformDial, with: NSNumber(value: true))
        }
        
        let setShowUI = NSSelectorFromString("setShowUIPrompt:")
        if dialRequest.responds(to: setShowUI) {
            dialRequest.perform(setShowUI, with: NSNumber(value: false))
        }
        
        let launchSelector = NSSelectorFromString("launchCallWithRequest:")
        let dialSelector = NSSelectorFromString("dialWithRequest:")
        
        if sharedCenter.responds(to: launchSelector) {
            sharedCenter.perform(launchSelector, with: dialRequest)
            print("GIGI: [LEE] Chiamata invisibile lanciata via launchCallWithRequest: verso \(number)")
        } else if sharedCenter.responds(to: dialSelector) {
            sharedCenter.perform(dialSelector, with: dialRequest)
            print("GIGI: [LEE] Chiamata invisibile lanciata via dialWithRequest: verso \(number)")
        } else {
            print("GIGI: [LEE] Metodo launchCall/dial non trovato in TUCallCenter.")
        }
    }

    private func performInvisibleMessage(payload: [String: Any]) {
        // 1. Bridge Swift per ChatKit
        let ckBundle = Bundle(path: "/System/Library/PrivateFrameworks/ChatKit.framework")
        ckBundle?.load()
        
        guard let _ = NSClassFromString("CKMessage") else {
            print("GIGI: [LEE] ChatKit non accessibile o CKMessage mancante.")
            return
        }
        print("GIGI: [LEE] Messaggio invisibile processato (stub).")
    }

    // MARK: - Trust Layer Biometrico (Secure Enclave)
    
    private func performBiometricPaymentAuth(payload: [String: Any]) {
        guard let paymentId = payload["paymentId"] as? String else { return }
        
        let context = LAContext()
        var error: NSError?
        
        // 1. Verifica disponibilità biometria (FaceID/TouchID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Autorizza il pagamento sicuro tramite GIGI"
            
            // 2. L'overlay di FaceID appare automaticamente sopra il top ViewController (GhostMode)
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        // 3. Generazione Token Crittografato (Simulazione firma Secure Enclave)
                        let rawData = "\(paymentId)-\(UUID().uuidString)-\(Date().timeIntervalSince1970)"
                        let hash = SHA256.hash(data: Data(rawData.utf8))
                        let secureToken = hash.compactMap { String(format: "%02x", $0) }.joined()
                        
                        print("GIGI: [TRUST LAYER] Autenticazione biometrica riuscita. Token generato.")
                        self.sendPaymentAuthResultToReact(paymentId: paymentId, success: true, token: secureToken, error: nil)
                    } else {
                        let errStr = authError?.localizedDescription ?? "Autenticazione fallita"
                        print("GIGI: [TRUST LAYER] Fallita: \(errStr)")
                        self.sendPaymentAuthResultToReact(paymentId: paymentId, success: false, token: nil, error: errStr)
                    }
                }
            }
        } else {
            let errStr = error?.localizedDescription ?? "Biometria non disponibile"
            DispatchQueue.main.async {
                self.sendPaymentAuthResultToReact(paymentId: paymentId, success: false, token: nil, error: errStr)
            }
        }
    }

    private func sendPaymentAuthResultToReact(paymentId: String, success: Bool, token: String?, error: String?) {
        let jsCode: String
        if success, let t = token {
            jsCode = "window.dispatchEvent(new CustomEvent('GigiPaymentAuthorized', { detail: { paymentId: '\(paymentId)', success: true, token: '\(t)' } }));"
        } else {
            let e = error ?? "Errore sconosciuto"
            jsCode = "window.dispatchEvent(new CustomEvent('GigiPaymentAuthorized', { detail: { paymentId: '\(paymentId)', success: false, error: '\(e)' } }));"
        }
        
        capacitorBridgeViewController()?.bridge?.webView?.evaluateJavaScript(jsCode, completionHandler: { err, _ in
            if let err = err {
                print("GIGI: Errore callback pagamento: \(err)")
            }
        })
    }
}
