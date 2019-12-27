# sunmi_thermal_printer

A Flutter plugin for accessing the thermal printer on SunMi devices.

Tested on:
SunMi V2 Pro

Probably works on other Sunmi devices equipped with SEIKO thermal printer.

## Getting Started

Required permissions in AndroidManifest.xml:
``` xml
<uses-permission android:name="android.permission.BLUETOOTH" />
```
Needed to set up a virtual Bluetooth connection to communicate with the printer on the device.

In android/app/build.gradle:
Make sure `minSdkVersion` is set to 19 or above
Add to your dependencies:
``` groovy
implementation group: 'com.google.zxing', name: 'core', version: '3.4.0'
```

### Usage Example
``` dart
// instantiate and queue your instructions
var printer = SunmiThermalPrinter()
  ..println('HELLO WORLD!')
  ..divider()
  ..qr('HELLO WORLD!', moduleSize: 8);
// execute printing
printer.exec();
```

See example app for a a detailed receipt example.