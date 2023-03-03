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
  bool episodePickerShow = false;
  bool controlsVisible = true;

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

  void _playEpisode(int episode) {
    playEpisode = episode;
    playUrl = _getVideoUrl(widget.video as Series, episode);
    setState(() {});
  }

  void _setFullScreen() async {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    setState(() {
      isFullScreen = true;
    });
  }

  void _exitFullScreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    setState(() {
      isFullScreen = false;
    });
  }

  void _toggleFullScreen() async {
    isFullScreen ? _exitFullScreen() : _setFullScreen();
  }

  void _onEnd() {
    if (widget.video is Series &&
        playEpisode < (widget.video as Series).episodes - 1) {
      _playEpisode(playEpisode + 1);
    }
  }

  Future<void> _onControlsVisibleStateChange(bool visible) async {
    if (isFullScreen) {
      if (visible) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
      else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    }
    setState(() {
      controlsVisible = visible;
    });
  }

  void _hideEpisodePicker() {
    setState(() {
      episodePickerShow = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(onWillPop: () {
      if (isFullScreen) {
        _exitFullScreen();
        return Future.value(false);
      } else {
        return Future.value(true);
      }
    }, child: SafeArea(
      child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
        bool isLand = orientation == Orientation.landscape;
        return Scaffold(
          appBar: isFullScreen ? null : AppBar(title: Text(widget.video.title)),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    bottom: isLand ? 0 : .6 * constraints.maxHeight,
                    child: Container(
                        constraints: const BoxConstraints.expand(),
                        color: Colors.black,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            NetworkVideoPlayer(
                                url: playUrl,
                                themeColor: Theme.of(context).primaryColor,
                                toggleFullScreen: _toggleFullScreen,
                                onEnd: _onEnd,
                                onControlsVisibleStateChange:
                                _onControlsVisibleStateChange),
                            Positioned(
                              left: 0,
                              top: 0,
                              right: 0,
                              child: Offstage(
                                offstage: !(isFullScreen && controlsVisible),
                                child: AppBar(
                                  title: Text(widget.video.title),
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  actions: widget.video is Series
                                      ? [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            episodePickerShow =
                                            !episodePickerShow;
                                          });
                                        },
                                        icon: const Icon(Icons
                                            .playlist_add_check_outlined))
                                  ]
                                      : [],
                                ),
                              ),
                            ),
                            episodePickerShow
                                ? GestureDetector(
                              onTap: _hideEpisodePicker,
                              child: Container(
                                width: constraints.maxWidth,
                                height: constraints.maxWidth,
                                color: Colors.black26,
                              ),
                            )
                                : Container(),
                            widget.video is Series
                                ? AnimatedPositioned(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn,
                                top: 0,
                                right: episodePickerShow ? 0 : -160.0,
                                child: Container(
                                  width: 150.0,
                                  height: constraints.maxHeight,
                                  decoration: const BoxDecoration(
                                      color: Colors.black54),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.all(16.0),
                                        decoration: const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    width: 1,
                                                    color: Colors.white24))),
                                        child: const Text('选集',
                                            style:
                                            TextStyle(color: Colors.white)),
                                      ),
                                      Expanded(
                                        child: ListView(
                                          padding: EdgeInsets.zero,
                                          children: <Widget>[
                                            for (int i = 1;
                                            i <=
                                                (widget.video as Series)
                                                    .episodes;
                                            i++)
                                              ListTile(
                                                title: Text('第$i集',
                                                    style: TextStyle(
                                                        color: playEpisode == i
                                                            ? Theme.of(context)
                                                            .primaryColor
                                                            : Colors.white)),
                                                onTap: () {
                                                  _playEpisode(i);
                                                  _hideEpisodePicker();
                                                },
                                              )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ))
                                : Container()
                          ],
                        )
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: constraints.maxHeight * (isLand ? 1 : .4),
                    right: 0,
                    bottom: 0,
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
                                        onTap: () => _playEpisode(i),
                                        child: Container(
                                          width:
                                          (constraints.maxWidth -
                                              48.0) /
                                              5,
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
                  )
                ],
              );
            },
          ),
        );
      }),
    ));
  }
}
