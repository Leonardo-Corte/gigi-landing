import UIKit
import Capacitor
import AVFoundation
import AudioToolbox
import WebKit
import SoundAnalysis

/// Native shell for GIGI: bubble window, voice activity (VAD), and WebView trigger only.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var bridge: CAPBridgeViewController? {
        return window?.rootViewController as? CAPBridgeViewController
    }

    let audioEngine = AVAudioEngine()

    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var wakeWordObserver: NSObject?
    private let aneQueue = DispatchQueue(label: "app.killsiri.gigi.ane", qos: .userInteractive)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if window == nil {
            let w = UIWindow(frame: UIScreen.main.bounds)
            w.rootViewController = CAPBridgeViewController()
            window = w
        }
        setupSystemOverlayMode()
        window?.makeKeyAndVisible()
        setupAudioSession()
        setupNeuralVoiceActivation()
        setupGigiBridge()

        return true
    }

    // MARK: - Bubble window (overlay)

    private func setupSystemOverlayMode() {
        guard let window = window else { return }

        let screenBounds = UIScreen.main.bounds
        let bubbleSize: CGFloat = 100
        let bottomPadding: CGFloat = 50

        window.frame = CGRect(
            x: (screenBounds.width - bubbleSize) / 2,
            y: screenBounds.height - bubbleSize - bottomPadding,
            width: bubbleSize,
            height: bubbleSize
        )
        window.layer.cornerRadius = bubbleSize / 2
        window.clipsToBounds = true
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear
        window.isOpaque = false
        window.alpha = 0
        window.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)

        if let bridgeVC = capacitorBridgeViewController() {
            bridgeVC.view.backgroundColor = .clear
            bridgeVC.view.isOpaque = false
            bridgeVC.bridge?.webView?.backgroundColor = .clear
            bridgeVC.bridge?.webView?.isOpaque = false
            bridgeVC.bridge?.webView?.scrollView.backgroundColor = .clear
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        triggerGhostMode()
    }

    // MARK: - Trigger bubble + JS event

    func triggerGhostMode() {
        AudioServicesPlaySystemSound(1519)
        NotificationCenter.default.post(name: NSNotification.Name("OpenGigiGhostMode"), object: nil)

        DispatchQueue.main.async {
            guard let window = self.window else { return }
            window.makeKeyAndVisible()
            UIView.animate(
                withDuration: 0.6,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: .curveEaseOut,
                animations: {
                    window.alpha = 1
                    window.transform = .identity
                }
            )
        }

        let js = "window.focus(); window.dispatchEvent(new CustomEvent('OpenGigiGhostMode'));"
        if let bridgeVC = capacitorBridgeViewController() {
            bridgeVC.bridge?.webView?.becomeFirstResponder()
            bridgeVC.bridge?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    private func capacitorBridgeViewController() -> CAPBridgeViewController? {
        if let root = bridge { return root }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for root in windowScene.windows.map(\.rootViewController) {
                if let cap = root as? CAPBridgeViewController { return cap }
            }
        }
        return nil
    }

    // MARK: - Audio + VAD

    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.mixWithOthers, .allowBluetoothHFP, .defaultToSpeaker]
            )
            try session.setActive(true)
        } catch {
            print("GIGI: Audio session error: \(error)")
        }
    }

    func setupNeuralVoiceActivation() {
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        streamAnalyzer = SNAudioStreamAnalyzer(format: recordingFormat)
        let observer = GIGIWakeWordObserver()
        observer.appDelegate = self
        wakeWordObserver = observer

        // Add a CoreML SNClassifySoundRequest here when GIGI_WakeWord.mlmodelc is in the bundle.

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [weak self] buffer, when in
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let n = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<n {
                sum += channelData[i] * channelData[i]
            }
            let rms = sqrt(sum / Float(max(n, 1)))
            if rms > 0.05 {
                print("GIGI: [VAD] level=\(rms)")
            }
            self?.aneQueue.async {
                self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: when.sampleTime)
            }
        }

        do {
            try audioEngine.start()
        } catch {
            print("GIGI: Audio engine error: \(error)")
        }
    }

    // MARK: - Minimal JS → native bridge (hide bubble only)

    private func setupGigiBridge() {
        DispatchQueue.main.async { [weak self] in
            self?.attachGigiBridge()
        }
    }

    @objc private func attachGigiBridge() {
        guard let webView = capacitorBridgeViewController()?.bridge?.webView else {
            perform(#selector(attachGigiBridge), with: nil, afterDelay: 0.35)
            return
        }
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "GigiBridge")
        webView.configuration.userContentController.add(self, name: "GigiBridge")
    }
}

extension AppDelegate: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "GigiBridge",
              let jsonString = message.body as? String,
              let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = obj["action"] as? String,
              action == "hideBubble" else { return }

        DispatchQueue.main.async {
            guard let window = self.window else { return }
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
                window.alpha = 0
                window.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }, completion: { _ in
                window.isHidden = true
            })
        }
    }
}

// MARK: - SoundAnalysis observer (wake word when model is wired)

class GIGIWakeWordObserver: NSObject, SNResultsObserving {
    weak var appDelegate: AppDelegate?

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }
        if let c = classificationResult.classifications.first(where: { $0.identifier == "gigi_wakeword" }),
           c.confidence > 0.85 {
            DispatchQueue.main.async {
                self.appDelegate?.triggerGhostMode()
            }
        }
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("GIGI: SoundAnalysis error: \(error)")
    }
}
