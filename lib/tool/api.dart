import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static String server = 'https://code-in-life.netlify.app';
  static String staticBaseUrl = kIsWeb ? '' : server;
  static String source = '$staticBaseUrl/videos.json';
  static Future<VideoData?> getSourceData(String url) async {
    Response response = await get(Uri.parse(url));
    String json = utf8.decode(response.bodyBytes);
    Map videoData = jsonDecode(json);
    VideoData requestData = VideoData.fromMap(videoData);
    return requestData;
  }

  static String? base64JsonDataParser(String source) {
    return RegExp(r'[a-zA-Z\d/+=]{100,}').firstMatch(source)?[0];
  }

  static Future<SearchVideoList> getSearchVideo(SearchQuery query) async {
    String searchUrl = '${Api.server}/video/search/api?s=${query.s}';
    if (query.prefer18) {
      searchUrl += '&prefer=18';
    }
    Response response = await get(Uri.parse(searchUrl));
    String? base64Str = base64JsonDataParser(response.body);
    if (base64Str == null) {
      return SearchVideoList([]);
    }
    SearchVideoList searchVideoList = SearchVideoList.fromBase64(base64Str);
    return searchVideoList;
  }

  static Future<String?> getVideoPoster(String key, int id) async {
    String api = '${Api.server}/video/$key/$id/poster';
    Response response = await get(Uri.parse(api));
    String? matchedImage = RegExp(r'https?://.+?\.((jpe?|pn)g|webp)')
        .firstMatch(response.body)?[0];
    return matchedImage;
  }

  static Future<VideoInfo?> getVideoDetail(String key, int id) async {
    String api = '${Api.server}/video/api?api=$key&id=$id'; // /video/api?api=${site}&id=${id}
    Response response = await get(Uri.parse(api));
    String? base64Str = base64JsonDataParser(response.body);
    if (base64Str != null) {
      return VideoInfo.fromBase64(base64Str);
    }
    return null;
  }
}
