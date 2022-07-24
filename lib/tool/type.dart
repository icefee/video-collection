
class RequestData {
  late List<VideoSection> videos;

  RequestData(this.videos);
  static RequestData fromMap(Map map) {
    Map<String, dynamic> props = map['props']['pageProps'];
    List<Map> videos = (props['videos'] as List).map((e) => e as Map).toList();
    List<VideoSection> sections = videos.map((Map section) => VideoSection.fromMap(section)).toList();
    return RequestData(sections);
  }
}

class VideoSection {
  late String section;
  late List<Video> series;

  VideoSection(this.section, this.series);

  static VideoSection fromMap(Map map) {
    String section = map['section'];
    List<Map<String, dynamic>> series = (map['series'] as List).map((e) => e as Map<String, dynamic>).toList();
    return VideoSection(
      section,
      series.map(
          (Map<String, dynamic> s) {
            if (s['episodes'] != null) {
              return Series.fromMap(s);
            }
            else {
              return Film.fromMap(s);
            }
          }
      ).toList()
    );
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
        (map['m3u8_list'] as List).map((e) => (e as List).map((e) => e.toString()).toList()).toList()
    );
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
