import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import './type.dart';
export './type.dart';

class Api {
  static String apiServer = 'https://spacedeta-1-f1000878.deta.app';
  static String videoSource = kIsWeb ? '/videos.json' : '$apiServer/api/video';
  static String tvSource = '$apiServer/api/video/tv';

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
      Map? data = await getJson(url);
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

  static Future<VideoData?> getSourceData() async {
    VideoData? videoData;
    Map? videoDataMap = await getJson(Api.videoSource);
    if (videoDataMap != null) {
      videoData = VideoData.fromMap(videoDataMap);
      List? mapList = await getJson<List>(Api.tvSource);
      List<Tv>? tvList = mapList?.map((item) => Tv.fromMap(item as Map)).toList();
      if (tvList != null) {
        videoData.videos.add(VideoSection('电视直播', tvList));
      }
    }
    return videoData;
  }

  static List<String> servers = [apiServer, 'https://apps.gatsbyjs.io', 'https://code-app.netlify.app'];

  static String getServer(int serverId) => servers[serverId];

  static String getDetailUrl(int serverId, String id) {
    String server = getServer(serverId);
    return '$server/video/play/$id';
  }

  static Future<SearchVideoList?> getSearchVideo(int serverId, SearchQuery query) async {
    String searchUrl = '${getServer(serverId)}/api/video/list?s=${query.s}';
    if (query.prefer18) {
      searchUrl += '&prefer=18';
    }
    List? listMap = await getApiJson(searchUrl);
    return listMap != null ? SearchVideoList.fromMap(listMap) : null;
  }

  static String getVideoPoster(int serverId, String id) {
    return '${getServer(serverId)}/api/video/$id?type=poster';
  }

  static Future<VideoInfo?> getVideoDetail(int serverId, String id) async {
    String api = '${getServer(serverId)}/api/video/$id';
    Map? jsonMap = await getApiJson(api);
    return jsonMap != null ? VideoInfo.fromMap(jsonMap) : null;
  }

  static Future<String?> parseVideoUrl(String url) => getApiJson<String>('$apiServer/api/video/parse?url=$url');
}
