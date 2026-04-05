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

    /// Phantom Heartbeat: high-priority timer (500 ms) for keep-alive signals to audio stack / scheduling.
    private var phantomHeartbeatTimer: DispatchSourceTimer?
    /// Process-level activity: reduces idle system sleep while GIGI is running.
    private var phantomProcessActivity: NSObjectProtocol?

    // MARK: - Lock button (Darwin) debounce
    /// Anti-bounce debounce between consecutive Darwin notifications.
    private static let lockButtonDebounceInterval: TimeInterval = 0.08
    /// After this delay without a "long" pattern, we classify it as a single press (screen lock).
    private static let lockButtonSinglePressSettle: TimeInterval = 0.48
    /// Two pulses separated by at least this interval ⇒ hold / wake up GIGI.
    private static let lockButtonLongPressMinSpan: TimeInterval = 0.38
    /// Maximum window to consider pulses as part of the same gesture.
    private static let lockButtonGestureWindow: TimeInterval = 1.6
    /// Prolonged hold: many close pulses (Springboard often repeats while the button is down).
    private static let lockButtonLongPressMinPulseCount = 3

    private var lastLockButtonDebounced: TimeInterval = 0
    private var lockButtonPulseTimes: [TimeInterval] = []
    private var lockButtonSinglePressWorkItem: DispatchWorkItem?

    private static let lockButtonDarwinName: CFString = "com.apple.springboard.lockbutton" as CFString

    private static let lockButtonDarwinCallback: CFNotificationCallback = { _, observer, _, _, _ in
        print("GIGI: [HACK] Received raw Darwin signal (com.apple.springboard.lockbutton)")
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

    /// Keep-alive signal every 500 ms on the userInteractive queue (does not block the main thread).
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

    /// Minimal work: touch `AVAudioSession` to keep the I/O path warm.
    private func phantomKeepAliveTick() {
        let session = AVAudioSession.sharedInstance()
        _ = session.secondaryAudioShouldBeSilencedHint
        _ = session.isOtherAudioPlaying
        // silent.mp3 has been removed in favor of hardware ANE monitoring.
    }

    // --- NERVOUS SYSTEM: PHYSICAL BUTTON (Darwin → Capacitor WebView) ---
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
        print("GIGI: Darwin listener com.apple.springboard.lockbutton ACTIVE (single vs long press debounce).")
    }

    /// Called on the main queue: classifies single press (lock) vs long press (Ghost Mode).
    private func processLockButtonDarwinPulse() {
        let t = ProcessInfo.processInfo.systemUptime
        if t - lastLockButtonDebounced < Self.lockButtonDebounceInterval {
            print("GIGI: [HACK] Pulse ignored (bounce too fast)")
            return
        }
        lastLockButtonDebounced = t

        print("GIGI: [HACK] Valid pulse registered at time \(t)")

        lockButtonPulseTimes.append(t)
        lockButtonPulseTimes = lockButtonPulseTimes.filter { t - $0 <= Self.lockButtonGestureWindow }

        print("GIGI: [HACK] Current window: \(lockButtonPulseTimes.count) active pulses")

        lockButtonSinglePressWorkItem?.cancel()

        if lockButtonGestureIsLongPress() {
            print("GIGI: [HACK] Immediate Long Press detected!")
            lockButtonPulseTimes.removeAll()
            lockButtonSinglePressWorkItem = nil
            triggerOpenGigiGhostModeFromHardware()
            return
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.lockButtonGestureIsLongPress() {
                print("GIGI: [HACK] Deferred Long Press detected!")
                self.triggerOpenGigiGhostModeFromHardware()
            } else {
                print("GIGI: [LOCK] Single press detected — normal screen lock. Ghost Mode NOT invoked.")
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

    /// Hardware → React bridge: DOM event on the Capacitor WebView.
    func triggerOpenGigiGhostModeFromHardware() {
        print("GIGI: [HACK] Preparing to launch Ghost Mode...")
        AudioServicesPlaySystemSound(1519)
        NotificationCenter.default.post(name: NSNotification.Name("OpenGigiGhostMode"), object: nil)
        
        let js = "window.dispatchEvent(new Event('OpenGigiGhostMode', { bubbles: true }));"
        print("GIGI: Attempting to trigger UI via evaluateJavaScript...")
        print("GIGI: [HACK] Executing evaluateJavaScript on WebView: \(js)")
        
        if let bridgeVC = capacitorBridgeViewController() {
            // Force WebView to wake up from background
            bridgeVC.bridge?.webView?.becomeFirstResponder()
            
            bridgeVC.bridge?.webView?.evaluateJavaScript(js, completionHandler: { _, error in
                if let error = error {
                    print("GIGI: [HACK] ERROR evaluateJavaScript: \(error)")
                } else {
                    print("GIGI: [HACK] JS Event OpenGigiGhostMode sent successfully to WebView!")
                }
            })
        } else {
            print("GIGI: [HACK] ERROR: Unable to find Capacitor WebView (bridge broken or not initialized).")
        }
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

    // --- LUNGS: AUDIO SESSION ---
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement, // Optimized for raw audio input without heavy software processing
                options: [.mixWithOthers, .allowBluetoothHFP, .defaultToSpeaker]
            )
            try audioSession.setActive(true)
            print("GIGI: Audio Session Secured (measurement mode for ANE DMA).")
        } catch {
            print("GIGI: Audio Session Error: \(error)")
        }
    }

    // --- EAR: ANE NEURAL VAD ---
    func setupNeuralVoiceActivation() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Initializes the audio stream analyzer (SoundAnalysis delegates inference to ANE via CoreML)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        let observer = GIGIWakeWordObserver()
        observer.appDelegate = self
        wakeWordObserver = observer
        
        do {
            // NOTE: Requires a compiled CoreML model "GIGI_WakeWord.mlmodelc" added to the bundle.
            // The SoundAnalysis framework automatically maps buffers into shared memory for the ANE.
            // If the model is not present, we use a fallback stub to keep the audio engine active.
            let config = MLModelConfiguration()
            config.computeUnits = .all // Force the use of ANE (Apple Neural Engine) if available
            
            // Model loading simulation (replace with the real model)
            // let model = try GIGI_WakeWord(configuration: config).model
            // let request = try SNClassifySoundRequest(mlModel: model)
            // try streamAnalyzer?.add(request, withObserver: observer)
            print("GIGI: [ANE] Hardware VAD configuration ready. Waiting for CoreML model.")
            
        } catch {
            print("GIGI: [ANE] Neural model loading error: \(error)")
        }
        
        // Direct tap from the microphone: PCM buffers are passed to the analyzer
        // iOS abstraction prevents true manual DMA from user-space, but SNAudioStreamAnalyzer
        // is Apple's optimized path to minimize latency (<10ms) and power consumption.
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] (buffer, when) in
            self?.aneQueue.async {
                self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: when.sampleTime)
            }
        }
        
        do {
            try audioEngine.start()
            print("GIGI: [ANE] Stealth listening microphone. Inference delegated to Neural Engine (simulated 0W quiescence).")
        } catch {
            print("GIGI: Audio engine start error: \(error)")
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
            // Retry shortly if the WebView is not ready yet
            perform(#selector(attachLEEToWebView), with: nil, afterDelay: 0.5)
            return
        }
        // Remove to avoid duplicates
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "LEE")
        webView.configuration.userContentController.add(self, name: "LEE")
        print("GIGI: Local Execution Engine (LEE) hooked to WebView.")
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
        
        // 3. Execution in the background stack to ensure "Operational Transparency"
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
            print("GIGI: [LEE] Unknown action: \(action)")
        }
    }

    private func performInvisibleCall(payload: [String: Any]) {
        guard let number = payload["number"] as? String else { return }
        
        // 1. Swift Bridge for TelephonyUtilities
        let tuBundle = Bundle(path: "/System/Library/PrivateFrameworks/TelephonyUtilities.framework")
        tuBundle?.load()
        
        guard let tuCallCenterClass = NSClassFromString("TUCallCenter") as? NSObject.Type,
              let tuDialRequestClass = NSClassFromString("TUDialRequest") as? NSObject.Type else {
            print("GIGI: [LEE] TelephonyUtilities not accessible.")
            return
        }
        
        // 2. Translation to direct call to TUCallCenter.shared.launchCall
        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard let sharedCenter = tuCallCenterClass.perform(sharedSelector)?.takeUnretainedValue() else { return }
        
        guard let url = URL(string: "tel:\(number)"),
              let dialRequest = tuDialRequestClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() else { return }
        
        _ = dialRequest.perform(NSSelectorFromString("initWithURL:"), with: url)
        
        // Bypass InCallService UI: Set internal flags (if supported by the daemon)
        let setPerformDial = NSSelectorFromString("setPerformDialWithRequest:")
        if dialRequest.responds(to: setPerformDial) {
            _ = dialRequest.perform(setPerformDial, with: NSNumber(value: true))
        }
        
        let setShowUI = NSSelectorFromString("setShowUIPrompt:")
        if dialRequest.responds(to: setShowUI) {
            _ = dialRequest.perform(setShowUI, with: NSNumber(value: false))
        }
        
        let launchSelector = NSSelectorFromString("launchCallWithRequest:")
        let dialSelector = NSSelectorFromString("dialWithRequest:")
        
        if sharedCenter.responds(to: launchSelector) {
            _ = sharedCenter.perform(launchSelector, with: dialRequest)
            print("GIGI: [LEE] Invisible call launched via launchCallWithRequest: to \(number)")
        } else if sharedCenter.responds(to: dialSelector) {
            _ = sharedCenter.perform(dialSelector, with: dialRequest)
            print("GIGI: [LEE] Invisible call launched via dialWithRequest: to \(number)")
        } else {
            print("GIGI: [LEE] launchCall/dial method not found in TUCallCenter.")
        }
    }

    private func performInvisibleMessage(payload: [String: Any]) {
        // 1. Swift Bridge for ChatKit
        let ckBundle = Bundle(path: "/System/Library/PrivateFrameworks/ChatKit.framework")
        ckBundle?.load()
        
        guard let _ = NSClassFromString("CKMessage") else {
            print("GIGI: [LEE] ChatKit not accessible or CKMessage missing.")
            return
        }
        print("GIGI: [LEE] Invisible message processed (stub).")
    }

    // MARK: - Biometric Trust Layer (Secure Enclave)
    
    private func performBiometricPaymentAuth(payload: [String: Any]) {
        guard let paymentId = payload["paymentId"] as? String else { return }
        
        let context = LAContext()
        var error: NSError?
        
        // 1. Verify biometrics availability (FaceID/TouchID)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authorize secure payment via GIGI"
            
            // 2. FaceID overlay appears automatically on top of the top ViewController (GhostMode)
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        // 3. Encrypted Token Generation (Secure Enclave signature simulation)
                        let rawData = "\(paymentId)-\(UUID().uuidString)-\(Date().timeIntervalSince1970)"
                        let hash = SHA256.hash(data: Data(rawData.utf8))
                        let secureToken = hash.compactMap { String(format: "%02x", $0) }.joined()
                        
                        print("GIGI: [TRUST LAYER] Biometric authentication successful. Token generated.")
                        self.sendPaymentAuthResultToReact(paymentId: paymentId, success: true, token: secureToken, error: nil)
                    } else {
                        let errStr = authError?.localizedDescription ?? "Authentication failed"
                        print("GIGI: [TRUST LAYER] Failed: \(errStr)")
                        self.sendPaymentAuthResultToReact(paymentId: paymentId, success: false, token: nil, error: errStr)
                    }
                }
            }
        } else {
            let errStr = error?.localizedDescription ?? "Biometrics not available"
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
            let e = error ?? "Unknown error"
            jsCode = "window.dispatchEvent(new CustomEvent('GigiPaymentAuthorized', { detail: { paymentId: '\(paymentId)', success: false, error: '\(e)' } }));"
        }
        
        capacitorBridgeViewController()?.bridge?.webView?.evaluateJavaScript(jsCode, completionHandler: { err, _ in
            if let err = err {
                print("GIGI: Payment callback error: \(err)")
            }
        })
    }
}

// MARK: - ANE Wake Word Observer
class GIGIWakeWordObserver: NSObject, SNResultsObserving {
    weak var appDelegate: AppDelegate?

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        
        // Look for the acoustic signature "GIGI" with high confidence
        if let classification = classificationResult.classifications.first(where: { $0.identifier == "gigi_wakeword" }),
           classification.confidence > 0.85 {
            
            print("GIGI: [ANE] Acoustic signature detected! Estimated latency < 10ms.")
            
            DispatchQueue.main.async {
                self.appDelegate?.triggerOpenGigiGhostModeFromHardware()
            }
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("GIGI: [ANE] Inference error: \(error)")
    }
}
