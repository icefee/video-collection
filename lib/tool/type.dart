import 'dart:convert';

class VideoData {
  late List<VideoSection> videos;

  VideoData(this.videos);
  static VideoData fromMap(Map map) {
    List<Map> videos = (map['videos'] as List).map((e) => e as Map).toList();
    List<VideoSection> sections =
        videos.map((Map section) => VideoSection.fromMap(section)).toList();
    return VideoData(sections);
  }
}

class VideoSection {
  late String section;
  late List<Video> series;

  VideoSection(this.section, this.series);

  static VideoSection fromMap(Map map) {
    String section = map['section'];
    List<Map<String, dynamic>> series =
        (map['series'] as List).map((e) => e as Map<String, dynamic>).toList();
    return VideoSection(
        section,
        series.map((Map<String, dynamic> s) {
          if (s['episodes'] != null) {
            return Series.fromMap(s);
          } else {
            return Film.fromMap(s);
          }
        }).toList());
  }
}

abstract class Video {
  late String title;
}

class Series implements Video {
  @override
  late String title;
  late int episodes;
  late String urlTemplate;
  late List<List<String>> m3u8List;
  Series(this.title, this.episodes, this.urlTemplate, this.m3u8List);

  static Series fromMap(Map<String, dynamic> map) {
    return Series(
        map['title'],
        map['episodes'],
        map['url_template'],
        (map['m3u8_list'] as List)
            .map((e) => (e as List).map((e) => e.toString()).toList())
            .toList());
  }
}

class Film implements Video {
  @override
  late String title;
  late String m3u8Url;
  Film(this.title, this.m3u8Url);

  static Film fromMap(Map map) {
    return Film(map['title']!, map['m3u8_url'] as String);
  }
}

class SearchVideoList {
  late List<SearchVideo> data;

  SearchVideoList(this.data);

  static SearchVideoList fromBase64(String text) {
    String jsonStr = utf8.decode(base64.decoder.convert(text));
    List data = jsonDecode(jsonStr);
    return SearchVideoList(data.map((e) => SearchVideo.fromMap(e)).toList());
  }

  static SearchVideoList fromMap(List data) {
    return SearchVideoList(data.map((e) => SearchVideo.fromMap(e)).toList());
  }
}

class SearchVideo {
  late String key;
  late String name;
  late double rating;
  late List<SearchVideoItem> data;

  SearchVideo(this.key, this.name, this.rating, this.data);

  static SearchVideo fromMap(Map map) {
    return SearchVideo(
        map['key'],
        map['name'],
        double.parse(map['rating'].toString()),
        (map['data'] as List)
            .map((e) => SearchVideoItem.fromMap(e as Map))
            .toList());
  }
}

class SearchQuery {
  late String s;
  late bool prefer18;
  SearchQuery(this.s, this.prefer18);
}

class SearchVideoItem {
  late int id;
  late String name;
  late String note;
  late String last;
  late String dt;
  late int tid;
  late String type;

  SearchVideoItem(
      this.id, this.name, this.note, this.last, this.dt, this.tid, this.type);

  static SearchVideoItem fromMap(Map map) {
    return SearchVideoItem(map['id'], map['name'], map['note'], map['last'],
        map['dt'], map['tid'], map['type']);
  }
}

class VideoInfo {
  late int tid;
  late String name;
  late String note;
  late String pic;
  late String type;
  late dynamic year;
  late List<VideoSource> dataList;
  late String des;
  String? actor;
  String? area;
  String? director;
  String? lang;
  late String last;
  late dynamic state;
  VideoInfo(this.tid, this.name, this.note, this.pic, this.type, this.year, this.dataList,
      this.des,
      this.last,
      this.state,
      {this.actor, this.area, this.director, this.lang});

  factory VideoInfo.fromBase64(String source) {
    String jsonStr = utf8.decode(base64.decoder.convert(source));
    Map data = jsonDecode(jsonStr);
    return VideoInfo.fromMap(data);
  }

  factory VideoInfo.fromMap(Map map) {
    return VideoInfo(
      map['tid'],
      map['name'],
      map['note'],
      map['pic'],
      map['type'],
      map['year'],
      (map['dataList'] as List).map((e) => VideoSource.fromMap(e)).toList(),
      map['des'],
      map['last'],
      map['state'],
      actor: map['actor'],
      area: map['area'],
      director: map['director'],
      lang: map['lang'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tid': tid,
      'name': name,
      'note': note,
      'pic': pic,
      'type': type,
      'year': year,
      'dataList': dataList.map((VideoSource source) => source.fromMap()).toList(),
      'des': des,
      'last': last,
      'state': state,
      'actor': actor,
      'area': area,
      'director': director,
      'lang': lang
    };
  }
}

class VideoSource {
  late String name;
  late List<VideoItem> urls;

  VideoSource(this.name, this.urls);

  factory VideoSource.fromMap(Map map) {
    return VideoSource(map['name'],
        (map['urls'] as List).map((e) => VideoItem.fromMap(e as Map)).toList());
  }

  Map<String, dynamic> fromMap() {
    return <String, dynamic>{
      'name': name,
      'urls': urls.map((VideoItem videoItem) => videoItem.toMap()).toList()
    };
  }
}

class VideoItem {
  late String label;
  late String url;
  VideoItem(this.label, this.url);

  factory VideoItem.fromMap(Map map) {
    return VideoItem(map['label'], map['url']);
  }

  Map<String, String> toMap() {
    return <String, String>{
      'label': label,
      'url': url
    };
  }
}

class ApiResponse<T> {
  late int code;
  late T data;
  late String msg;

  ApiResponse(this.code, this.data, this.msg);

  static fromMap<E>(Map map) {
    return ApiResponse<E>(map['code'], map['data'], map['msg']);
  }
}
