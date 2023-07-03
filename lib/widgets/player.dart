import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:math' show min, max;
import '../tool/parser.dart';
import '../tool/type.dart';
import '../tool/theme.dart';

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
  PlayState playState = PlayState.origin();
  bool pending = false;
  bool seeking = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();

    _initPlayer();
  }

  void videoPlayerControllerListener() {
    if (_controller.value.isInitialized) {
      if (_controller.value.isPlaying && _controller.value.position.inSeconds == _controller.value.duration.inSeconds) {
        widget.onEnd?.call();
      }
      if (!seeking) {
        playState = PlayState.fromVideoPlayerValue(_controller.value);
      }
      setState(() {});
    }
  }

  void _initPlayer() async {
    _controller = VideoPlayerController.network(widget.url);
    _controller.addListener(videoPlayerControllerListener);

    setState(() {
      failed = false;
      pending = true;
    });
    // await _controller.setLooping(true);
    try {
      await _controller.initialize();
      await _controller.play();
      setWakelock(true);
    } catch (err) {
      failed = true;
    }
    pending = false;
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant NetworkVideoPlayer oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposePlayer().then((value) => _initPlayer());
    }
  }

  Future<void> _disposePlayer() async {
    await _controller.dispose();
    setWakelock(false);
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.black,
        constraints: const BoxConstraints.expand(),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            Offstage(
              offstage: !(pending || _controller.value.isBuffering),
              child: Container(
                constraints: const BoxConstraints.expand(),
                child: Center(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(.8),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
            Offstage(
              offstage: failed,
              child: ControlsOverlay(
                controller: _controller,
                playState: playState,
                onSeeking: (double value) {
                  playState.played = value;
                  seeking = true;
                  setState(() {});
                },
                onSeekEnd: (double value) {
                  _controller
                      .seekTo(Duration(milliseconds: (value * _controller.value.duration.inMilliseconds).round()))
                      .then((value) {
                    seeking = false;
                  });
                },
                toggleFullScreen: () => widget.toggleFullScreen?.call(),
                onControlsVisibleStateChange: widget.onControlsVisibleStateChange,
              ),
            )
          ],
        ));
  }
}

class ControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final PlayState playState;
  final ValueChanged<double> onSeeking;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback toggleFullScreen;
  final ValueChanged<bool>? onControlsVisibleStateChange;

  const ControlsOverlay(
      {Key? key,
      required this.controller,
      required this.playState,
      required this.onSeeking,
      required this.onSeekEnd,
      required this.toggleFullScreen,
      this.onControlsVisibleStateChange})
      : super(key: key);

  @override
  State<ControlsOverlay> createState() => _ControlsOverlay();
}

class _ControlsOverlay extends State<ControlsOverlay> {
  bool controlsVisible = true;
  double originOffset = 0;

  Future<void> _togglePlay() async {
    if (widget.controller.value.isInitialized) {
      if (widget.controller.value.isPlaying) {
        await widget.controller.pause();
        setWakelock(false);
        _toggleControlsVisible(true);
      } else {
        await widget.controller.play();
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

  String get playedTime {
    return [widget.playState.duration * widget.playState.played, widget.playState.duration]
        .map(DateTimeParser.parseDuration)
        .join(' / ');
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
                  min(seconds + (details.globalPosition.dx - originOffset) * totalSeconds ~/ screenWidth,
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
              colors: [controlsVisible ? Colors.black54 : Colors.transparent, Colors.transparent],
              stops: const [.2, .75],
            )),
            duration: AppTheme.transitionDuration,
            child: AnimatedOpacity(
              opacity: controlsVisible ? 1 : 0,
              duration: AppTheme.transitionDuration,
              child: Center(
                child: IconButton(
                    onPressed: controlsVisible ? _togglePlay : null,
                    iconSize: 64,
                    icon: Icon(
                      widget.controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white.withOpacity(.8),
                    )),
              ),
            ),
          ),
        ),
        AnimatedPositioned(
            duration: AppTheme.transitionDuration,
            left: 0,
            right: 0,
            bottom: controlsVisible ? 0 : -100,
            curve: Curves.linearToEaseOut,
            child: Column(
              children: <Widget>[
                Slider.adaptive(
                    value: widget.playState.played,
                    secondaryTrackValue: widget.playState.buffered,
                    onChanged: widget.onSeeking,
                    onChangeEnd: widget.onSeekEnd,
                    secondaryActiveColor: Colors.white60,
                    inactiveColor: Colors.white30),
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          InkWell(
                            onTap: _togglePlay,
                            child: Icon(
                              widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 5.0),
                            child: Text(playedTime, style: const TextStyle(color: Colors.white, fontSize: 16.0)),
                          )
                        ],
                      ),
                      InkWell(
                        onTap: widget.toggleFullScreen,
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
            )),
      ],
    );
  }
}
