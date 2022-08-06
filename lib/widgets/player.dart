import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' show min, max;

class NetworkVideoPlayer extends StatefulWidget {
  final String url;
  final Color themeColor;
  final VoidCallback? toggleFullScreen;
  final VoidCallback? onEnd;

  const NetworkVideoPlayer(
      {Key? key,
      required this.url,
      this.themeColor = Colors.blue,
      this.toggleFullScreen,
      this.onEnd})
      : super(key: key);

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayer();
}

class _NetworkVideoPlayer extends State<NetworkVideoPlayer> {
  late VideoPlayerController _controller;
  bool pending = false;

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
      if (_controller.value.isPlaying && _controller.value.position.inSeconds == _controller.value.duration.inSeconds) {
        widget.onEnd?.call();
      }

      setState(() {});
    });

    setState(() {
      pending = true;
    });
    // await _controller.setLooping(true);
    await _controller.initialize();
    await _controller.play();

    setState(() {
      pending = false;
    });
  }

  @override
  void didUpdateWidget(covariant NetworkVideoPlayer oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposePlayer();
      _initPlayer();
    }
  }

  void _disposePlayer() {
    _controller.dispose();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        ControlsOverlay(
            controller: _controller,
            pending: pending,
            toggleFullScreen: () => widget.toggleFullScreen?.call())
      ],
    );
  }
}

class ControlsOverlay extends StatefulWidget {
  const ControlsOverlay(
      {Key? key, required this.controller, required this.pending, required this.toggleFullScreen})
      : super(key: key);

  final VideoPlayerController controller;
  final bool pending;
  final VoidCallback toggleFullScreen;

  @override
  State<ControlsOverlay> createState() => _ControlsOverlay();
}

class _ControlsOverlay extends State<ControlsOverlay> {
  bool controlsVisible = true;
  double originOffset = 0;

  void _togglePlay() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
      setState(() {
        controlsVisible = true;
      });
    } else {
      widget.controller.play();
    }
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
            setState(() {
              controlsVisible = !controlsVisible;
            });
          },
          onDoubleTap: _togglePlay,
          onHorizontalDragStart: (DragStartDetails details) {
            originOffset = details.globalPosition.dx;
            setState(() {
              controlsVisible = true;
            });
          },
          onHorizontalDragUpdate: (DragUpdateDetails details) {
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
          },
          child: AnimatedContainer(
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
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
          child: controlsVisible
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: VideoProgressIndicator(widget.controller,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                              playedColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white30,
                              bufferedColor: Colors.white38
                          )
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              (widget.pending || widget.controller.value.isBuffering) ? const SizedBox(
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
                              ) : InkWell(
                                onTap: _togglePlay,
                                child: Icon(
                                  widget.controller.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
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
                              Icons.fullscreen,
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
