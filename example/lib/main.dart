import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payme_sdk_flutter/payme_sdk_flutter.dart';
import 'package:payme_sdk_flutter_example/row_input.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

const APP_TOKEN_DEFAULT_SANDBOX =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6MTQsImlhdCI6MTYxNDE2NDI3MH0.MmzNL81YTx8XyTu6SczAqZtnCA_ALsn9GHsJGBKJSIk";
const PUBLIC_KEY_DEFAULT_SANDBOX = "-----BEGIN PUBLIC KEY-----\n" +
    "      MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAMyTFdiYBiaSIBgqFdxSgzk5LYXKocgT\n" +
    "      MCx/g1gz9k2jadJ1PDohCs7N65+dh/0dTbT8CIvXrrlAgQT1zitpMPECAwEAAQ==\n" +
    "      -----END PUBLIC KEY-----";
const SECRET_KEY_DEFAULT_SANDBOX = "de7bbe6566b0f1c38898b7751b057a94";
const PRIVATE_KEY_DEFAULT_SANDBOX = "-----BEGIN RSA PRIVATE KEY-----\n" +
    "      MIIBOQIBAAJAZCKupmrF4laDA7mzlQoxSYlQApMzY7EtyAvSZhJs1NeW5dyoc0XL\n" +
    "      yM+/Uxuh1bAWgcMLh3/0Tl1J7udJGTWdkQIDAQABAkAjzvM9t7kD84PudR3vEjIF\n" +
    "      5gCiqxkZcWa5vuCCd9xLUEkdxyvcaLWZEqAjCmF0V3tygvg8EVgZvdD0apgngmAB\n" +
    "      AiEAvTF57hIp2hkf7WJnueuZNY4zhxn7QNi3CQlGwrjOqRECIQCHfqO53A5rvxCA\n" +
    "      ILzx7yXHzk6wnMcGnkNu4b5GH8usgQIhAKwv4WbZRRnoD/S+wOSnFfN2DlOBQ/jK\n" +
    "      xBsHRE1oYT3hAiBSfLx8OAXnfogzGLsupqLfgy/QwYFA/DSdWn0V/+FlAQIgEUXd\n" +
    "      A8pNN3/HewlpwTGfoNE8zCupzYQrYZ3ld8XPGeQ=\n" +
    "      -----END RSA PRIVATE KEY-----";

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _accountStatus = 'Not Connected. Please LOGIN first';
  bool _connected = false;
  PaymeSdkFlutterPayCode _payCode = PaymeSdkFlutterPayCode.PAYME;
  TextEditingController _userIdController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final sdkArgs = PaymeSdkFlutterConfig(
      appToken: APP_TOKEN_DEFAULT_SANDBOX,
      publicKey: PUBLIC_KEY_DEFAULT_SANDBOX,
      privateKey: PRIVATE_KEY_DEFAULT_SANDBOX,
      secretKey: SECRET_KEY_DEFAULT_SANDBOX,
    );
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('PayME SDK Example'),
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            print('aaaaa');
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(_accountStatus),
                ),
                _buildTextField('UserId', _userIdController),
                _buildTextField('Phone', _phoneController),
                Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildButton(() async {
                        try {
                          final status = await PaymeSdkFlutter.login(
                              _userIdController.text, _phoneController.text, sdkArgs);
                          setState(() {
                            _accountStatus = status.toString();
                            _connected = true;
                          });
                          print(status);
                        } catch (e) {
                          print(e);
                          setState(() {
                            _connected = false;
                          });
                        }
                      }, 'Login'),
                    _buildButton(() async {
                      try {
                        await PaymeSdkFlutter.logout();
                        setState(() {
                          _accountStatus = 'Not Connected. Please LOGIN first';
                          _connected = false;
                        });
                      } catch (e) {
                        print(e);
                        setState(() {
                          _connected = false;
                        });
                      }
                    }, 'Logout'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDropdown(),
                      _buildButton(() {
                        PaymeSdkFlutter.openWallet();
                      }, 'Open Wallet'),
                      _buildButton(() async {
                        try {
                          await PaymeSdkFlutter.openKYC();
                        } on PlatformException catch (e) {
                          showAlertDialog(context,
                              content: e.message ?? 'Có lỗi xảy ra');
                        }
                      }, 'Open KYC'),
                      RowFunction(
                        placeholder: 'Deposit amount',
                        onPress: (value) async {
                          if (value.isEmpty) {
                            return;
                          }
                          try {
                            final response = await PaymeSdkFlutter.deposit(
                                amount: int.parse(value));
                            print(response);
                          } on PlatformException catch (e) {
                            print(e);
                            showAlertDialog(context,
                                title: 'Lỗi',
                                content: e.message ?? 'Có lỗi xảy ra');
                          }
                        },
                        text: 'deposit',
                      ),
                      RowFunction(
                        placeholder: 'Withdraw amount',
                        onPress: (value) async {
                          if (value.isEmpty) {
                            return;
                          }
                          try {
                            final response = await PaymeSdkFlutter.withdraw(
                                amount: int.parse(value));
                            print(response);
                          } on PlatformException catch (e) {
                            print(e);
                            showAlertDialog(context,
                                title: 'Lỗi',
                                content: e.message ?? 'Có lỗi xảy ra');
                          }
                        },
                        text: 'withdraw',
                      ),
                      RowFunction(
                        placeholder: 'Transfer amount',
                        onPress: (value) async {
                          if (value.isEmpty) {
                            return;
                          }
                          try {
                            final response = await PaymeSdkFlutter.transfer(
                                amount: int.parse(value));
                            print(response);
                          } on PlatformException catch (e) {
                            print(e);
                            showAlertDialog(context,
                                title: 'Lỗi',
                                content: e.message ?? 'Có lỗi xảy ra');
                          }
                        },
                        text: 'transfer',
                      ),
                      RowFunction(
                        placeholder: 'Pay amount',
                        onPress: (value) async {
                          if (value.isEmpty) {
                            return;
                          }
                          try {
                            final response = await PaymeSdkFlutter.pay(
                              int.parse(value),
                              DateTime.now().millisecondsSinceEpoch.toString(),
                              _payCode,
                              storeId: '10581207'
                            );
                            print(response);
                          } on PlatformException catch (e) {
                            print(e);
                            if (e.code != 'USER_CANCELLED') {
                              showAlertDialog(context,
                                  title: 'Lỗi',
                                  content: e.message ?? 'Có lỗi xảy ra');
                            }
                          }
                        },
                        text: 'pay',
                      ),
                      _buildButton(() async {
                        try {
                          final response =
                              await PaymeSdkFlutter.getSupportedServices();
                          showAlertDialog(context,
                              title: 'Lấy danh sách thành công',
                              content: response.toString());
                        } on PlatformException catch (e) {
                          showAlertDialog(context,
                              content: e.message ?? 'Có lỗi xảy ra');
                        }
                      }, 'Lấy danh sách dịch vụ'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(VoidCallback onPress, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      child: Container(
          height: 40,
          child: ElevatedButton(
            style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ))),
            onPressed: onPress,
            child: Text(text),
          )),
    );
  }

  Widget _buildTextField(String placeholder, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26.0),
          ),
          hintText: placeholder,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            child: Text('Select PAYCODE: '),
          ),
          Container(
            height: 40,
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(30)),
            child: DropdownButton<PaymeSdkFlutterPayCode>(
              value: _payCode,
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 42,
              underline: SizedBox(),
              items: [
                PaymeSdkFlutterPayCode.PAYME,
                PaymeSdkFlutterPayCode.ATM,
                PaymeSdkFlutterPayCode.CREDIT,
                PaymeSdkFlutterPayCode.MANUAL_BANK,
                PaymeSdkFlutterPayCode.VN_PAY,
                PaymeSdkFlutterPayCode.MOMO
              ].map((PaymeSdkFlutterPayCode value) {
                return DropdownMenuItem(
                  value: value,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: Text(value.toString().split('.').last),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _payCode = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  showAlertDialog(BuildContext context,
      {String title = 'Thông báo', String content = 'Có lỗi xảy ra'}) {
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text("Đã hiểu"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
