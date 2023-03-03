import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static bool dev = true;
  static String devServer = 'http://192.168.10.104:420';
  static String staticBaseUrl = 'https://c.stormkit.dev';
  static String source = '${kIsWeb ? '' : staticBaseUrl}/videos.json';

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
    return '$server/api/video/list';
  }

  static String getPosterApi(int serverId, String key, int id) {
    String server = getServer(serverId);
    if (serverId == 0) {
      return '$server/api/video/$key/$id?type=poster';
    }
    return '$server/api/video?api=$key&id=$id?type=poster';
  }

  static String getDetailApi(int serverId, String key, int id) {
    String server = getServer(serverId);
    if (serverId == 0) {
      return '$server/api/video/$key/$id';
    }
    return '$server/api/video?api=$key&id=$id';
  }

  static Future<SearchVideoList?> getSearchVideo(
      int serverId, SearchQuery query) async {
    String searchUrl = '${getSearchApi(serverId)}?s=${query.s}';
    if (query.prefer18) {
      searchUrl += '&prefer=18';
    }
    List? result = await getApiJson(searchUrl);
    return result != null ? SearchVideoList.fromMap(result) : null;
  }

  static Future<String?> getVideoPoster(
      int serverId, String key, int id) async {
    String api = getPosterApi(serverId, key, id);
    String? result = await getApiJson(api);
    return result;
  }

  static Future<VideoInfo?> getVideoDetail(
      int serverId, String key, int id) async {
    String api = getDetailApi(serverId, key, id);
    Map? result = await getApiJson(api);
    return result != null ? VideoInfo.fromMap(result) : null;
  }
}
