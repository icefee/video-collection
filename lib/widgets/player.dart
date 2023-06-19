import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:math' show min, max;

void setWakelock(bool enable) {
  if (!kIsWeb) {
    enable ? Wakelock.enable() : Wakelock.disable();
  }
}

class NetworkVideoPlayer extends StatefulWidget {
  final String url;
  final Color themeColor;
  final VoidCallback? toggleFullScreen;
  final VoidCallback? onEnd;
  final ValueChanged<bool>? onControlsVisibleStateChange;

  const NetworkVideoPlayer(
      {Key? key,
      required this.url,
      this.themeColor = Colors.blue,
      this.toggleFullScreen,
      this.onEnd,
      this.onControlsVisibleStateChange})
      : super(key: key);

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayer();
}

class _NetworkVideoPlayer extends State<NetworkVideoPlayer> {
  late VideoPlayerController _controller;
  bool pending = false;
  bool failed = false;
  ScaffoldFeatureController? messageBanner;

  @override
  void initState() {
    super.initState();

    _initPlayer();
  }

  void _initPlayer() async {
    _controller = VideoPlayerController.network(
      widget.url,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.isPlaying &&
          _controller.value.position.inSeconds ==
              _controller.value.duration.inSeconds) {
        widget.onEnd?.call();
      }

      setState(() {});
    });

    setState(() {
      failed = false;
      pending = true;
    });
    // await _controller.setLooping(true);
    try {
      await _controller.initialize();
    } catch (err) {
      if (!mounted) {
        return;
      }

      setState(() {
        failed = true;
      });

      messageBanner = ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
            content: const Text('视频源连接失败, 请尝试切换网络重试.'),
            contentTextStyle: const TextStyle(color: Colors.white),
            backgroundColor: Colors.red,
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    _disposeErrorMsg();
                    _disposePlayer();
                    _initPlayer();
                  },
                  child:
                      const Text('重试', style: TextStyle(color: Colors.white)))
            ]),
      );

      setState(() {
        pending = false;
      });
      return;
    }

    setState(() {
      pending = false;
    });
    await _controller.play();
    setWakelock(true);
  }

  Future<void> _disposeErrorMsg() async {
    messageBanner?.close();
    await messageBanner?.closed;
    messageBanner = null;
  }

  @override
  void didUpdateWidget(covariant NetworkVideoPlayer oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposePlayer();
      _disposeErrorMsg();
      _initPlayer();
    }
  }

  void _disposePlayer() {
    _controller.dispose();
    setWakelock(false);
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (failed) {
            await _disposeErrorMsg();
          }
          return true;
        },
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            Offstage(
              offstage: failed,
              child: ControlsOverlay(
                controller: _controller,
                pending: pending,
                toggleFullScreen: () => widget.toggleFullScreen?.call(),
                onControlsVisibleStateChange:
                    widget.onControlsVisibleStateChange,
              ),
            )
          ],
        ));
  }
}

class ControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final bool pending;
  final VoidCallback toggleFullScreen;
  final ValueChanged<bool>? onControlsVisibleStateChange;

  const ControlsOverlay(
      {Key? key,
      required this.controller,
      required this.pending,
      required this.toggleFullScreen,
      this.onControlsVisibleStateChange})
      : super(key: key);

  @override
  State<ControlsOverlay> createState() => _ControlsOverlay();
}

class _ControlsOverlay extends State<ControlsOverlay> {
  bool controlsVisible = true;
  double originOffset = 0;

  void _togglePlay() {
    if (widget.controller.value.isInitialized) {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        setWakelock(false);
        _toggleControlsVisible(true);
      } else {
        widget.controller.play();
        setWakelock(true);
      }
    }
  }

  void _toggleControlsVisible(bool visible) {
    setState(() {
      controlsVisible = visible;
    });
    widget.onControlsVisibleStateChange?.call(visible);
  }

  String timeFormatter(Duration d) {
    int s = d.inSeconds;
    int m = d.inMinutes;
    int h = d.inHours;
    if (s < 3600) {
      return '${m.toString().padLeft(2, '0')}:${(s - m * 60).toString().padLeft(2, '0')}';
    }
    return '${h.toString().padLeft(2, '0')}:${(m - h * 60).toString().padLeft(2, '0')}:${(s - m * 60).toString().padLeft(2, '0')}';
  }

  String get playedTime {
    Duration current = widget.controller.value.position;
    Duration total = widget.controller.value.duration;
    return '${timeFormatter(current)} / ${timeFormatter(total)}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            _toggleControlsVisible(!controlsVisible);
          },
          onDoubleTap: _togglePlay,
          onHorizontalDragStart: (DragStartDetails details) {
            originOffset = details.globalPosition.dx;
            _toggleControlsVisible(true);
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            if (widget.controller.value.isInitialized) {
              int seconds = widget.controller.value.position.inSeconds;
              int totalSeconds = widget.controller.value.duration.inSeconds;
              double screenWidth = MediaQuery.of(context).size.width;
              seconds = max(
                  0,
                  min(
                      seconds +
                          (details.globalPosition.dx - originOffset) *
                              totalSeconds ~/
                              screenWidth,
                      totalSeconds));
              widget.controller.seekTo(Duration(seconds: seconds));
              originOffset = details.globalPosition.dx;
            }
          },
          child: AnimatedContainer(
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [
                controlsVisible ? Colors.black54 : Colors.transparent,
                Colors.transparent
              ],
              stops: const [.2, .5],
            )),
            duration: const Duration(milliseconds: 200),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: (controlsVisible || widget.pending)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: VideoProgressIndicator(widget.controller,
                          allowScrubbing: true,
                          padding: const EdgeInsets.all(8.0),
                          colors: VideoProgressColors(
                              playedColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white30,
                              bufferedColor: Colors.white38)),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              (widget.pending ||
                                      widget.controller.value.isBuffering)
                                  ? const SizedBox(
                                      width: 36,
                                      child: Center(
                                        child: SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : InkWell(
                                      onTap: _togglePlay,
                                      child: Icon(
                                        widget.controller.value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36.0,
                                      ),
                                    ),
                              Container(
                                margin: const EdgeInsets.only(left: 5.0),
                                child: Text(playedTime,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16.0)),
                              )
                            ],
                          ),
                          InkWell(
                            onTap: () => widget.toggleFullScreen(),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 36.0,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
