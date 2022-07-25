import 'package:flutter/material.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import '../tool/type.dart';

String getVideoUrl(String urlTemplate, List<String> params) {
  String url = urlTemplate;
  for (int i = 0; i < params.length; i ++) {
    url = url.replaceAll('{$i}', params[i]);
  }
  return url;
}

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({Key? key, required this.video}) : super(key: key);
  final Video video;

  @override
  State<StatefulWidget> createState() => _VideoPlayer();
}

class _VideoPlayer extends State<VideoPlayer> {
  late FlickManager flickManager;
  late String playingVideoUrl;

  @override
  void initState() {

    super.initState();

    if (widget.video is Series) {
      Series series = widget.video as Series;
      playingVideoUrl = getVideoUrl(series.urlTemplate, series.m3u8List.first);
    }
    else {
      playingVideoUrl = (widget.video as Film).m3u8Url;
    }
    flickManager = FlickManager(
      videoPlayerController: VideoPlayerController.network(playingVideoUrl),
    );
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: boxConstraints.maxHeight * .4,
                child: FlickVideoPlayer(
                    flickManager: flickManager
                ),
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    Text(widget.video.title)
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
