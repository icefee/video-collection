import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/player.dart';
import '../tool/type.dart';

class VideoDetail extends StatefulWidget {
  final Video video;

  const VideoDetail({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoDetail> createState() => _VideoDetail();
}

class _VideoDetail extends State<VideoDetail> {
  int playEpisode = 1;
  String playUrl = '';
  bool isFullScreen = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _initPlayer();
  }

  String _getVideoUrl(Series series, int episode) {
    List<String> params = series.m3u8List[episode - 1];
    String temp = series.urlTemplate;
    for (int i = 0; i < params.length; i++) {
      temp = temp.replaceAll('{$i}', params[i]);
    }
    return temp;
  }

  void _initPlayer() {
    if (widget.video is Film) {
      playUrl = (widget.video as Film).m3u8Url;
    } else {
      Series series = widget.video as Series;
      playUrl = _getVideoUrl(series, playEpisode);
    }
    setState(() {});
  }

  void _playeEpisode(int episode) {
    playEpisode = episode;
    playUrl = _getVideoUrl(widget.video as Series, episode);
    setState(() {});
  }

  void _setFullScreen() async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);
    setState(() {
      isFullScreen = true;
    });
  }

  void _exitFullScreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setState(() {
      isFullScreen = false;
    });
  }

  void _toggleFullScreen() async {
    isFullScreen ? _exitFullScreen() : _setFullScreen();
  }

  void _onEnd() {
    if (widget.video is Series && playEpisode < (widget.video as Series).episodes) {
      _playeEpisode(playEpisode + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
        onWillPop: () {
          if (isFullScreen) {
            _exitFullScreen();
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: isFullScreen
              ? null
              : AppBar(
                  title: Text(widget.video.title),
                ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return OrientationBuilder(
                builder: (BuildContext context, Orientation orientation) {
                  return Column(children: <Widget>[
                    Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight *
                            (orientation == Orientation.landscape ? 1 : .4),
                        color: Colors.black,
                        child: Center(
                          child: NetworkVideoPlayer(
                            url: playUrl,
                            themeColor: Theme.of(context).primaryColor,
                            toggleFullScreen: _toggleFullScreen,
                            onEnd: _onEnd,
                          ),
                        )),
                    Expanded(
                      child: Offstage(
                        offstage: orientation == Orientation.landscape,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 5.0),
                                margin: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                    border: Border(
                                        left: BorderSide(
                                            width: 5,
                                            color: Theme.of(context)
                                                .primaryColor))),
                                child: const Text('选集')),
                            widget.video is Film
                                ? Container(
                                    padding: const EdgeInsets.all(10.0),
                                    child: const Text('暂无'),
                                  )
                                : Expanded(
                                    child: ListView(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          alignment: Alignment.center,
                                          child: Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: [
                                              for (int i = 1;
                                                  i <=
                                                      (widget.video as Series)
                                                          .episodes;
                                                  i++)
                                                InkWell(
                                                  onTap: () => _playeEpisode(i),
                                                  child: Container(
                                                    width:
                                                        constraints.maxWidth /
                                                            6,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            width: 2),
                                                        color: playEpisode == i
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                            : Colors
                                                                .transparent),
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Center(
                                                      child: Text('第$i集',
                                                          style: TextStyle(
                                                              color: playEpisode ==
                                                                      i
                                                                  ? Colors.white
                                                                  : Colors
                                                                      .black)),
                                                    ),
                                                  ),
                                                )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                          ],
                        ),
                      ),
                    )
                  ]);
                },
              );
            },
          ),
        ));
  }
}
