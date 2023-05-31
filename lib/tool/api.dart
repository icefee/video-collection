import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {

  static String apiServer = 'https://spacedeta-1-f1000878.deta.app';
  static String source = kIsWeb ? '/videos.json' : '$apiServer/api/video';

  static Future<T?> getJson<T>(String url) async {
    try {
      Response response = await get(Uri.parse(url));
      String json = utf8.decode(response.bodyBytes);
      T data = jsonDecode(json);
      return data;
    } catch (err) {
      return null;
    }
  }

  static Future<T?> getApiJson<T>(String url) async {
    try {
      Map? data = await getJson<Map>(url);
      if (data == null) {
        throw const SocketException('network error');
      }
      ApiResponse<T> result = ApiResponse.fromMap<T>(data);
      if (result.code == 0) {
        return result.data;
      } else {
        throw result.msg;
      }
    } catch (err) {
      return null;
    }
  }

  static Future<VideoData?> getSourceData(String url) async {
    Map? videoData = await getJson<Map>(url);
    return videoData != null ? VideoData.fromMap(videoData) : null;
  }

  static List<String> servers = [
    apiServer,
    'https://apps.gatsbyjs.io',
    'https://code-app.netlify.app'
  ];

  static String getServer(int serverId) => servers[serverId];

  static String getDetailUrl(int serverId, String id) {
    String server = getServer(serverId);
    return '$server/video/play/$id';
  }

  static Future<SearchVideoList?> getSearchVideo(
      int serverId, SearchQuery query) async {
    String searchUrl = '${getServer(serverId)}/api/video/list?s=${query.s}';
    if (query.prefer18) {
      searchUrl += '&prefer=18';
    }
    List? result = await getApiJson(searchUrl);
    return result != null ? SearchVideoList.fromMap(result) : null;
  }

  static String getVideoPoster(int serverId, String id) {
    return '${getServer(serverId)}/api/video/$id?type=poster';
  }

  static Future<VideoInfo?> getVideoDetail(
      int serverId, String id) async {
    String api = '${getServer(serverId)}/api/video/$id';
    Map? result = await getApiJson(api);
    return result != null ? VideoInfo.fromMap(result) : null;
  }
}
