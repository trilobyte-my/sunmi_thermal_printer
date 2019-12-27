#import "SunmiThermalPrinterPlugin.h"
#if __has_include(<sunmi_thermal_printer/sunmi_thermal_printer-Swift.h>)
#import <sunmi_thermal_printer/sunmi_thermal_printer-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "sunmi_thermal_printer-Swift.h"
#endif

@implementation SunmiThermalPrinterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSunmiThermalPrinterPlugin registerWithRegistrar:registrar];
}
@end
