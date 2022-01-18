import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PaymeSdkFlutterLanguage { VN, EN }

enum PaymeSdkFlutterEnv { PRODUCTION, SANDBOX, DEV }

enum PaymeSdkFlutterPayCode {
  ATM,
  CREDIT,
  MANUAL_BANK,
  MOMO,
  PAYME,
  VN_PAY,
  ZALO_PAY,
}

enum PaymeSdkFlutterKYCState {
  NOT_ACTIVATED,
  NOT_KYC,
  KYC_REVIEW,
  KYC_REJECTED,
  KYC_APPROVED
}

class PaymeSdkFlutterConfig {
  final String appToken;
  final String publicKey;
  final String privateKey;
  final String secretKey;
  final Color primaryColor;
  final Color secondaryColor;
  final PaymeSdkFlutterLanguage language;
  final PaymeSdkFlutterEnv env;

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
}

class PaymeSdkFlutter {
  static const MethodChannel _channel =
      const MethodChannel('payme_sdk_flutter');

  static PaymeSdkFlutterEnv? currentEnv;

  static Future<PaymeSdkFlutterKYCState> login(
      String userId, String phone, PaymeSdkFlutterConfig config) async {
    final args = {
      'user_id': userId,
      'phone': phone,
      'app_token': config.appToken,
      'public_key': config.publicKey,
      'private_key': config.privateKey,
      'secret_key': config.secretKey,
      'primary_color': _hexFromColor(config.primaryColor),
      'secondary_color': _hexFromColor(config.secondaryColor),
      'language': _enumValue(config.language),
      'env': _enumValue(config.env),
    };
    final String kycState = await _channel.invokeMethod('login', args);
    currentEnv = config.env;
    return PaymeSdkFlutterKYCState.values
        .firstWhere((e) => e.toString().split(".").last == kycState);
  }

  static Future<void> logout() {
    return _channel.invokeMethod('logout');
  }

  static Future<dynamic> setLanguage(PaymeSdkFlutterLanguage lang) {
    final args = {'language': _enumValue(lang)};
    return _channel.invokeMethod('setLanguage', args);
  }

  static Future<dynamic> getAccountInfo() async {
    final rs = await _channel.invokeMethod('getAccountInfo');
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> getWalletInfo() async {
    final rs = await _channel.invokeMethod('getWalletInfo');
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> getSupportedServices() {
    return _channel.invokeMethod('getSupportedServices');
  }

  static Future<dynamic> openWallet() async {
    final rs = await _channel.invokeMethod('openWallet');
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> deposit({int? amount}) async {
    final args = {'amount': amount};
    final rs = await _channel.invokeMethod('deposit', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> withdraw({int? amount}) async {
    final args = {'amount': amount};
    final rs = await _channel.invokeMethod('withdraw', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> openKYC() async {
    final rs = await _channel.invokeMethod('openKYC');
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> pay(
    int amount,
    String orderId,
    PaymeSdkFlutterPayCode payCode, {
    String? storeId,
    String? userName,
    String? note,
    String? extraData,
    bool isShowResultUI = true,
  }) async {
    final args = {
      'amount': amount,
      'store_id': storeId,
      'user_name': userName,
      'order_id': orderId,
      'pay_code': _enumValue(payCode),
      'note': note,
      'extra_data': extraData,
      'is_show_result_ui': isShowResultUI,
    };
    final rs = await _channel.invokeMethod('pay', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> transfer({int? amount, String note = ""}) async {
    final args = {'amount': amount, 'note': note};
    final rs = await _channel.invokeMethod('transfer', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> openService(
      String serviceCode, String serviceDescription) async {
    final args = {
      'service_code': serviceCode,
      'service_desc': serviceDescription
    };
    final rs = await _channel.invokeMethod('openService', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<void> close() {
    return _channel.invokeMethod('close');
  }

  static Future<dynamic> openHistory() async {
    final rs = await _channel.invokeMethod('openHistory');
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> scanQR(PaymeSdkFlutterPayCode payCode) async {
    final args = {"pay_code": payCode};
    final rs = await _channel.invokeMethod('scanQR', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }

  static Future<dynamic> payQRCode(String qr, PaymeSdkFlutterPayCode payCode,
      {bool isShowResultUI = true}) async {
    final args = {
      "qr": qr,
      "pay_code": payCode,
      "is_show_result_ui": isShowResultUI
    };
    final rs = await _channel.invokeMethod('payQRCode', args);
    if (Platform.isAndroid && rs is String) {
      return jsonDecode(rs);
    }
    return rs;
  }
}

String _hexFromColor(Color color) {
  return '#${color.value.toRadixString(16).substring(2, 8)}';
}

String _enumValue(dynamic e) {
  return e.toString().split('.').last;
}
