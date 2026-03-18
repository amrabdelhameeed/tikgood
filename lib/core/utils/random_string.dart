import 'dart:math';

class RandomFactory {
  RandomFactory._();
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static Random rnd = Random();
  static String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => _chars.codeUnitAt(rnd.nextInt(_chars.length))));
  static String getRandomNumber(int length) => (rnd.nextInt(9000) + 1000).toString();
}
