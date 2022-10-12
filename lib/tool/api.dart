import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static String source = kIsWeb ? '/videos.json' : 'https://code-in-life.netlify.app/videos.json';
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
