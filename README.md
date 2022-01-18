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
  
static Future<PaymeSdkFlutterKYCState> login(String userId, String phone, PaymeSdkFlutterConfig config);
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

## Các chức năng của PayME SDK (Static Method)

### logout()

```dart
logout() -> Future<void>
```

Dùng để đăng xuất ra khỏi phiên làm việc trên SDK

### close() - Đóng SDK

Hàm này được dùng để app tích hợp đóng lại UI của SDK khi đang <code>pay()</code> hoặc <code>openWallet()</code>

```dart
close() -> Future<void>
```

### openWallet() - Mở UI chức năng PayME tổng hợp

```dart
openWallet() -> Future<dynamic>
```

Hàm này được gọi khi từ app tích hợp khi muốn gọi chức năng của sdk PayME

### deposit() - Nạp tiền

```swift
deposit({int? amount}) -> Future<dynamic>
```

### withdraw() - Rút tiền

```dart
withdraw({int? amount}) -> Future<dynamic>
```

### transfer() - Chuyển tiền

```dart
transfer({int? amount, String note = ""}) -> Future<dynamic>
```

### openHistory() - Mở lịch sử giao dịch

```dart
openHistory() -> Future<dynamic>
```

Hàm này có ý nghĩa giống như gọi <code>openWallet</code> với action là <code>Action.OPEN_HISTORY</code>

### pay() - Thanh toán

Hàm này được dùng khi app cần thanh toán 1 khoản tiền từ ví PayME đã được kích hoạt.

```dart
pay(
    int amount,
    String orderId,
    PaymeSdkFlutterPayCode payCode, 
    {
    	String? storeId,
    	String? userName,
    	String? note,
    	String? extraData,
    	bool isShowResultUI = true,
    }
) -> Future<dynamic>
```
| Tham số                                                      | **Bắt buộc** | **Giá trị**                                               | 
| :----------------------------------------------------------- | :----------- | :----------------------------------------------------------- |
| <code>payCode</code> | Yes          | <code>PAYME</code> <code>ATM</code> <code>CREDIT</code> <code>MANUAL_BANK</code>  |
| <code>userName</code> | No          | Tên tài khoản |
| <code>storeId</code> | No | ID của store phía công thanh toán thực hiên giao dịch thanh toán |

Lưu ý : Chỉ có userName hoặc storeId, nếu dùng userName thì để storeId = null và ngược lại

### scanQR() - Mở chức năng quét mã QR để thanh toán

```dart
scanQR(payCode: String) -> Future<dynamic>

```
Định dạng QR : 
```dart
final qrString =  "{$type}|${storeId?}|${action}|${amount}|${note}|${orderId}|${userName?}"
```

Ví dụ  : 
```dart
final qrString = "OPENEWALLET|54938607|PAYMENT|20000|Chuyentien|2445562323|DEMO)"
```

- action: loại giao dịch ( 'PAYMENT' => thanh toán)
- amount: số tiền thanh toán
- note: Mô tả giao dịch từ phía đối tác
- orderId: mã giao dịch của đối tác, cần duy nhất trên mỗi giao dịch
- storeId: ID của store phía hiện giao dịch thanh toán
- type: <code>OPENEWALLET</code>

### payQRCode() - thanh toán mã QR code

```dart
payQRCode(
	qr: String,
	payCode: String,
	isShowResultUI: Bool
) -> Future<dynamic>
```

- qr: Mã QR để thanh toán  ( Định dạng QR như hàm <code>scanQR()</code> )
- isShowResultUI: Có muốn hiển thị UI kết quả giao dịch hay không

### openKYC() - Mở modal định danh tài khoản

Hàm này được gọi khi từ app tích hợp khi muốn mở modal định danh tài khoản ( yêu cầu tài khoản phải chưa định danh )

```dart
openKYC() -> Future<dynamic>
```

### getWalletInfo() - **Lấy các thông tin của ví**

```dart
getWalletInfo() -> Future<dynamic>
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

```dart
getAccountInfo() -> Future<dynamic>
```

### getSupportedServices()

Dùng để xác định các dịch vụ có thể dùng SDK để thanh toán (điện, nước, học phí...).

```dart
getSupportedServices() -> Future<dynamic>
```

### openService()

Mở WebSDK để thanh toán dịch vụ. ( Tính năng đang được xây dựng )

```dart
openService(String serviceCode, String serviceDescription) -> Future<dynamic>
```

### setLanguage()

Chuyển đổi ngôn ngữ của sdk

```dart
setLanguage(PaymeSdkFlutterLanguage lang) -> Future<dynamic>
```

## Ghi chú

### Làm việc với use_framework!

- react-native-permission: https://github.com/zoontek/react-native-permissions#workaround-for-use_frameworks-issues
- Google Map iOS Util: https://github.com/googlemaps/google-maps-ios-utils/blob/b721e95a500d0c9a4fd93738e83fc86c2a57ac89/Swift.md
