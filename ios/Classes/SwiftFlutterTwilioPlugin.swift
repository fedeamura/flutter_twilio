import Flutter
import UIKit
import AVFoundation
import PushKit
import TwilioVoice
import CallKit

public class SwiftFlutterTwilioPlugin: NSObject, FlutterPlugin,   NotificationDelegate, AVAudioPlayerDelegate {
        
    var deviceTokenString: Data?
    var callTo: String = ""
    var callStatus: String = ""
    var callInvite: CallInvite?
    var call: Call?
    var result: FlutterResult?
    
    var voipRegistry: PKPushRegistry
    var incomingPushCompletionCallback: (()->Swift.Void?)? = nil
    var callKitCompletionCallback: ((Bool)->Swift.Void?)? = nil
    var audioDevice: DefaultAudioDevice = DefaultAudioDevice()
    var callKitProvider: CXProvider
    var callKitCallController: CXCallController
    var userInitiatedDisconnect: Bool = false
    var channel: FlutterMethodChannel?
    
    public override init() {
        
        //isSpinning = false
        voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        let appName = Bundle.main.infoDictionary!["CFBundleName"] as! String
        let configuration = CXProviderConfiguration(localizedName: appName)
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        if let callKitIcon = UIImage(named: "iconMask80") {
            configuration.iconTemplateImageData = callKitIcon.pngData()
        }
        
        callKitProvider = CXProvider(configuration: configuration)
        callKitCallController = CXCallController()
        
        //super.init(coder: aDecoder)
        super.init()
        
        callKitProvider.setDelegate(self, queue: nil)
        
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
        
        
        let appDelegate = UIApplication.shared.delegate
        guard let controller = appDelegate?.window??.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }
        
        channel = FlutterMethodChannel(
            name: "flutter_twilio_response",
            binaryMessenger: controller.binaryMessenger
        )
        
    }
    
    deinit {
        // CallKit has an odd API contract where the developer must call invalidate or the CXProvider is leaked.
        callKitProvider.invalidate()
    }
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterTwilioPlugin()
        let methodChannel = FlutterMethodChannel(name: "flutter_twilio", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    public func handle(_ flutterCall: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = flutterCall.arguments as? NSDictionary
        
        if flutterCall.method == "makeCall" {
            guard let callTo = arguments?["to"] as? String else {return}
            self.callTo = callTo;
            self.callStatus = "callConnecting"
            makeCall(to: callTo)
            self.result = result
            self.channel?.invokeMethod("callConnecting", arguments: self.getCallResult())
            return
        }
        
        if flutterCall.method == "toggleMute"
        {
            if self.call == nil{
                result(FlutterError.init(
                    code: "No call",
                    message: "There is no an active call",
                    details: "There is no an active call"
                ))
                return
            }
            
            let isMuted: Bool = !self.call!.isMuted
            self.call!.isMuted = isMuted
            self.channel?.invokeMethod(self.callStatus, arguments: self.getCallResult())
            result(isMuted)
            return
        }
        
        if flutterCall.method == "isMuted"
        {
            if self.call == nil{
                result(FlutterError.init(
                    code: "No call",
                    message: "There is no an active call",
                    details: "There is no an active call"
                ))
                return
            }
            
            result(self.call?.isMuted ?? false)
            return
        }
        
        if flutterCall.method == "toggleSpeaker"
        {
            if self.call == nil{
                result(FlutterError.init(
                    code: "No call",
                    message: "There is no an active call",
                    details: "There is no an active call"
                ))
                return
            }
            
            let isSpeaker: Bool = !self.isSpeaker()
            toggleAudioRoute(toSpeaker: isSpeaker);
            self.channel?.invokeMethod(self.callStatus, arguments: self.getCallResult())
            result(isSpeaker)
            return
        }
        
        if flutterCall.method == "isSpeaker"
        {
            if self.call == nil{
                result(FlutterError.init(
                    code: "No call",
                    message: "There is no an active call",
                    details: "There is no an active call"
                ))
                return
            }
            
            result(self.isSpeaker())
            return
        }
        
        if flutterCall.method == "register"
        {
            guard let accessToken = arguments?["accessToken"] as? String else {return}
            
            self.storeAccessToken(token: accessToken)

            self.result = result;
            self.registerTwilio()
            return
        }
        
        if flutterCall.method == "unregister"
        {
            self.unregisterTwilio()
            result("")
            return
        }
        
        if flutterCall.method == "hangUp"
        {
            if (self.call != nil && self.call?.state == .connected) {
                self.userInitiatedDisconnect = true
                performEndCallAction(uuid: self.call!.uuid!)
            }
            result("")
            return
        }
        
        if flutterCall.method == "activeCall"
        {
            if(self.call == nil){
                result("")
            }else{
                result(self.getCallResult())
            }
            return
        }
        
        if flutterCall.method == "setContactData"
        {
            guard let data = arguments?["contacts"] as? NSDictionary else {
                return
            }
            
            let defaultDisplayName = arguments?["defaultDisplayName"] as? String ?? ""
            
            self.storeContactData(data: data, defaultDisplayName: defaultDisplayName)
            result("")
            return
        }
        
    
    }
    
    func registerTwilio() {
        guard let accessToken = getAccessToken() else {
            self.result?(FlutterError.init(
                code: "No access token",
                message: "No access token",
                details: "No access token"
            ))
            self.result = nil
            return
        }
        
        guard let deviceToken = self.deviceTokenString else {
            self.result?(FlutterError.init(
                code: "No device token",
                message: "No device token",
                details: "No device token"
            ))
            self.result = nil
            return
        }
        
        
        TwilioVoice.register(accessToken: accessToken, deviceToken: deviceToken) { (error) in
            if(error != nil){
                NSLog(error!.localizedDescription)

                self.result?(FlutterError.init(
                    code: "Error",
                    message: "Error",
                    details: "Error"
                ))
            } else {
                self.result?("")
            }
            self.result = nil
        }
    }
    
    func unregisterTwilio(){
        guard let accessToken = getAccessToken() else {
            return
        }
        
        guard let deviceToken = self.deviceTokenString else {
            return
        }
        
        
        self.removeAccessToken()
        TwilioVoice.unregister(accessToken: accessToken, deviceToken: deviceToken) {(error) in
            
        }
    }
    
    func makeCall(to: String) {
        if (self.call != nil && self.call?.state == .connected) {
            self.userInitiatedDisconnect = true
            self.performEndCallAction(uuid: self.call!.uuid!)
            self.result?(FlutterError.init(
                code: "Already and active call",
                message: "Already and active call",
                details: "Already and active call"
            ))
            self.result = nil;

        } else {
            var displayName: String = to
            if self.hasContactDisplayName(phoneNumber: to) {
                displayName = self.getContactDisplayName(phoneNumber: to)
            }
            let uuid = UUID()
            self.performStartCallAction(uuid: uuid, handle: displayName)
        }
    }
    
    
    func storeContactData(data: NSDictionary, defaultDisplayName: String)->Void{
        UserDefaults.standard.set(defaultDisplayName, forKey: "_defaultDisplayName")

        for phoneNumber in data.allKeys{
            let item = data[phoneNumber] as? NSDictionary
            let displayName = item?["displayName"] as? String ?? ""
            let photoURL = item?["phoneNumber"] as? String ?? ""
            UserDefaults.standard.set(displayName + ";" + photoURL, forKey: phoneNumber as? String ?? "")
        }
    }
    
    func hasContactDisplayName(phoneNumber: String) -> Bool{
        if let value = UserDefaults.standard.string(forKey: phoneNumber) {
            let parts = value.components(separatedBy: ";")
            if parts.count == 2 {
                let name =  String(parts[0])
                if name == "" {
                    NSLog("Contact name saved is blanck " + value + " for number " + phoneNumber)
                    return false
                }
                return true
            }else{
                NSLog("Wrong contact name saved " + value + ". Parts length: " + parts.count.description + " for number " + phoneNumber)
                return false
            }
        } else {
            NSLog("No contact name saved for number " + phoneNumber)
            return false
        }
    }
    
    
    func getContactDisplayName(phoneNumber: String)-> String{
        let defaultDisplayName = UserDefaults.standard.string(forKey: "_defaultDisplayName") ?? ""
        
        if let value = UserDefaults.standard.string(forKey: phoneNumber) {
            let parts = value.components(separatedBy: ";")
            if parts.count == 2 {
                let name =  parts[0]
                if name == "" {
                    NSLog("Contact name saved is blanck " + value + " for number " + phoneNumber)
                    return defaultDisplayName
                }
                return name
            }else{
                NSLog("Wrong contact name saved " + value + ". Parts length: " + parts.count.description + " for number " + phoneNumber)
                return defaultDisplayName
            }
            
        } else {
            NSLog("No contact name saved for number " + phoneNumber)
            return defaultDisplayName
        }
    }
    
    func getContactPhotoURL(phoneNumber: String)-> String{
        if let value = UserDefaults.standard.string(forKey: phoneNumber) {
            let parts = value.components(separatedBy: ";")
            if parts.count == 2 {
                return parts[1]
            }else{
                NSLog("Wrong contact photo URL saved " + value + ". Parts length: " + parts.count.description + " for number " + phoneNumber)
                return ""
            }
        } else {
            NSLog("No contact url saved for number " + phoneNumber)
            return ""
        }
    }

    func storeAccessToken(token: String) -> Void{
        UserDefaults.standard.set(token, forKey: "_accessToken");
    }
    
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "_accessToken")
    }
    
    func removeAccessToken() -> Void{
        UserDefaults.standard.removeObject(forKey: "_accessToken")
    }
    
    func getCallResult() -> [String: Any?]{
        var callResult: [String: Any] = [:];
        if(self.call != nil) {
            callResult["id"] = self.call!.sid
            callResult["mute"] = self.call!.isMuted
            callResult["speaker"] = self.isSpeaker()
        } else {
            callResult["id"] = ""
            callResult["mute"] = false
            callResult["speaker"] = false
        }

        callResult["to"] = self.callTo
        callResult["toDisplayName"] = self.getContactDisplayName(phoneNumber: self.callTo)
        callResult["toPhotoURL"] = self.getContactPhotoURL(phoneNumber: self.callTo)
        callResult["status"] = self.callStatus
        return callResult;
    }
    
    func incomingPushHandled() {
        if let completion = self.incomingPushCompletionCallback {
            completion()
            self.incomingPushCompletionCallback = nil
        }
    }
    
    // MARK: TVONotificaitonDelegate
    public func callInviteReceived(callInvite: CallInvite) {
        NSLog("callInviteReceived:")
        
        if (self.callInvite != nil) {
            NSLog("A CallInvite is already in progress. Ignoring the incoming CallInvite from \(callInvite.from ?? "Unknown Caller")")
            self.incomingPushHandled()
            return;
        } else if (self.call != nil) {
            NSLog("Already an active call.");
            NSLog("  >> Ignoring call from \(String(describing: callInvite.from))");
            self.incomingPushHandled()
            return;
        }
        
        self.callInvite = callInvite
        self.callTo = callInvite.from ?? ""
        var displayName = self.callTo
        if self.hasContactDisplayName(phoneNumber: self.callTo) {
            displayName = self.getContactDisplayName(phoneNumber: self.callTo)
        }
    
        reportIncomingCall(from: displayName, uuid: callInvite.uuid)
    }
    
    
    public func cancelledCallInviteReceived(cancelledCallInvite: CancelledCallInvite, error: Error) {
        NSLog("cancelledCallInviteCanceled:")
        
        self.incomingPushHandled()
        
        if (self.callInvite == nil || self.callInvite!.callSid != cancelledCallInvite.callSid) {
            NSLog("No matching pending CallInvite. Ignoring the Cancelled CallInvite")
            return
        }
        
        performEndCallAction(uuid: self.callInvite!.uuid)
        
        self.callInvite = nil
        self.incomingPushHandled()
    }
    
    func callDisconnected(error: String?) {
        self.call = nil
        self.callKitCompletionCallback = nil
        self.userInitiatedDisconnect = false
        DispatchQueue.main.async {
            self.callStatus = "callDisconnected"
            self.channel?.invokeMethod("callDisconnected", arguments: nil)
        }
    }
    
    
    func isSpeaker() -> Bool{
        var speaker: Bool = false
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            switch output.portType {
            case AVAudioSession.Port.builtInSpeaker:
                speaker = true
            default:
                break
            }
        }
        return speaker
    }
    
    // MARK: AVAudioSession
    func toggleAudioRoute(toSpeaker: Bool) {
        // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
        audioDevice.block = {
            DefaultAudioDevice.DefaultAVAudioSessionConfigurationBlock()
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
        audioDevice.block()
    }
    
    
    // MARK: Call Kit Actions
    func performStartCallAction(uuid: UUID, handle: String) {
        let callHandle = CXHandle(type: .generic, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: callHandle)
        let transaction = CXTransaction(action: startCallAction)
        
        callKitCallController.request(transaction)  { error in
            if let error = error {
                NSLog("StartCallAction transaction request failed: \(error.localizedDescription)")
                self.result?(FlutterError.init(
                    code: "Error",
                    message: "Error",
                    details: "Error"
                ))

                self.result = nil
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

            self.result?(self.getCallResult())
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
            } else {
                NSLog("Incoming call successfully reported.")
            }
        }
    }
    
    func performEndCallAction(uuid: UUID) {
        
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)
        
        callKitCallController.request(transaction) { error in
            
        }
    }
    
    func performVoiceCall(uuid: UUID, client: String?, completionHandler: @escaping (Bool) -> Swift.Void) {
        guard let accessToken = getAccessToken() else {
            completionHandler(false)
            return
        }
        
        let connectOptions: ConnectOptions = ConnectOptions(accessToken: accessToken) { (builder) in
            builder.params = ["To" : self.callTo]
            builder.uuid = uuid
        }
                
        call = TwilioVoice.connect(options: connectOptions, delegate: self)
        self.callKitCompletionCallback = completionHandler
    }
    
    func performAnswerVoiceCall(uuid: UUID, completionHandler: @escaping (Bool) -> Swift.Void) {
        
        if self.callInvite == nil {
            NSLog("No call invite")
            return
        }
        
        let acceptOptions: AcceptOptions = AcceptOptions(callInvite: self.callInvite!) { (builder) in
            builder.uuid = self.callInvite?.uuid
        }
        
        self.callStatus = "callConnecting"
        self.channel?.invokeMethod("callConnecting", arguments: self.getCallResult())
        call = self.callInvite!.accept(options: acceptOptions, delegate: self)
        
        self.callInvite = nil
        self.callKitCompletionCallback = completionHandler
        self.incomingPushHandled()
    }
}


// MARK: PKPushRegistryDelegate
extension SwiftFlutterTwilioPlugin : PKPushRegistryDelegate {
    
    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        NSLog("pushRegistry:didUpdatePushCredentials:forType:")
        
        if (type != .voIP) {
            return
        }
        
        self.deviceTokenString = credentials.token
        let deviceToken = deviceTokenString?.reduce("", {$0 + String(format: "%02X", $1) })
        NSLog("Device token \(String(describing: deviceToken))")
    }
    
    public func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        NSLog("pushRegistry:didInvalidatePushTokenForType:")
        
        if (type != .voIP) {
            return
        }
        
        guard let deviceToken = deviceTokenString, let accessToken = getAccessToken() else {
            return
        }
        
        TwilioVoice.unregister(accessToken: accessToken, deviceToken: deviceToken) { (error) in
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
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:")
        
        if (type == PKPushType.voIP) {
            TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
        }
    }
    
    /**
     * This delegate method is available on iOS 11 and above. Call the completion handler once the
     * notification payload is passed to the `TwilioVoice.handleNotification()` method.
     */
    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        NSLog("pushRegistry:didReceiveIncomingPushWithPayload:forType:completion:")
        // Save for later when the notification is properly handled.
        self.incomingPushCompletionCallback = completion
        
        if (type == PKPushType.voIP) {
            TwilioVoice.handleNotification(payload.dictionaryPayload, delegate: self, delegateQueue: nil)
        }
    }
}

/**
 Call provider delegate
 // MARK: CXProviderDelegate
 */
extension SwiftFlutterTwilioPlugin : CXProviderDelegate {
    
    public func providerDidReset(_ provider: CXProvider) {
        NSLog("providerDidReset:")
        audioDevice.isEnabled = true
    }
    
    public func providerDidBegin(_ provider: CXProvider) {
        NSLog("providerDidBegin")
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        NSLog("provider:didActivateAudioSession:")
        audioDevice.isEnabled = true
    }
    
    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        NSLog("provider:didDeactivateAudioSession:")
    }
    
    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        NSLog("provider:timedOutPerformingAction:")
    }
    
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        NSLog("provider:performStartCallAction:")
        
        audioDevice.isEnabled = false
        audioDevice.block();
        
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
    
    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NSLog("provider:performAnswerCallAction:")
        
        assert(action.callUUID == self.callInvite?.uuid)
        
        audioDevice.isEnabled = false
        audioDevice.block();
        
        self.performAnswerVoiceCall(uuid: action.callUUID) { (success) in
            if (success) {
                action.fulfill()
            } else {
                action.fail()
            }
        }
        
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        NSLog("provider:performEndCallAction:")
        
        if (self.callInvite != nil) {
            self.callInvite!.reject()
            self.callInvite = nil
        } else if (self.call != nil) {
            self.call?.disconnect()
        }
        
        audioDevice.isEnabled = true
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        NSLog("provider:performSetHeldAction:")
        if (self.call?.state == .connected) {
            self.call?.isOnHold = action.isOnHold
            action.fulfill()
        } else {
            action.fail()
        }
    }
}

/**
 Call state delegate
 // MARK: TVOCallDelegate
 */
extension SwiftFlutterTwilioPlugin : CallDelegate {
    
    public func callDidStartRinging(call: Call) {
        NSLog("callDidStartRinging:")
        
        self.callStatus = "callRinging"
        self.channel?.invokeMethod("callRinging", arguments: self.getCallResult())
    }
    
    public func callDidConnect(call: Call) {
        NSLog("callDidConnect:")
        
        self.call = call
        self.callKitCompletionCallback!(true)
        self.callKitCompletionCallback = nil
        self.callStatus = "callConnected"
        self.channel?.invokeMethod("callConnected", arguments: self.getCallResult())
    }
    
    public func callIsReconnecting(call: Call, error: Error) {
        NSLog("call:isReconnectingWithError:")
        
        self.callStatus = "callReconnecting"
        self.channel?.invokeMethod("callReconnecting", arguments: self.getCallResult())
    }
    
    public func callDidReconnect(call: Call) {
        NSLog("callDidReconnect:")
        
        self.callStatus = "callReconnected"
        self.channel?.invokeMethod("callReconnected", arguments: self.getCallResult())
    }
    
    public func callDidFailToConnect(call: Call, error: Error) {
        NSLog("Call failed to connect: \(error.localizedDescription)")
        
        if let completion = self.callKitCompletionCallback {
            completion(false)
        }
        
        performEndCallAction(uuid: call.uuid!)
        callDisconnected(error: error.localizedDescription)
    }
    
    public func callDidDisconnect(call: Call, error: Error?) {
        NSLog("callDidDisconnect:")
        
        if !self.userInitiatedDisconnect {
            var reason = CXCallEndedReason.remoteEnded
            
            if error != nil {
                reason = .failed
            }
            
            self.callKitProvider.reportCall(with: call.uuid!, endedAt: Date(), reason: reason)
        }
        callDisconnected(error: nil)
    }
}

extension UIWindow {
    func topMostViewController() -> UIViewController? {
        guard let rootViewController = self.rootViewController else {
            return nil
        }
        return topViewController(for: rootViewController)
    }
    
    func topViewController(for rootViewController: UIViewController?) -> UIViewController? {
        guard let rootViewController = rootViewController else {
            return nil
        }
        guard let presentedViewController = rootViewController.presentedViewController else {
            return rootViewController
        }
        switch presentedViewController {
        case is UINavigationController:
            let navigationController = presentedViewController as! UINavigationController
            return topViewController(for: navigationController.viewControllers.last)
        case is UITabBarController:
            let tabBarController = presentedViewController as! UITabBarController
            return topViewController(for: tabBarController.selectedViewController)
        default:
            return topViewController(for: presentedViewController)
        }
    }
}
