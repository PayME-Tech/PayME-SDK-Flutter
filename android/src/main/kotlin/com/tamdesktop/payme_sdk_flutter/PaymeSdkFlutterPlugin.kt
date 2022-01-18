package com.tamdesktop.payme_sdk_flutter

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import vn.payme.sdk.PayME
import vn.payme.sdk.enums.*
import vn.payme.sdk.model.InfoPayment
import vn.payme.sdk.model.Method
import vn.payme.sdk.model.Service
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.*

/** PaymeSdkFlutterPlugin */
class PaymeSdkFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity
    private lateinit var payme: PayME

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "payme_sdk_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "login" -> {
                login(call, result)
            }
            "getAccountInfo" -> {
                getAccountInfo(call, result)
            }
            "getWalletInfo" -> {
                getWalletInfo(call, result)
            }
            "getSupportedServices" -> {
                getSupportedServices(call, result)
            }
            "openWallet" -> {
                openWallet(call, result)
            }
            "deposit" -> {
                deposit(call, result)
            }
            "withdraw" -> {
                withdraw(call, result)
            }
            "openKYC" -> {
                openKYC(call, result)
            }
            "pay" -> {
                pay(call, result)
            }
            "transfer" -> {
                transfer(call, result)
            }
            "logout" -> {
                logout(call, result)
            }
            "setLanguage" -> {
                setLanguage(call, result)
            }
            "openService" -> {
                openService(call, result)
            }
            "close" -> {
                close()
            }
            "openHistory" -> {
                openHistory(result)
            }
            "scanQR" -> {
                scanQR(call, result)
            }
            "payQRCode" -> {
                payQRCode(call, result)
            }
            else -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    private fun login(@NonNull call: MethodCall, @NonNull result: Result) {
        // Extract args
        val userId = call.argument<String>("user_id")
        val phone = call.argument<String>("phone")
        val appToken = call.argument<String>("app_token")
        val publicKey = call.argument<String>("public_key")
        val privateKey = call.argument<String>("private_key")
        val secretKey = call.argument<String>("secret_key")
        val primaryColor = call.argument<String>("primary_color")
        val secondaryColor = call.argument<String>("secondary_color")
        val language = call.argument<String>("language")
        val envStr = call.argument<String>("env")

        // TODO: Check required args
        if (appToken == null || publicKey == null || privateKey == null || secretKey == null || primaryColor == null || secondaryColor == null) {
            result.error("MISSING_INFO", "Missing info", null)
            return
        }

        val lang = when (language) {
            "VI" -> LANGUAGES.VI
            "EN" -> LANGUAGES.EN
            else -> LANGUAGES.VI
        }

        val env = when (envStr) {
            "PRODUCTION" -> Env.PRODUCTION
            "SANDBOX" -> Env.SANDBOX
            "DEV" -> Env.DEV
            else -> Env.SANDBOX
        }

        // Init PayMe SDK
        val tz = TimeZone.getTimeZone("UTC")
        val df: DateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm'Z'")
        df.timeZone = tz
        val nowAsISO: String = df.format(Date())
        val dataExample = "{\"userId\":\"${userId}\",\"timestamp\":\"${nowAsISO}\",\"phone\":\"${phone}\"}"
        val connectToken = CryptoAES.encrypt(dataExample, secretKey).toString()

        val configColor = arrayOf<String>(primaryColor, secondaryColor)
        payme = PayME(context, appToken, publicKey, connectToken, privateKey, configColor, lang, env, false)

        // Login to PayME
        payme.login(
                onSuccess = { accountStatus: AccountStatus ->
                    when (accountStatus) {
                        AccountStatus.NOT_ACTIVATED -> {
                            //Tài khoản chưa kich hoạt
                            println("NOT_ACTIVATED")
                            result.success("NOT_ACTIVATED")
                        }
                        AccountStatus.NOT_KYC -> {
                            //Tài khoản chưa định danh
                            println("NOT_KYC")
                            result.success("NOT_KYC")
                        }
                        AccountStatus.KYC_REVIEW -> {
                            //Tài khoản chưa định danh
                            println("KYC_REVIEW")
                            result.success("KYC_REVIEW")
                        }
                        AccountStatus.KYC_REJECTED -> {
                            //Tài khoản chưa định danh
                            println("KYC_REJECTED")
                            result.success("KYC_REJECTED")
                        }
                        AccountStatus.KYC_APPROVED -> {
                            //Tài khoản đã định danh
                            println("KYC_APPROVED")
                            result.success("KYC_APPROVED")
                        }
                        else -> {
                            result.success("")
                        }
                    }

                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )


    }

    private fun getAccountInfo(@NonNull call: MethodCall, @NonNull result: Result) {
        payme.getAccountInfo(
                onSuccess = { data: JSONObject ->
                    result.success(data.toString())
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun getWalletInfo(@NonNull call: MethodCall, @NonNull result: Result) {
        payme.getWalletInfo(
                onSuccess = { data: JSONObject ->
                    result.success(data.toString())
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun getSupportedServices(@NonNull call: MethodCall, @NonNull result: Result) {
        payme.getSupportedServices(
                onSuccess = { arrService: ArrayList<Service>? ->
                    val list = arrayListOf<Map<String, Any?>>()
                    arrService?.forEach { service: Service ->
                        list.add(mapOf(
                                "code" to service.code,
                                "description" to service.description
                        ))
                    }
                    result.success(list)
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun openWallet(@NonNull call: MethodCall, @NonNull result: Result) {
        val fragment = activity as FragmentActivity
        payme.openWallet(fragment.supportFragmentManager,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun deposit(@NonNull call: MethodCall, @NonNull result: Result) {
        val amount = call.argument<Int>("amount")
        if (amount != null && amount < 10000) {
            result.error("MIN_LIMIT", "Vui lòng nạp hơn 10.000VND", null)
            return
        }
        val fragment = activity as FragmentActivity
        payme.deposit(fragment.supportFragmentManager, amount, true,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun withdraw(@NonNull call: MethodCall, @NonNull result: Result) {
        val amount = call.argument<Int>("amount")
        if (amount != null && amount < 10000) {
            result.error("MIN_LIMIT", "Vui lòng rút hơn 10.000VND", null)
            return
        }
        val fragment = activity as FragmentActivity
        payme.withdraw(fragment.supportFragmentManager, amount, true,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun openKYC(@NonNull call: MethodCall, @NonNull result: Result) {
        val fragment = activity as FragmentActivity
        payme.openKYC(fragment.supportFragmentManager,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun pay(@NonNull call: MethodCall, @NonNull result: Result) {
        val amount = call.argument<Int>("amount")
        val note = call.argument<String>("note")
        val orderId = call.argument<String>("order_id")
        val storeId = call.argument<String>("store_id")
        val payCode = call.argument<String>("pay_code")
        val extraData = call.argument<String>("extra_data")
        val isShowResultUI = call.argument<Boolean>("is_show_result_ui")
        val userName = call.argument<String>("user_name")
        if (amount == null || storeId == null || isShowResultUI == null || payCode == null || orderId == null) {
            result.error("MISSING_INFO", "Missing info", null)
            return
        }
        if (amount < 10000) {
            result.error("MIN_LIMIT", "Vui lòng thanh toán hơn 10.000VND", null)
            return
        }
        val fragment = activity as FragmentActivity
        val infoPayment = InfoPayment("PAY", amount, note, orderId, storeId.toLong(), "OpenEWallet", extraData, userName)
        payme.pay(fragment.supportFragmentManager, infoPayment, isShowResultUI, payCode,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                })

    }

    private fun transfer(@NonNull call: MethodCall, @NonNull result: Result) {
        val amount = call.argument<Int>("amount")
        val note = call.argument<String>("note")
        if (amount != null && amount < 10000) {
            result.error("MIN_LIMIT", "Vui lòng thanh toán hơn 10.000VND", null)
            return
        }
        var description = ""
        if (note != null) {
            description = note
        }
        val fragment = activity as FragmentActivity
        payme.transfer(fragment.supportFragmentManager, amount, description, true,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                })

    }

    private fun logout(@NonNull call: MethodCall, @NonNull result: Result) {
        payme.logout()
        result.success(null)
    }

    private fun setLanguage(@NonNull call: MethodCall, @NonNull result: Result) {
        val lang = when (call.argument<String>("language")) {
            "VN" -> LANGUAGES.VI
            "EN" -> LANGUAGES.EN
            else -> LANGUAGES.VI
        }
        payme.setLanguage(context, lang)
        result.success(null)
    }

    private fun openService(@NonNull call: MethodCall, @NonNull result: Result) {
        val sCode = call.argument<String>("service_code")
        val sDesc = call.argument<String>("service_desc")
        if (sCode == null || sDesc == null) {
            result.error("MISSING_INFO", "Missing info", null)
            return
        }
        val fragment = activity as FragmentActivity
        val service = Service(sCode, sDesc)
        payme.openService(fragment.supportFragmentManager, service,
                onSuccess = { data: JSONObject? ->
                    if (data == null) {
                        result.success(data)
                    } else {
                        result.success(data.toString())
                    }
                },
                onError = { jsonObject: JSONObject?, code: Int, message: String? ->
                    println(message)
                    result.error(handleErrorCode(code), message, jsonObject)
                }
        )
    }

    private fun close() {
        payme.close()
    }

    private fun openHistory(@NonNull result: Result) {
        val fragment = activity as FragmentActivity
        payme.openHistory(fragment.supportFragmentManager, onSuccess = { data: JSONObject? ->
            result.success(data?.toString() ?: data)
        }, onError = { jsonObject: JSONObject?, code: Int, message: String? ->
            println(message)
            result.error(handleErrorCode(code), message, jsonObject)
        })
    }

    private fun scanQR(@NonNull call: MethodCall, @NonNull result: Result) {
        val fragment = activity as FragmentActivity
        val payCode = call.argument<String>("pay_code")
        if (payCode == null) {
            result.error("MISSING_INFO", "Missing info", null)
            return
        }
        payme.scanQR(fragment.supportFragmentManager, payCode!!, onSuccess = { data: JSONObject? ->
           result.success(data?.toString() ?: data)
        }, onError = { jsonObject: JSONObject?, code: Int, message: String? ->
            println(message)
            result.error(handleErrorCode(code), message, jsonObject)
        })
    }

    private fun payQRCode(@NonNull call: MethodCall, @NonNull result: Result) {
        val fragment = activity as FragmentActivity
        val qr = call.argument<String>("qr")
        val payCode = call.argument<String>("pay_code")
        val isShowResultUI = call.argument<Boolean>("is_show_result_ui") ?: true
        if (qr == null && payCode == null) {
            result.error("MISSING_INFO", "Missing info", null)
            return
        }
        payme.payQRCode(fragment.supportFragmentManager, qr = qr!!, payCode = payCode!!, isShowResultUI = isShowResultUI,
                onSuccess = { data: JSONObject? ->
            result.success(data?.toString() ?: data)
        }, onError = { jsonObject: JSONObject?, code: Int, message: String? ->
            println(message)
            result.error(handleErrorCode(code), message, jsonObject)
        })
    }

    private fun handleErrorCode(code: Int): String {
        when (code) {
            ERROR_CODE.EXPIRED -> "EXPIRED"
            ERROR_CODE.OTHER -> "OTHER"
            ERROR_CODE.NETWORK -> "NETWORK"
            ERROR_CODE.SYSTEM -> "SYSTEM"
            ERROR_CODE.LITMIT -> "LIMIT"
            ERROR_CODE.ACCOUNT_NOT_ACTIVATED -> "ACCOUNT_NOT_ACTIVATED"
            ERROR_CODE.ACCOUNT_NOT_KYC -> "ACCOUNT_NOT_KYC"
            ERROR_CODE.PAYMENT_ERROR -> "PAYMENT_ERROR"
            ERROR_CODE.ERROR_KEY_ENCODE -> "ERROR_KEY_ENCODE"
            ERROR_CODE.USER_CANCELLED -> "USER_CANCELLED"
            ERROR_CODE.ACCOUNT_NOT_LOGIN -> "ACCOUNT_NOT_LOGIN"
            ERROR_CODE.BALANCE_ERROR -> "BALANCE_ERROR"
            else -> "UNKNOWN_ERROR"
        }
        return "UNKNOWN_ERROR"
    }
}
