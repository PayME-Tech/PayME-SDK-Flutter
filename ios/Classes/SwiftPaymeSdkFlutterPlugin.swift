import Flutter
import UIKit
import PayMESDK
import CryptoSwift

public class SwiftPaymeSdkFlutterPlugin: NSObject, FlutterPlugin {
    var payME: PayME?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "payme_sdk_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftPaymeSdkFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "login":
            login(call, result: result)
        case "getAccountInfo":
            getAccountInfo(call, result: result)
        case "getWalletInfo":
            getWalletInfo(call, result: result)
        case "getSupportedServices":
            getSupportedServices(call, result: result)
        case "openWallet":
            openWallet(call, result: result)
        case "deposit":
            deposit(call, result: result)
        case "withdraw":
            withdraw(call, result: result)
        case "openKYC":
            openKYC(call, result: result)
        case "pay":
            pay(call, result: result)
        case "transfer":
            transfer(call, result: result)
        case "logout":
            logout(call, result: result)
        case "setLanguage":
            setLanguage(call, result: result)
        case "openService":
            openService(call, result: result)
        case "close":
            close(call, result: result)
        case "openHistory":
            openHistory(call, result: result)
        case "scanQR":
            scanQR(call, result: result)
        case "payQRCode":
            payQRCode(call, result: result)
        default:
            result("iOS " + UIDevice.current.systemVersion)
        }
    }
    
    private func genConnectToken(userId: String, phone: String, secret: String) -> String {
        let iSO8601DateFormatter = ISO8601DateFormatter()
        let isoDate = iSO8601DateFormatter.string(from: Date())
        let data: [String: Any] = ["timestamp": isoDate, "userId": "\(userId)", "phone": "\(phone)"]
        let params = try? JSONSerialization.data(withJSONObject: data)
        let aes = try? AES(key: Array(secret.utf8), blockMode: CBC(iv: [UInt8](repeating: 0, count: 16)), padding: .pkcs5)
        let dataEncrypted = try? aes?.encrypt(Array(String(data: params!, encoding: .utf8)!.utf8))
        return dataEncrypted?.toBase64() ?? ""
    }
    
    private func login(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let appToken = args["app_token"] as! String
        let pubKey = args["public_key"] as! String
        let priKey = args["private_key"] as! String
        let secretKey = args["secret_key"] as! String
        let primaryColor = args["primary_color"] as! String
        let secondaryColor = args["secondary_color"] as! String
        let language = args["language"] as! String
        let strEnv = args["env"] as! String
        let userId = args["user_id"] as! String
        let phone = args["phone"] as! String
        
        var lang: String
        switch language {
        case "EN":
            lang = PayME.Language.ENGLISH
        case "VN":
            lang = PayME.Language.VIETNAMESE
        default:
            lang = PayME.Language.VIETNAMESE
        }
        
        var env:PayME.Env
        switch strEnv {
        case "PRODUCTION":
            env = PayME.Env.PRODUCTION
        case "SANDBOX":
            env = PayME.Env.SANDBOX
        case "DEV":
            env = PayME.Env.DEV
        default:
            env = PayME.Env.SANDBOX
        }
        
        payME = PayME(
            appToken: appToken,
            publicKey: pubKey,
            connectToken: genConnectToken(userId: userId, phone: phone, secret: secretKey),
            appPrivateKey: priKey,
            language: lang,
            env: env,
            configColor: [primaryColor, secondaryColor],
            showLog: 0
        )
        
        payME?.login(onSuccess: { success in
            if success["code"] as! PayME.KYCState == PayME.KYCState.NOT_KYC {
                result("NOT_KYC")
            }else if success["code"] as! PayME.KYCState == PayME.KYCState.NOT_ACTIVATED {
                result("NOT_ACTIVATED")
            }else if success["code"] as! PayME.KYCState == PayME.KYCState.KYC_REVIEW {
                result("KYC_REVIEW")
            }else if success["code"] as! PayME.KYCState == PayME.KYCState.KYC_REJECTED {
                result("KYC_REJECTED")
            }else if success["code"] as! PayME.KYCState == PayME.KYCState.KYC_APPROVED {
                result("KYC_APPROVED")
            }else{
                result("")
            }
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func getAccountInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        payME?.getAccountInfo(onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func getWalletInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        payME?.getWalletInfo(onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func getSupportedServices(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        payME?.getSupportedServices(onSuccess: { configs in
            var serviceList: [[String: Any?]] = []
            configs.forEach { service in
                serviceList.append([
                    "code": service.getCode(),
                    "description": service.getDescription()
                ])
            }
            result(serviceList)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func openWallet(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            return
        }
        payME?.openWallet(currentVC: vc, action: PayME.Action.OPEN, amount: nil, description: nil, extraData: nil,
                          onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func deposit(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let amount = args["amount"] as? Int
        if(amount != nil && amount! < 10000){
            result(FlutterError(code: "MIN_LIMIT", message: "Vui lòng nạp hơn 10.000VND", details: nil))
            return
        }
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            result(FlutterError(code: "-1", message: "Can't find View Controller", details: nil))
            return
        }
        self.payME!.deposit(currentVC: vc,
                            amount: amount,
                            description: "",
                            extraData: nil,
                            closeWhenDone: true,
                            onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func withdraw(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let amount = args["amount"] as? Int
        if(amount != nil && amount! < 10000){
            result(FlutterError(code: "MIN_LIMIT", message: "Vui lòng rút hơn 10.000VND", details: nil))
            return
        }
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            result(FlutterError(code: "-1", message: "Can't find View Controller", details: nil))
            return
        }
        payME!.withdraw(currentVC: vc,
                        amount: amount,
                        description: "",
                        extraData: nil,
                        onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
        
    }
    
    private func openKYC(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            result(FlutterError(code: "-1", message: "Can't find View Controller", details: nil))
            return
        }
        payME?.openKYC(currentVC: vc, onSuccess: {
            result("KYC thành công")
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func pay(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            return
        }
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let amount = args["amount"] as! Int
        let storeId = args["store_id"] as! String?
        let storeIdInt: Int? = storeId == nil ? nil : Int.init(storeId!)!
        let userName = args["user_name"] as! String?
        let orderId = args["order_id"] as! String
        let note = args["note"] as? String
        let payCode = args["pay_code"] as! String
        let extraData = args["extra_data"] as? String
        let isShowResultUI = args["is_show_result_ui"] as! Bool
        if (amount < 10000) {
            result(FlutterError(code: "MIN_LIMIT", message: "Vui lòng thanh toán hơn 10.000VND", details: nil))
            return
        }
        payME?.pay(currentVC: vc,
                   storeId: storeIdInt,
                   userName: userName,
                   orderId: orderId,
                   amount: amount,
                   note: note,
                   payCode: payCode,
                   extraData: extraData,
                   isShowResultUI: isShowResultUI,
                   onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func transfer(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            return
        }
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let amount = args["amount"] as? Int
        let note = args["note"] as? String
        if (amount != nil && amount! < 10000) {
            result(FlutterError(code: "MIN_LIMIT", message: "Vui lòng thanh toán hơn 10.000VND", details: nil))
            return
        }
        payME?.transfer(currentVC: vc,
                        amount: amount,
                        description: note,
                        extraData: nil,
                        closeWhenDone: true,
                        onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func logout(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        payME?.logout()
        result(nil)
    }
    
    private func setLanguage(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let language = args["language"] as! String
        var lang: String
        switch language {
        case "EN":
            lang = PayME.Language.ENGLISH
        case "VN":
            lang = PayME.Language.VIETNAMESE
        default:
            lang = PayME.Language.VIETNAMESE
        }
        payME?.setLanguage(language: lang)
        result(nil)
    }
    
    private func openService(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController  as? FlutterViewController else {
            return
        }
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let amount = args["amount"] as? Int
        let note = args["note"] as? String
        let extraData = args["extra_data"] as? String
        let sCode = args["service_code"] as! String
        let sDesc = args["service_desc"] as! String
        let serviceConfig = ServiceConfig(sCode, sDesc)
        payME?.openService(currentVC: vc,
                           amount: amount,
                           description: note,
                           extraData: extraData,
                           service: serviceConfig,
                           onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
        result(nil)
    }
    
    private func close(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        payME?.close()
    }
    
    private func openHistory(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return
        }
        payME?.openHistory(currentVC: vc, onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func scanQR(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return
        }
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let payCode = args["pay_code"] as! String
        payME?.scanQR(currentVC: vc, payCode: payCode, onSuccess: { success in
            result(success)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func payQRCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController else {
            return
        }
        guard let args = call.arguments as? [String : Any] else {
            result(FlutterError(code: "MISSING_INFO", message: "Missing info", details: nil))
            return
        }
        let qr = args["qr"] as! String
        let payCode = args["pay_code"] as! String
        let isShowResultUI = args["is_show_result_ui"] as! Bool
        payME?.payQRCode(currentVC: vc, qr: qr, payCode: payCode, isShowResultUI: isShowResultUI, onSuccess: { succes in
            result(succes)
        }, onError: { error in
            result(FlutterError(code: self.handleErrorCode(error), message: error["message"] as? String, details: nil))
        })
    }
    
    private func handleErrorCode(_ error: Dictionary<String, AnyObject>) -> String {
        if let code = error["code"] as? Int {
            switch code {
            case PayME.ResponseCode.EXPIRED:
                return "EXPIRED"
            case PayME.ResponseCode.OTHER:
                return "OTHER"
            case PayME.ResponseCode.NETWORK:
                return "NETWORK"
            case PayME.ResponseCode.SYSTEM:
                return "SYSTEM"
            case PayME.ResponseCode.LIMIT:
                return "LIMIT"
            case PayME.ResponseCode.ACCOUNT_NOT_ACTIVATED:
                return "ACCOUNT_NOT_ACTIVATED"
            case PayME.ResponseCode.ACCOUNT_NOT_KYC:
                return "ACCOUNT_NOT_KYC"
            case PayME.ResponseCode.PAYMENT_ERROR:
                return "PAYMENT_ERROR"
            case PayME.ResponseCode.ERROR_KEY_ENCODE:
                return "ERROR_KEY_ENCODE"
            case PayME.ResponseCode.USER_CANCELLED:
                return "USER_CANCELLED"
            case PayME.ResponseCode.ACCOUNT_NOT_LOGIN:
                return "ACCOUNT_NOT_LOGIN"
            case PayME.ResponseCode.BALANCE_ERROR:
                return "BALANCE_ERROR"
            case PayME.ResponseCode.PAYMENT_PENDING:
                return "PAYMENT_PENDING"
            default:
                return "UNKNOWN_ERROR"
            }
        }
        return "UNKNOWN_ERROR"
    }
}

