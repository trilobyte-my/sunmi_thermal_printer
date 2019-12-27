import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Used to access thermal printer on SunMi devices.
/// Currently supports 58mm only
///
/// TODO: Fullwidth character support (for CJK)
///
/// TODO: automatic QR scaling depending on data size
///
/// TODO: check if bitmap dimensions are within printer limits
class SunmiThermalPrinter {
  static const _charsPerLine = 32;
  static const MethodChannel _channel =
      const MethodChannel('sunmi_thermal_printer');

  int __width = 1, __height = 1;

  set _width(int val) => __width = bounded(val, 1, 16);
  set _height(int val) => __height = bounded(val, 1, 16);
  int get width => __width;
  int get height => __height;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  List<Map<String, dynamic>> _payload;

  PrintAlign _defaultAlign = PrintAlign.Left;

  /// Maximum characters per line
  int get cpl => _charsPerLine ~/ width;

  /// Runs stored printing instructions and resets the printer state afterwards.
  Future<void> exec() async {
    String res;
    try {
      res = await _channel.invokeMethod<String>(
          'print', <String, dynamic>{'payload': _payload});
      print(res);
    } on PlatformException catch (e) {
      rethrow;
    } finally {
      clear();
    }
  }

  void clear() => _payload = [];

  void _cmd(String method, [List<dynamic> params]) {
    if (_payload == null) _payload = [];
    List<MapEntry<String, dynamic>> entries = [];
    entries.add(MapEntry<String, dynamic>('method', method));
    if (params?.isNotEmpty == true) {
      entries.add(MapEntry<String, dynamic>('params', params));
    }
    Map<String, dynamic> map = Map();
    map.addEntries(entries);
    _payload.add(map);
  }

  String _repeat(String pattern, int n) =>
      (n < 1) ? '' : (n == 1) ? pattern : '$pattern${_repeat(pattern, n - 1)}';

  String _separated(String left, String right) {
    final pad = _repeat(' ', cpl - left.length - right.length);
    return '$left$pad$right';
  }

  void _alignDefault() => _cmd('align', [_defaultAlign.value]);

  /// Changes default alignment to either [Center, Left, Right].
  void align(PrintAlign align) {
    _defaultAlign = align;
    _alignDefault();
  }

  /// sets default printing Alignment to Center.
  void center() => align(PrintAlign.Center);

  /// sets default printing Alignment to Left.
  void left() => align(PrintAlign.Left);

  /// sets default printing Alignment to Right.
  void right() => align(PrintAlign.Right);

  /// prints a binary image represented as a bitmap [byte] list in (max width 384, max pixels 1M).
  void bitmap(Uint8List bytes, [PrintAlign align = PrintAlign.Center]) {
    if (align == _defaultAlign) {
      _bitmap(bytes);
    } else {
      var previousAlign = _defaultAlign;
      this
        ..align(align)
        .._bitmap(bytes)
        ..align(previousAlign);
      _defaultAlign = previousAlign;
    }
  }

  void _bitmap(Uint8List bytes) => _cmd('bitmap', [bytes]);

  /// Sets Bold state. When [state] is null, toggles on/off).
  void bold([bool state]) => _cmd('bold', [state]);

  /// NB: Does not seem to have any effect with some devices.
  void darkness(int level) => _cmd('darkness', [level]);

  /// Sets font scale multiplier as [scale]. (Min: 1 - Default, Max: 16).
  void fontScale([int scale = 1]) {
    _height = _width = scale;
    _cmd('fontSize', [scale, scale]);
  }

  /// Customises the font [width] and [height] multiplier. (min: 1 - Default), max: 16)
  void fontSize({int width = 1, int height = 1}) {
    _width = width;
    _height = height;
    _cmd('fontSize', [width, height]);
  }

  /// Proceeds [lines] number of lines down.
  /// Moves 1 line when [lines] is null.
  void newLine([int lines]) => _cmd('newLine', [lines]);

  /// Prints [str].
  /// NB: All printing on the same line will align according to the last alignment setting.
  void print([String str]) => _cmd('print', [str]);

  /// Prints [str] as with [print], then moves to the next line.
  void println([String str]) => _cmd('println', [str]);

  /// Prints [str] like in [println], but with alignment [align] without changing the affecting the default alignment.
  void printAlign([String str, PrintAlign align]) {
    if (align == _defaultAlign) {
      println(str);
    } else {
      var previousAlign = _defaultAlign;
      this
        ..align(align)
        ..println(str)
        ..align(previousAlign);
      _defaultAlign = previousAlign;
    }
  }

  String _pad(String str, [String pad = '*']) {
    if (str.length <= cpl - 2 - pad.length * 2) {
      pad = _repeat(pad, (cpl - str.length - 2) ~/ pad.length ~/ 2);
      return '$pad $str ${pad.split('').reversed.join()}';
    } else
      return str;
  }

  void printCenterPad(String str, String pad) =>
      printAlign(_pad(str, pad), PrintAlign.Center);

  /// Convenience method for [printAlign] with center alignment.
  void printCenter([String str]) => printAlign(str, PrintAlign.Center);

  /// Convenience method for [printAlign] with left alignment.
  void printLeft([String str]) => printAlign(str, PrintAlign.Left);

  /// Convenience method for [printAlign] with right alignment.
  void printRight([String str]) => printAlign(str, PrintAlign.Right);

  /// Prints a divider using [pattern]
  void divider([String pad = '\u2500']) =>
      printCenter(_repeat(pad, cpl ~/ pad.length));

  /// Sets the line spacing to [n] dots. Minimum: 0. Default: 30. Maximum: 127
  /// NB: If there are printed characters on the line, the line spacing is the higher of [n] and character height
  void lineSpacing([int n = 30]) => _cmd('lineSpacing', [n]);

  /// Prints a barcode containing [data] with format [symbology].
  ///
  /// Barcode [height] can be set between 1-255 dots.
  /// Barcode [width] (thickness) can be set between 2-6 dots.
  /// [textPosition] specifies where the barcode data is displayed.
  void barcode(String data,
      {BarcodeSymbology symbology = BarcodeSymbology.UPC_A,
      int height = 162,
      int width = 2,
      BarcodeText textPosition = BarcodeText.None,
      PrintAlign align = PrintAlign.Center}) {
    if (align == _defaultAlign) {
      _barcode(data, symbology, height, width, textPosition);
    } else {
      var previousAlign = _defaultAlign;
      this
        ..align(align)
        .._barcode(data, symbology, height, width, textPosition)
        ..align(previousAlign);
      _defaultAlign = previousAlign;
    }
  }

  void _barcode(String data, BarcodeSymbology symbology, int height, int width,
          BarcodeText textPosition) =>
      _cmd('barcode',
          [data, symbology.value, height, width, textPosition.value]);

  /// Prints [left] on the left, and [right] on the right, then moves to the next ilne
  void printLR(String left, String right) => println(_separated(left, right));

  /// Prints QR code of [data] with module width [moduleSize] (in pixels/dots) and error correction level [errorCode].
  ///
  /// Recommended minimum module size: 4
  void qr(String data,
      {int moduleSize = 4,
      QRErrorCode errorCode = QRErrorCode.L,
      PrintAlign align = PrintAlign.Center}) {
    if (align == _defaultAlign) {
      _qr(data, bounded(moduleSize, 1, 16), errorCode);
    } else {
      var previousAlign = _defaultAlign;
      this
        ..align(align)
        .._qr(data, bounded(moduleSize, 1, 16), errorCode)
        ..align(previousAlign);
      _defaultAlign = previousAlign;
    }
  }

  void _qr(String data, int moduleSize,
          [QRErrorCode errorCode = QRErrorCode.L]) =>
      _cmd('qr', [data, bounded(moduleSize, 1, 16), errorCode.value]);

  /// Similar to [qr], but prints two QR codes side-by-side.
  void qrPair(String data1, String data2,
      {int moduleSize = 4,
      QRErrorCode errorCode = QRErrorCode.L,
      PrintAlign align = PrintAlign.Center}) {
    if (align == _defaultAlign) {
      _qrPair(data1, data2, bounded(moduleSize, 1, 16), errorCode);
    } else {
      var previousAlign = _defaultAlign;
      this
        ..align(align)
        .._qrPair(data1, data2, bounded(moduleSize, 1, 16), errorCode)
        ..align(previousAlign);
      _defaultAlign = previousAlign;
    }
  }

  void _qrPair(String data1, String data2, int moduleSize,
          [QRErrorCode errorCode = QRErrorCode.L]) =>
      _cmd('qr2', [data1, data2, bounded(moduleSize, 1, 16), errorCode.value]);

  /// Sets Underline state.
  ///
  /// NB: [Underline.Thick] and [Underline.Thin] do not seem to be different on some devices
  void underline(Underline style) => _cmd('underline', [style.value]);

  /// fits [val] within [low] and [high].
  int bounded(int val, int low, int high) {
    assert(
        low <= high, 'Lower Bound must be less than or equal to Upper Bound.');
    return val < low ? low : (val > high ? high : val);
  }

  // TODO: Use to optimise QR printing size
  static const qrByteLimits = {
    1: QRVersion(version: 1, byteLimit: {
      QRErrorCode.L: 17,
      QRErrorCode.M: 14,
      QRErrorCode.Q: 11,
      QRErrorCode.H: 7,
    }),
    2: QRVersion(version: 2, byteLimit: {
      QRErrorCode.L: 32,
      QRErrorCode.M: 26,
      QRErrorCode.Q: 20,
      QRErrorCode.H: 14,
    }),
    3: QRVersion(version: 3, byteLimit: {
      QRErrorCode.L: 53,
      QRErrorCode.M: 42,
      QRErrorCode.Q: 32,
      QRErrorCode.H: 24,
    }),
    4: QRVersion(version: 4, byteLimit: {
      QRErrorCode.L: 78,
      QRErrorCode.M: 62,
      QRErrorCode.Q: 46,
      QRErrorCode.H: 34,
    }),
    5: QRVersion(version: 5, byteLimit: {
      QRErrorCode.L: 106,
      QRErrorCode.M: 84,
      QRErrorCode.Q: 60,
      QRErrorCode.H: 44,
    }),
    6: QRVersion(version: 6, byteLimit: {
      QRErrorCode.L: 134,
      QRErrorCode.M: 106,
      QRErrorCode.Q: 74,
      QRErrorCode.H: 58,
    }),
    7: QRVersion(version: 7, byteLimit: {
      QRErrorCode.L: 154,
      QRErrorCode.M: 122,
      QRErrorCode.Q: 86,
      QRErrorCode.H: 64,
    }),
    8: QRVersion(version: 8, byteLimit: {
      QRErrorCode.L: 192,
      QRErrorCode.M: 152,
      QRErrorCode.Q: 108,
      QRErrorCode.H: 84,
    }),
    9: QRVersion(version: 9, byteLimit: {
      QRErrorCode.L: 230,
      QRErrorCode.M: 180,
      QRErrorCode.Q: 130,
      QRErrorCode.H: 98,
    }),
    10: QRVersion(version: 10, byteLimit: {
      QRErrorCode.L: 271,
      QRErrorCode.M: 213,
      QRErrorCode.Q: 151,
      QRErrorCode.H: 119,
    }),
    11: QRVersion(version: 11, byteLimit: {
      QRErrorCode.L: 321,
      QRErrorCode.M: 251,
      QRErrorCode.Q: 177,
      QRErrorCode.H: 137,
    }),
    12: QRVersion(version: 12, byteLimit: {
      QRErrorCode.L: 367,
      QRErrorCode.M: 287,
      QRErrorCode.Q: 203,
      QRErrorCode.H: 155,
    }),
    13: QRVersion(version: 13, byteLimit: {
      QRErrorCode.L: 425,
      QRErrorCode.M: 331,
      QRErrorCode.Q: 241,
      QRErrorCode.H: 177,
    }),
    14: QRVersion(version: 14, byteLimit: {
      QRErrorCode.L: 458,
      QRErrorCode.M: 362,
      QRErrorCode.Q: 258,
      QRErrorCode.H: 194,
    }),
    15: QRVersion(version: 15, byteLimit: {
      QRErrorCode.L: 520,
      QRErrorCode.M: 412,
      QRErrorCode.Q: 292,
      QRErrorCode.H: 220,
    }),
    16: QRVersion(version: 16, byteLimit: {
      QRErrorCode.L: 586,
      QRErrorCode.M: 450,
      QRErrorCode.Q: 322,
      QRErrorCode.H: 250,
    }),
    17: QRVersion(version: 17, byteLimit: {
      QRErrorCode.L: 644,
      QRErrorCode.M: 504,
      QRErrorCode.Q: 364,
      QRErrorCode.H: 280,
    }),
    18: QRVersion(version: 18, byteLimit: {
      QRErrorCode.L: 718,
      QRErrorCode.M: 560,
      QRErrorCode.Q: 394,
      QRErrorCode.H: 310,
    }),
    19: QRVersion(version: 19, byteLimit: {
      QRErrorCode.L: 792,
      QRErrorCode.M: 624,
      QRErrorCode.Q: 442,
      QRErrorCode.H: 338,
    }),
    20: QRVersion(version: 20, byteLimit: {
      QRErrorCode.L: 858,
      QRErrorCode.M: 666,
      QRErrorCode.Q: 482,
      QRErrorCode.H: 382,
    }),
    21: QRVersion(version: 21, byteLimit: {
      QRErrorCode.L: 929,
      QRErrorCode.M: 711,
      QRErrorCode.Q: 509,
      QRErrorCode.H: 403,
    }),
    22: QRVersion(version: 22, byteLimit: {
      QRErrorCode.L: 1003,
      QRErrorCode.M: 779,
      QRErrorCode.Q: 565,
      QRErrorCode.H: 439,
    }),
  };
}

class QRVersion {
  final int version;
  final Map<QRErrorCode, int> byteLimit;
  const QRVersion({this.version, this.byteLimit});

  int get modulesPerSide => version * 4 + 17;
  int get totalModules => math.pow(modulesPerSide, 2);
}

enum PrintAlign { Center, Left, Right }

extension PrintAlignExt on PrintAlign {
  static const values = {
    PrintAlign.Center: 'CENTER',
    PrintAlign.Left: 'LEFT',
    PrintAlign.Right: 'RIGHT',
  };
  String get value => values[this];
}

enum Underline { Thin, Thick, None }

extension UnderlineExt on Underline {
  static const values = {
    Underline.Thin: 'THIN',
    Underline.Thick: 'THICK',
    Underline.None: 'NONE',
  };
  String get value => values[this];
}

/// Error correcting levels.
///
/// Damaged area to Entire Code Size:
///
/// L: 7% M: 15%, Q: 25%, H: 30%
enum QRErrorCode { L, M, Q, H }

extension QRErrorCodeExt on QRErrorCode {
  static const values = {
    QRErrorCode.L: 0,
    QRErrorCode.M: 1,
    QRErrorCode.Q: 2,
    QRErrorCode.H: 3,
  };
  int get value => values[this];
}

enum BarcodeText { None, Top, Bottom, Both }

extension BarcodeTextExt on BarcodeText {
  static const values = {
    BarcodeText.None: 0,
    BarcodeText.Top: 1,
    BarcodeText.Bottom: 2,
    BarcodeText.Both: 3,
  };
  int get value => values[this];
}

enum BarcodeSymbology {
  UPC_A,
  UPC_E,
  EAN_13,
  EAN_8,
  CODE_39,
  ITF,
  CODABAR,
  CODE_93,
  CODE_128,
  UNKNOWN_1,
  UNKNOWN_2,
}

extension BarcodeSymbologyExt on BarcodeSymbology {
  static const values = {
    BarcodeSymbology.UPC_A: 0,
    BarcodeSymbology.UPC_E: 1,
    BarcodeSymbology.EAN_13: 2,
    BarcodeSymbology.EAN_8: 3,
    BarcodeSymbology.CODE_39: 4,
    BarcodeSymbology.ITF: 5,
    BarcodeSymbology.CODABAR: 6,
    BarcodeSymbology.CODE_93: 7,
    BarcodeSymbology.CODE_128: 8,
    BarcodeSymbology.UNKNOWN_1:
        9, // TODO: find out which symbology this represents
    BarcodeSymbology.UNKNOWN_2:
        10, // TODO: find out which symbology this represents
  };
  int get value => values[this];
}
