import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static bool dev = false;
  static String devServer = 'http://127.0.0.1:420';
  static String staticBaseUrl = 'https://cif.stormkit.dev';
  static String source = '${kIsWeb ? '' : staticBaseUrl}/videos.json';
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

  static String getServer(int serverId) {
    if (dev) {
      return devServer;
    }
    return [
      'https://code-in-life.netlify.app',
      'https://code-in-life.onrender.com'
    ][serverId];
  }

  static String getSearchApi(int serverId) {
    String server = getServer(serverId);
    if (serverId < 1) {
      return '$server/video/search/api';
    }
    return '$server/video/search/proxy';
  }

  static String getPosterApi(int serverId, String key, int id) {
    return '${getServer(serverId)}/video/$key/$id/poster';
  }

  static String getDetailApi(int serverId) {
    return '${getServer(serverId)}/video/api';
  }

  static Future<SearchVideoList> getSearchVideo(
      int serverId, SearchQuery query) async {
    String searchUrl = '${getSearchApi(serverId)}?s=${query.s}';
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

  static Future<String?> getVideoPoster(
      int serverId, String key, int id) async {
    String api = getPosterApi(serverId, key, id);
    Response response = await get(Uri.parse(api));
    String? matchedImage = RegExp(r'https?://.+?\.((jpe?|pn)g|webp)')
        .firstMatch(response.body)?[0];
    return matchedImage;
  }

  static Future<VideoInfo?> getVideoDetail(
      int serverId, String key, int id) async {
    String api =
        '${getDetailApi(serverId)}?api=$key&id=$id';
    Response response = await get(Uri.parse(api));
    String? base64Str = base64JsonDataParser(response.body);
    if (base64Str != null) {
      return VideoInfo.fromBase64(base64Str);
    }
    return null;
  }
}
