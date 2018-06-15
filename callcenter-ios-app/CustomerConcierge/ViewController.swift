//
//  ViewController.swift
//  Twilio Voice with CallKit Quickstart - Swift
//
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit
import AVFoundation
import PushKit
import CallKit
import TwilioVoice

let baseURLString = "https://conciergevoiceserver.mybluemix.net"
let accessTokenEndpoint = "/accessToken"
var identity = ""
var agent = ""
var defaults = UserDefaults.standard
var yourPhone = ""
var agentPhone = ""
var industry = ""
let uuid = UUID().uuidString

class ViewController: UIViewController, PKPushRegistryDelegate, TVONotificationDelegate, TVOCallDelegate, CXProviderDelegate, UITextFieldDelegate, UIWebViewDelegate {

    @IBOutlet weak var placeCallButton: UIButton!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var callControlView: UIView!
    @IBOutlet weak var muteSwitch: UISwitch!
    @IBOutlet weak var speakerSwitch: UISwitch!
    @IBOutlet weak var watsonWeb: UIWebView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func defaultsChanged(notification:NSNotification){
        if let newDefaults = notification.object as? UserDefaults {
            yourPhone = newDefaults.string(forKey: "yourPhone")!
            agentPhone = newDefaults.string(forKey: "agentPhone")!
            industry = newDefaults.string(forKey: "subIndustry")!
            loadPage()
        }
    }
    func loadPage() {
        let url = URL(string: "https://customerconcierge.mybluemix.net/demo?yourPhone=" + yourPhone + "&agentPhone=" + agentPhone + "&industry=" + industry)!
        let urlRequest: URLRequest = URLRequest(url: url)
            self.watsonWeb!.loadRequest(urlRequest)
    }
    
    var deviceTokenString:String?

    var voipRegistry:PKPushRegistry

    var incomingAlertController: UIAlertController?

    var callInvite:TVOCallInvite?
    var call:TVOCall?
    var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil

    let callKitProvider:CXProvider
    let callKitCallController:CXCallController
    
    
    
    
    required init?(coder aDecoder: NSCoder) {
        voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        TwilioVoice.logLevel = .verbose
        
        let configuration = CXProviderConfiguration(localizedName: "Customer Concierge")
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        if let callKitIcon = UIImage(named: "iconMask80") {
            configuration.iconTemplateImageData = UIImagePNGRepresentation(callKitIcon)
        }

        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()

        super.init(coder: aDecoder)

        callKitProvider.setDelegate(self, queue: nil)
        
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
    }
    
    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        callKitProvider.invalidate()
    }
    func webViewDidFinishLoad(_ watsonWeb: UIWebView) {
        
        let scrollableSize = CGSize(width: view.frame.size.width-30, height: watsonWeb.scrollView.contentSize.height)
        self.watsonWeb?.scrollView.contentSize = scrollableSize
        self.watsonWeb?.scrollView.bounces = false
        
    }
    override func viewDidLoad() {
        yourPhone = defaults.string(forKey: "yourPhone")!
        agentPhone = defaults.string(forKey: "agentPhone")!
        industry = defaults.string(forKey: "subIndustry")!
        watsonWeb?.delegate = self
        loadPage()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        toggleUIState(isEnabled: true, showCallControl: false)
        self.placeCallButton.imageView?.contentMode = UIViewContentMode.scaleAspectFit
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func fetchAccessToken() -> String? {
        identity = yourPhone
        
        let endpointWithIdentity = String(format: "%@?identity=%@", accessTokenEndpoint, identity)
        guard let accessTokenURL = URL(string: baseURLString + endpointWithIdentity + "&agent=" + agentPhone) else {
            return nil
        }

        return try? String.init(contentsOf: accessTokenURL, encoding: .utf8)
    }
    
    func toggleUIState(isEnabled: Bool, showCallControl: Bool) {
        placeCallButton.isEnabled = isEnabled
        if (showCallControl) {
            callControlView.isHidden = false
            muteSwitch.isOn = false
            speakerSwitch.isOn = true
        } else {
            callControlView.isHidden = true
        }
    }

    @IBAction func placeCall(_ sender: UIButton) {
        if (self.call != nil && self.call?.state == .connected) {
            self.call?.disconnect()
            self.toggleUIState(isEnabled: false, showCallControl: false)
        } else {
            let uuid = UUID()
            let handle = "Concierge"
            if (yourPhone == "12223334444"){
                let alert = UIAlertController(title: "Update Settings", message: "Please update your app settings to include your phone number and an agent phone number.  \nInclude the country code and area code", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in }))
                self.present(alert, animated: true, completion: nil)
            }else{
                let resp = getService("https://conciergevoiceserver.mybluemix.net/checkNumber?number=" + yourPhone)
                if ( resp == "1"){
                    NSLog("Caller ID is registered")
                    performStartCallAction(uuid: uuid, handle: handle)
                }else{
                    NSLog("Caller ID is not registered")
                    let confCode = getService("https://conciergevoiceserver.mybluemix.net/registerNumber?number=" + yourPhone)!
                    NSLog("Presenting confirmation code: " + confCode)
                    let alert = UIAlertController(title: "Register Number", message: "First time users need to register their numbers with the service. We will call you in 10 seconds. \n\nPlease enter code: \n" + confCode, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func getService(_ url : String) -> String? {
        var retval = ""
        var response: URLResponse?
        let url = URL(string: url)!
        let request: URLRequest = URLRequest(url: url)
        var urlData: Data?
        do {
            urlData = try NSURLConnection.sendSynchronousRequest(request, returning:&response)
        } catch _ as NSError {
            urlData = nil
        }
        if ( urlData != nil ) {
            let res = response as! HTTPURLResponse?;
            if ((res?.statusCode)! >= 200 && (res?.statusCode)! < 300)
            {
                let base64Encoded = urlData!.base64EncodedString()
                let decodedData = Data(base64Encoded: base64Encoded)!
                retval = String(data: decodedData, encoding: .utf8)!
            }
        }
        return retval
    }
    
    @IBAction func muteSwitchToggled(_ sender: UISwitch) {
        if let call = call {
            call.isMuted = sender.isOn
        } else {
            NSLog("No active call to be muted")
        }
    }
    
    @IBAction func speakerSwitchToggled(_ sender: UISwitch) {
        toggleAudioRoute(toSpeaker: sender.isOn)
    }
    

    // MARK: PKPushRegistryDelegate
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        NSLog("pushRegistry:didUpdatePushCredentials:forType:")
        
        if (type != .voIP) {
            return
        }

        guard let accessToken = fetchAccessToken() else {
            return
        }
        
        let deviceToken = (credentials.token as NSData).description

        TwilioVoice.register(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
            if let error = error {
                NSLog("An error occurred while registering: \(error.localizedDescription)")
            }
            else {
                NSLog("Successfully registered for VoIP push notifications.")
            }
        }

        self.deviceTokenString = deviceToken
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenForType type: PKPushType) {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
        
        if (type != .voIP) {
            return
        }
        
        guard let deviceToken = deviceTokenString, let accessToken = fetchAccessToken() else {
            return
        }
        
        TwilioVoice.unregister(withAccessToken: accessToken, deviceToken: deviceToken) { (error) in
            if let error = error {
                NSLog("An error occurred while unregistering: \(error.localizedDescription)")
            }
            else {
                NSLog("Successfully unregistered from VoIP push notifications.")
            }
        }
        
        self.deviceTokenString = nil
    }

    /**
     * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
     * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:")

        if (type == PKPushType.voIP) {
            TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self)
        }
    }

    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")
        
        if (type == PKPushType.voIP) {
            TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self)
        }
        
        completion()
    }

    // MARK: TVONotificaitonDelegate
    func callInviteReceived(_ callInvite: TVOCallInvite) {
        if (callInvite.state == .pending) {
            handleCallInviteReceived(callInvite)
        } else if (callInvite.state == .canceled) {
            handleCallInviteCanceled(callInvite)
        }
    }
    
    func handleCallInviteReceived(_ callInvite: TVOCallInvite) {
        NSLog("callInviteReceived:")
        
        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            NSLog("Already a pending incoming call invite.");
            NSLog("  >> Ignoring call from %@", callInvite.from);
            return;
        } else if (self.call != nil) {
            NSLog("Already an active call.");
            NSLog("  >> Ignoring call from %@", callInvite.from);
            return;
        }
        
        self.callInvite = callInvite

        reportIncomingCall(from: "Voice Bot", uuid: callInvite.uuid)
    }
    
    func handleCallInviteCanceled(_ callInvite: TVOCallInvite) {
        NSLog("callInviteCanceled:")
        
        performEndCallAction(uuid: callInvite.uuid)

        self.callInvite = nil
    }
    
    func notificationError(_ error: Error) {
        NSLog("notificationError: \(error.localizedDescription)")
    }
    
    
    // MARK: TVOCallDelegate
    func callDidConnect(_ call: TVOCall) {
        NSLog("callDidConnect:")
        
        self.call = call
        self.callKitCompletionCallback!(true)
        self.callKitCompletionCallback = nil
        
        self.placeCallButton.setImage(UIImage(named: "close.png")!, for: .normal)
        
        toggleUIState(isEnabled: true, showCallControl: true)

        toggleAudioRoute(toSpeaker: true)
    }
    
    func call(_ call: TVOCall, didFailToConnectWithError error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        
        if let completion = self.callKitCompletionCallback {
            completion(false)
        }

        performEndCallAction(uuid: call.uuid)
        callDisconnected()
    }
    
    func call(_ call: TVOCall, didDisconnectWithError error: Error?) {
        if let error = error {
            NSLog("Call failed: \(error.localizedDescription)")
        } else {
            NSLog("Call disconnected")
        }
        
        performEndCallAction(uuid: call.uuid)
        callDisconnected()
    }
    
    func callDisconnected() {
        self.call = nil
        self.callKitCompletionCallback = nil
        
        toggleUIState(isEnabled: true, showCallControl: false)
        self.placeCallButton.setImage(UIImage(named: "microphone.png")!, for: .normal)
        
    }
    
    
    // MARK: AVAudioSession
    func toggleAudioRoute(toSpeaker: Bool) {
        // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
        do {
            if (toSpeaker) {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
        } catch {
            NSLog(error.localizedDescription)
        }
    }

    
    // MARK: CXProviderDelegate
    func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        TwilioVoice.isAudioEnabled = true
    }

    func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        TwilioVoice.isAudioEnabled = true
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("provider:didDeactivateAudioSession:")
        TwilioVoice.isAudioEnabled = false
    }

    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")
        
        toggleUIState(isEnabled: false, showCallControl: false)

        TwilioVoice.configureAudioSession()
        TwilioVoice.isAudioEnabled = false

        
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())

        self.performVoiceCall(uuid: action.callUUID, client: "") { (success) in
            if (success) {
                provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
                action.fulfill()
            } else {
                action.fail()
            }
        }
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("provider:performAnswerCallAction:")

        // RCP: Workaround from https://forums.developer.apple.com/message/169511 suggests configuring audio in the
        //      completion block of the `reportNewIncomingCallWithUUID:update:completion:` method instead of in
        //      `provider:performAnswerCallAction:` per the WWDC examples.
        // TwilioVoice.configureAudioSession()
        
        assert(action.callUUID == self.callInvite?.uuid)
        
        TwilioVoice.isAudioEnabled = false
        self.performAnswerVoiceCall(uuid: action.callUUID) { (success) in
            if (success) {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")

        if (self.callInvite != nil && self.callInvite?.state == .pending) {
            self.callInvite?.reject()
            self.callInvite = nil
        } else if (self.call != nil) {
            self.call?.disconnect()
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provider:performSetHeldAction:")
        if (self.call?.state == .connected) {
            self.call?.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }

    // MARK: Call Kit Actions
    func performStartCallAction(uuid: UUID, handle: String) {
        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)

        callKitCallController.request(transaction)  { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                return
            }

            NSLog("StartCallAction transaction request successful")

            let callUpdate = CXCallUpdate()
            callUpdate.remoteHandle = callHandle
            callUpdate.supportsDTMF = true
            callUpdate.supportsHolding = true
            callUpdate.supportsGrouping = false
            callUpdate.supportsUngrouping = false
            callUpdate.hasVideo = false

            self.callKitProvider.reportCall(with: uuid, updated: callUpdate)
        }
    }

    func reportIncomingCall(from: String, uuid: UUID) {
        let callHandle = CXHandle(type: .generic, value: from)

        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = callHandle
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false

        callKitProvider.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if let error = error {
                NSLog("Failed to report incoming call successfully: \(error.localizedDescription).")
                return
            }

            NSLog("Incoming call successfully reported.")

            // RCP: Workaround per https://forums.developer.apple.com/message/169511
            TwilioVoice.configureAudioSession()
        }
    }

    func performEndCallAction(uuid: UUID) {

        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callKitCallController.request(transaction) { error in
            if let error = error {
                NSLog("EndCallAction transaction request failed: \(error.localizedDescription).")
                return
            }

            NSLog("EndCallAction transaction request successful")
        }
    }
    
    func performVoiceCall(uuid: UUID, client: String?, completionHandler: @escaping (Bool) -> Swift.Void) {
        guard let accessToken = fetchAccessToken() else {
            completionHandler(false)
            return
        }
        
            call = TwilioVoice.call(accessToken, params: ["to" : "8582120545",  "from" : agentPhone + "+" + yourPhone], uuid:uuid, delegate: self)

            self.callKitCompletionCallback = completionHandler
        
    }
    
    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {
        call = self.callInvite?.accept(with: self)
        self.callInvite = nil
        self.callKitCompletionCallback = completionHandler
    }
}
