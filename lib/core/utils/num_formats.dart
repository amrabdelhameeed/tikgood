import 'package:easy_localization/easy_localization.dart';

class NumberFormats {
  static final decimalFormat = NumberFormat.decimalPattern();
  static final decimalFormatOneDigit = NumberFormat("#,##0.0");
  static final decimalFormatTwoDigits = NumberFormat("#,##0.00");

  static String formatWithOptionalDecimals(double value) {
    return value % 1 == 0
        ? NumberFormat("#,##0").format(value) // No decimal part if the value is an integer
        : decimalFormatTwoDigits.format(value); // Two decimal places otherwise
  }
}
