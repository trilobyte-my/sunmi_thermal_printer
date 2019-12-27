package my.trilobyte.sunmi_thermal_printer

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

/** SunmiThermalPrinterPlugin */
public class SunmiThermalPrinterPlugin: FlutterPlugin, MethodCallHandler {
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "sunmi_thermal_printer")
    channel.setMethodCallHandler(SunmiThermalPrinterPlugin())
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "sunmi_thermal_printer")
      channel.setMethodCallHandler(SunmiThermalPrinterPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
    "print" -> {
      try {
        var payload: ArrayList<HashMap<String, Any>?>? = call.argument("payload")
        if (payload == null) result.error("", "Nothing to do", null)
        var printer = Printer()
        for (item: HashMap<String, Any>? in payload.orEmpty()) {
          var itemMap = item.orEmpty()
          try {
            var params: ArrayList<Any?>? = itemMap["params"] as ArrayList<Any?>?
            printer.invoke(itemMap["method"] as String, params?.toArray())
          } catch (e: Exception) {
            result.error("", "Invalid Instruction", e)
          }
        }
        printer.lineSpacing()
        printer.newLine(3)
        result.success("PRINT SUCCESS")
        return
      } catch (e: Exception) {
        result.error("", "Printer Error", e)
        return
      }
    }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
  }
}
