PayME SDK là bộ thư viện để các app có thể tương tác với PayME Platform. PayME SDK bao gồm các chức năng chính như sau:

- Hệ thống đăng nhập, eKYC thông qua tài khoản ví PayME 
- Hỗ trợ app lấy thông tin số dư ví PayME
- Chức năng nạp rút từ ví PayME.

**Một số thuật ngữ**

|      | Name    | Giải thích                                                   |
| :--- | :------ | ------------------------------------------------------------ |
| 1    | app     | Là app mobile iOS/Android hoặc web sẽ tích hợp SDK vào để thực hiện chức năng thanh toán ví PayME. |
| 2    | SDK     | Là bộ công cụ hỗ trợ tích hợp ví PayME vào hệ thống app.     |
| 3    | backend | Là hệ thống tích hợp hỗ trợ cho app, server hoặc api hỗ trợ  |
| 4    | AES     | Hàm mã hóa dữ liệu AES256 PKCS5 . [Tham khảo](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) |
| 5    | RSA     | Thuật toán mã hóa dữ liệu RSA.                               |
| 6    | IPN     | Instant Payment Notification , dùng để thông báo giữa hệ thống backend của app và backend của PayME |

## Cách cài đặt:

PayMESDK đang được lưu trữ trên nền tảng CocoaPods. Để cài đặt, đơn giản thêm dòng sau vào Podfile của bạn:

```json
pod 'PayMESDK'
```

Sau đó chạy lệnh <code>pod install</code> để hoàn tất cài dặt

**Info.plist**

Update file Info.plist của app với những key như sau (giá trị của string có thể thay đổi, đây là các message hiển thị khi yêu cầu người dùng cấp quyền tương ứng):

```swift
<key>NSCameraUsageDescription</key>
<string>Need to access your camera to capture a photo add and update profile picture.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Need to access your library to add a photo or videoo off kyc video</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Need to access your photo library to select a photo add and update profile picture</string>
<key>NSContactsUsageDescription</key>
<string>Need to access your contact</string>
```

**Nếu không sử dụng tính năng danh bạ thì thêm vào cuối podfile**

```ruby
post_install do |installer|
   installer.pods_project.targets.each do |target|
       if target.name == 'PayMESDK'
           target.build_configurations.each do |config|
             config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] ||= '$(inherited)'
             config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] << 'IGNORE_CONTACT'
           end
       end
   end
end
```

## Cách sử dụng SDK:

Hệ thống PayME sẽ cung cấp cho app tích hợp các thông tin sau:

- **PublicKey** : Dùng để mã hóa dữ liệu, app tích hợp cần truyền cho SDK để mã hóa.
- **AppToken** : AppId cấp riêng định danh cho mỗi app, cần truyền cho SDK để mã hóa
- **SecretKey** : Dùng đã mã hóa và xác thực dữ liệu ở hệ thống backend cho app tích hợp.

Bên App sẽ cung cấp cho hệ thống PayME các thông tin sau:

- **AppPublicKey** : Sẽ gửi qua hệ thống backend của PayME dùng để mã hóa. (không truyền vào SDK này )
- **AppPrivateKey**: Sẽ truyền vào PayME SDK để thực hiện việc giải mã.

Chuẩn mã hóa: RSA-512bit. Có thể dùng tool sau để sinh ra [tại đây](https://travistidwell.com/jsencrypt/demo/)

### Khởi tạo PayME SDK:

Trước khi sử dụng PayME SDK cần gọi phương thức khởi tạo và đăng nhập để sử dụng SDK.

```dart
PaymeSdkFlutterConfig({
    required this.appToken,
    required this.publicKey,
    required this.privateKey,
    required this.secretKey,
    this.primaryColor = const Color(0xff75255b),
    this.secondaryColor = const Color(0xff9d455f),
    this.language = PaymeSdkFlutterLanguage.VN,
    this.env = PaymeSdkFlutterEnv.SANDBOX,
  });
  
static Future<String> login(String userId, String phone, PaymeSdkFlutterConfig config);
```

![image](../master/assets/configColor.png?raw=true)

| **Tham số**   | **Bắt buộc** | **Giải thích**                                               |
| :------------ | :----------- | :----------------------------------------------------------- |
| **appPrivateKey** | Yes| là private key của app tự sinh ra như trên |
| **publicKey** | Yes | là public key được PayME cung cấp cho mỗi app riêng biệt |
| **configColor** | Yes | là tham số màu để có thể thay đổi màu sắc giao dịch ví PayME, kiểu dữ liệu là chuỗi với định dạng #rrggbb. Nếu như truyền 2 màu thì giao diện PayME sẽ gradient theo 2 màu truyền vào |
| **timestamp** | Yes          | Thời gian tạo ra connectToken theo định dạng iSO 8601 , Dùng để xác định thời gian timeout cùa connectToken. Ví dụ 2021-01-20T06:53:07.621Z |
| ***userId***  | Yes          | là giá trị cố định duy nhất tương ứng với mỗi tài khoản khách hàng ở dịch vụ, thường giá trị này do server hệ thống được tích hợp cấp cho PayME SDK |
| ***phone***   | Yes           | Số điện thoại của hệ thống tích hợp, nếu hệ thống không dùng số điện thoại thì có thể không cần truyền lên hoặc truyền null |

Các tính năng như nạp tiền, rút tiền, pay chỉ thực hiện được khi đã kích hoạt ví và gửi định danh thành công. Tức là khi login sẽ được trả về enum <code>KYCState</code> với case là <code>KYC_APPROVED</code>.

## Mã lỗi của PayME SDK

| **Hằng số**   | **Mã lỗi** | **Giải thích**                                               |
| :------------ | :----------- | :----------------------------------------------------------- |
| <code>EXPIRED</code> | <code>401</code>          | ***token*** hết hạn sử dụng |
| <code>NETWORK</code>  | <code>-1</code>          | Kết nối mạng bị sự cố |
| <code>SYSTEM</code>   | <code>-2</code>           | Lỗi hệ thống |
| <code>LIMIT</code>   | <code>-3</code>           | Lỗi số dư không đủ để thực hiện giao dịch |
| <code>ACCOUNT_NOT_ACTIVATED</code>   | <code>-4</code>           | Lỗi tài khoản chưa kích hoạt |
| <code>ACCOUNT_NOT_KYC</code>   | <code>-5</code>           | Lỗi tài khoản chưa định danh |
| <code>PAYMENT_ERROR</code>   | <code>-6</code>          | Thanh toán thất bại |
| <code>ERROR_KEY_ENCODE</code>   | <code>-7</code>           | Lỗi mã hóa/giải mã dữ liệu |
| <code>USER_CANCELLED</code>   | <code>-8</code>          | Người dùng thao tác hủy |
| <code>ACCOUNT_NOT_LOGIN</code>   | <code>-9</code>           | Lỗi chưa đăng nhập tài khoản |
| <code>PAYMENT_PENDING</code>   | <code>-11</code>           | Thanh toán chờ xử lý |
| <code>ACCOUNT_ERROR</code>   | <code>-12</code>           | Lỗi tài khoản bị khóa |

## Các chức năng của PayME SDK

### logout()

```swift
public func logout()
```

Dùng để đăng xuất ra khỏi phiên làm việc trên SDK

### close() - Đóng SDK

Hàm này được dùng để app tích hợp đóng lại UI của SDK khi đang <code>pay()</code> hoặc <code>openWallet()</code>

```swift
public func close() -> ()
```

### openWallet() - Mở UI chức năng PayME tổng hợp

```swift
public func openWallet( 
   currentVC : UIViewController, 
   action : Action, 
   amount: Int?, 
   description: String?, 
   extraData: String?,
   onSuccess: (Dictionary<String, AnyObject>) -> (),
   onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

**trong đó enum Action bao gồm:**

```swift
  enum Action: String {
      case OPEN = "OPEN"
      case DEPOSIT = "DEPOSIT"
      case WITHDRAW = "WITHDRAW"
      case TRANSFER = "TRANSFER"
  }
```

Hàm này được gọi khi từ app tích hợp khi muốn gọi 1 chức năng PayME bằng cách truyền vào tham số <code>Action</code> như trên.

#### Tham số

| **Tham số**                                                  | **Bắt buộc** | **Giải thích**                                               |
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>currentVC</code> | Yes          | ViewController để PayME SDK dựa vào đó tự mở giao diện của PayME lên. |
| <code>action</code> | Yes          | <ul><li>OPEN : Dùng để mở giao diện ví PayME WebView và không thực hiện hành động nào đặc biệt.</li><li>DEPOSIT: Dùng để mở giao diện ví PayME và thực hiện chức năng nạp tiền PayME sẽ xử lý và có thông báo thành công thất bại trên UI của PayME. Ngoài ra sẽ trả về cho app tích hợp kết quả nếu muốn tự hiển thị và xử lý trên app.</li><li>WITHDRAW: Dùng để mở giao diện ví PayME và thực hiện chức năng rút tiền PayME sẽ xử lý và có thông báo thành công thất bại trên UI của PayME. Ngoài ra sẽ trả về cho app tích hợp kết quả nếu muốn tự hiển thị và xử lý trên app.</li></ul> |
| <code>amount</code> | No           | Dùng trong trường hợp action là Deposit/Withdraw thì truyền vào số tiền |
| <code>description</code> | No           | Truyền mô tả của giao dịch nếu có                            |
| <code>extraData</code> | No           | Khi thực hiện Deposit hoặc Withdraw thì app tích hợp cần truyền thêm các dữ liệu khác nếu muốn để hệ thông backend PayME có thể IBN lại hệ thống backend app tích hợp đối chiều. Ví dụ : transactionID của giao dịch hay bất kỳ dữ liệu nào cần thiết đối với hệ thống app tích hợp. |
| <code>onSuccess</code> | Yes          | Dùng để bắt callback khi thực hiện giao dịch thành công từ PayME SDK |
| <code>onError</code> | Yes          | Dùng để bắt callback khi có lỗi xảy ra trong quá trình gọi PayME SDK |

Ví dụ :

```swift
import PayMESDK

class ViewController: UIViewController {
    let payME: PayME
    
    @IBAction func click(_ sender: Any) {
	payME.openWallet(
		currentVC: self,
		action: Action.OPEN, 
		amount: nil, 
		description : nil,
		extraData: nil
	)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        payME = PayME(  
		appID: appID, 
		publicKey: self.PUBLIC_KEY, 
		connectToken: self.connectToken, 
		appPrivateKey: self.PRIVATE_KEY, 
		env: currentEnv, 
		configColor: ["#75255b", "#a81308"]
	)
    }
}
```

### deposit() - Nạp tiền

```swift
public func deposit(
    currentVC : UIViewController, 
    amount: Int?, 
    description: String?, 
    extraData: String?,
    closeWhenDone: Bool = false,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> () 
```

Hàm này có ý nghĩa giống như khi gọi <code>openWallet</code> với action <code>Action.DEPOSIT</code>

| **Tham số**                                                  | **Mặc định** | **Giải thích**                                               |
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>closeWhenDone</code> | <code>false</code>          | <code>true</code>: Đóng SDK khi hoàn tất giao dịch |

### withdraw() - Rút tiền

```swift
public func withdraw(
    currentVC : UIViewController, 
    amount: Int?, 
    description: String?, 
    extraData: String?,
    closeWhenDone: Bool = false,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

Hàm này có ý nghĩa giống như gọi <code>openWallet</code> với action là <code>Action.WITHDRAW</code>

| **Tham số**                                                  | **Mặc định** | **Giải thích**                                               |
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>closeWhenDone</code> | <code>false</code>          | <code>true</code>: Đóng SDK khi hoàn tất giao dịch |

### transfer() - Chuyển tiền

```swift
public func transfer(
    currentVC : UIViewController, 
    amount: Int?, 
    description: String?, 
    extraData: String?,
    closeWhenDone: Bool = false,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

Hàm này có ý nghĩa giống như gọi <code>openWallet</code> với action là <code>Action.TRANSFER</code>

| **Tham số**                                                  | **Mặc định** | **Giải thích**                                               |
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>closeWhenDone</code> | <code>false</code>          | <code>true</code>: Đóng SDK khi hoàn tất giao dịch |

### openHistory() - Mở lịch sử giao dịch

```swift
public func openHistory(
    currentVC : UIViewController,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

Hàm này có ý nghĩa giống như gọi <code>openWallet</code> với action là <code>Action.OPEN_HISTORY</code>

### pay() - Thanh toán

Hàm này được dùng khi app cần thanh toán 1 khoản tiền từ ví PayME đã được kích hoạt.

⚠️ version 0.1.65 trở về trước: 

```swift
public func pay(
    currentVC : UIViewController,
    storeId: Int,
    orderId: Int,
    amount: Int,
    note: String?,
    paymentMethodID: Int?,
    extraData: String?,
    isShowResultUI: Bool = true,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

| Tham số                                                      | **Bắt buộc** | **Giải thích**                                               |
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>currentVC</code> | Yes          | ViewController để PayME SDK dựa vào đó tự mở giao diện của PayME lên. |
| <code>amount</code> | Yes          | Số tiền cần thanh toán bên app truyền qua cho SDK            |
| <code>extraData</code> | Yes          | Khi thực hiện thanh toán thì app cần truyền thêm các dữ liệu khác nếu muốn để hệ thông backend PayME có thể IPN lại hệ thống backend tích hợp đối chiều. Ví dụ : transactionID của giao dịch hay bất kỳ dữ liệu nào cần thiết. |
| <code>storeId</code> | Yes | ID của store phía công thanh toán thực hiên giao dịch thanh toán |
| <code>orderId</code> | Yes | Mã giao dịch của đối tác, cần duy nhất trên mỗi giao dịch (tối đa 22 kí tự) |
| <code>note</code> | No | Mô tả giao dịch từ phía đối tác |
| <code>isShowResultUI</code> | No | Đã có giá trị default là <code>true</code>, với ý nghĩa là khi có kết quả thanh toán thì sẽ hiển thị màn hình thành công, thất bại. Khi truyền giá trị là false thì sẽ không có màn hình thành công, thất bại. |
| <code>onSuccess</code> | Yes | Callback trả kết quả khi thành công |
| <code>onError</code> | Yes | Callback trả kết quả khi thất bại |

Trong trường hợp app tích hợp cần lấy số dư để tự hiển thị lên UI trên app thì có thể dùng hàm <code>getWalletInfo()</code>
, hàm này không hiển thị UI của PayME SDK

- Khi thanh toán bằng ví PayME thì yêu cầu tài khoản đã kích hoạt,định danh và số dư trong ví phải lớn hơn số tiền thanh toán
- Thông tin tài khoản lấy qua hàm <code>getAccountInfo()</code>
- Thông tin số dư lấy qua hàm <code>getWalletInfo()</code>

:warning: version 0.1.66 trở đi: 

```swift
public func pay(
    currentVC : UIViewController,
    storeId: Int?,
    userName: String?,
    orderId: Int,
    amount: Int,
    note: String?,
    payCode: String,
    extraData: String?,
    isShowResultUI: Bool = true,
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```
| Tham số                                                      | **Bắt buộc** | **Giá trị**                                               | 
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>payCode</code> | Yes          | <code>PAYME</code> <code>ATM</code> <code>CREDIT</code> <code>MANUAL_BANK</code>  |
| <code>userName</code> | No          | Tên tài khoản |
| <code>storeId</code> | No | ID của store phía công thanh toán thực hiên giao dịch thanh toán |

Lưu ý : Chỉ có userName hoặc storeId, nếu dùng userName thì để storeId = nil và ngược lại

### scanQR() - Mở chức năng quét mã QR để thanh toán

```swift
public func scanQR(
            currentVC: UIViewController,
	    payCode: String,
            onSuccess: @escaping (Dictionary<String, AnyObject>) -> (),
            onError: @escaping (Dictionary<String, AnyObject>) -> ()
) -> ()

```
Định dạng QR : 
```swift
let qrString =  "{$type}|${storeId?}|${action}|${amount}|${note}|${orderId}|${userName?}"
```

Ví dụ  : 
```swift
let qrString = "OPENEWALLET|54938607|PAYMENT|20000|Chuyentien|2445562323|DEMO)"
```

- action: loại giao dịch ( 'PAYMENT' => thanh toán)
- amount: số tiền thanh toán
- note: Mô tả giao dịch từ phía đối tác
- orderId: mã giao dịch của đối tác, cần duy nhất trên mỗi giao dịch
- storeId: ID của store phía hiện giao dịch thanh toán
- type: <code>OPENEWALLET</code>

### payQRCode() - thanh toán mã QR code

```swift
public func payQRCode(
	currentVC: UIViewController, 
	qr: String,
	payCode: String,
	isShowResultUI: Bool,
    	onSuccess: @escaping (Dictionary<String, AnyObject>) -> (),
	onError: @escaping (Dictionary<String, AnyObject>) -> ()
) -> ()
```

- qr: Mã QR để thanh toán  ( Định dạng QR như hàm <code>scanQR()</code> )
- isShowResultUI: Có muốn hiển thị UI kết quả giao dịch hay không

### openKYC() - Mở modal định danh tài khoản

Hàm này được gọi khi từ app tích hợp khi muốn mở modal định danh tài khoản ( yêu cầu tài khoản phải chưa định danh )

```swift
public func openKYC(
	currentVC: UIViewController,
        onSuccess: ([Dictionary<String, AnyObject>]) -> (),
        onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

### getWalletInfo() - **Lấy các thông tin của ví**

```swift
public func getWalletInfo(
        onSuccess: (Dictionary<String, AnyObject>) -> (),
        onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

- Trong trường hợp lỗi thì hàm sẽ trả về message lỗi tại hàm <code>onError</code> , khi đó app có thể hiển thị <code>balance</code> là 0.

- Trong trường hợp thành công SDK trả về thông tin như sau:

```json
{
  "walletBalance": {
    "balance": 111,
    "detail": {
      "cash": 1,
      "lockCash": 2
    }
  }
}
```

***balance*** : App tích hợp có thể sử dụng giá trị trong key balance để hiển thị, các field khác hiện tại chưa dùng.

***detail.cash :*** Tiền có thể dùng

***detail.lockCash:*** tiền bị lock

### getAccountInfo()

App có thể dùng được tính này sau khi khởi tạo SDK để biết được trạng thái liên kết tới ví PayME.

```swift
public func getAccountInfo(
    onSuccess: (Dictionary<String, AnyObject>) -> (),
    onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

### getSupportedServices()

Dùng để xác định các dịch vụ có thể dùng SDK để thanh toán (điện, nước, học phí...).

```swift
public func getSupportedServices(
            onSuccess: ([ServiceConfig]) -> (),
            onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

```swift
class ServiceConfig {
	...
	public func getCode() -> String
	
   	public func getDescription() -> String
	...
}
```

### openService()

Mở WebSDK để thanh toán dịch vụ. ( Tính năng đang được xây dựng )

```swift
public func openService(
        currentVC : UIViewController,
        amount: Int?,
        description: String?,
        extraData: String?,
        service: ServiceConfig,
        onSuccess: (Dictionary<String, AnyObject>) -> (),
        onError: (Dictionary<String, AnyObject>) -> ()
) -> ()
```

### setLanguage()

Chuyển đổi ngôn ngữ của sdk

```swift
public func setLanguage(language: PayME.Language) -> ()
```

## Ghi chú

### Làm việc với use_framework!

- react-native-permission: https://github.com/zoontek/react-native-permissions#workaround-for-use_frameworks-issues
- Google Map iOS Util: https://github.com/googlemaps/google-maps-ios-utils/blob/b721e95a500d0c9a4fd93738e83fc86c2a57ac89/Swift.md
