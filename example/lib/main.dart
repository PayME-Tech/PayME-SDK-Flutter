import 'package:flutter/material.dart';
import 'package:payme_sdk_flutter/payme_sdk_flutter.dart';
import 'package:payme_sdk_flutter_example/row_input.dart';

void main() {
  runApp(MyApp());
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
  String _payCode = 'PAYME';

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
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(_accountStatus),
              ),
              _buildButton(() async {
                try {
                  final status = await PaymeSdkFlutter.login(
                      '1001', '0929000200', sdkArgs);
                  setState(() {
                    _accountStatus = status;
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
              _buildDropdown(),
              _buildButton(() {
                _connected ? PaymeSdkFlutter.openWallet() : null;
              }, 'Open Wallet'),
              RowFunction(
                placeholder: 'Deposit amount',
                onPress: (value) => print(value),
                text: 'deposit',
              ),
              RowFunction(
                placeholder: 'Withdraw amount',
                onPress: (value) => print(value),
                text: 'withdraw',
              ),
              RowFunction(
                placeholder: 'Transfer amount',
                onPress: (value) => print(value),
                text: 'transfer',
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(VoidCallback onPress, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      child: SizedBox(
          width: double.infinity,
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
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(30)),
            child: DropdownButton<String>(
              value: _payCode,
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 42,
              underline: SizedBox(),
              items: <String>['PAYME', 'ATM', 'CREDIT', 'VNPAY']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    child: Text(value),
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
}
