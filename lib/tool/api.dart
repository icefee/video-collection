import 'dart:convert';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static String source = 'https://code-space.netlify.app/videos';
  static Future<RequestData?> getSouraceData(String url) async {
    Response response = await get(
      Uri.parse(url)
    );
    String html = response.body;
    RegExp regExp = RegExp(r'(?<=<script id="__NEXT_DATA__" type="application\/json">).+(?=<\/script>)', multiLine: true);
    RegExpMatch? matched = regExp.firstMatch(html);
    if (matched != null) {
      String? jsonStr = matched.group(0);
      if (jsonStr != null)  {
        Map videoData = jsonDecode(jsonStr);
        RequestData requestData = RequestData.fromMap(videoData);
        return requestData;
      }
      return null;
    }
    return null;
  }
}
