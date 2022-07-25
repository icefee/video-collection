import 'dart:convert';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static String source = './videos.json';
  static Future<RequestData?> getSourceData(String url) async {
    Response response = await get(
      Uri.parse(url)
    );
    String json = utf8.decode(response.bodyBytes);
    Map videoData = jsonDecode(json);
    RequestData requestData = RequestData.fromMap(videoData);
    return requestData;
  }
}
