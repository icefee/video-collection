import 'package:flutter/material.dart';
import '../tool/api.dart';

class VideoUrlParser extends StatefulWidget {
  const VideoUrlParser({super.key, required this.url, required this.childBuilder});

  final String url;
  final Widget Function(String url) childBuilder;

  @override
  State<StatefulWidget> createState() => _VideoUrlParser();
}

class _VideoUrlParser extends State<VideoUrlParser> {
  Map<String, Widget> cachedWidgets = {};

  bool get isVideoUrl {
    return widget.url.contains(RegExp(r'.(mp4|ogg|webm|m3u8|flv)$'));
  }

  Widget get loading {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lightbulb, color: Theme.of(context).primaryColor),
          const SizedBox(width: 5),
          const Text('播放地址解析中...', style: TextStyle(color: Colors.white))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    if (isVideoUrl) {
      return widget.childBuilder(widget.url);
    }

    if (!cachedWidgets.containsKey(widget.url)) {
      cachedWidgets[widget.url] = FutureBuilder(
          future: Api.parseVideoUrl(widget.url),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loading;
            }
            return widget.childBuilder(snapshot.data ?? widget.url);
          });
    }
    return cachedWidgets[widget.url]!;
  }
}
