import 'dart:convert';

abstract class DateTimeParser {
  static String parseDuration(Duration duration) =>
      '$duration'.replaceAll(RegExp(r'\.\d+$'), '');
}

abstract class Base64Params {

  static String? parse(String text) {
    try {
      return utf8.decode(base64Decode(text + List.generate(4 - text.length % 4, (index) => '=').join()));
    }
    catch (e) {
      return null;
    }
  }

  static String create(String text) {
    return base64Encode(
      utf8.encode(text)
    ).replaceAll(RegExp(r'={1,2}$'), '');
  }
}
