import 'dart:io';

import 'package:flutter/material.dart';
import '../tool/api.dart';

enum PendingState { none, pending, done, fail }

class Poster extends StatefulWidget {
  final String api;
  final int id;

  const Poster({super.key, required this.api, required this.id});

  @override
  State<StatefulWidget> createState() => _Poster();
}

class _Poster extends State<Poster> {
  PendingState pendingState = PendingState.none;
  String? poster;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getPosterUrl();
  }

  Future<void> getPosterUrl() async {
    setState(() {
      pendingState = PendingState.pending;
    });

    try {
      String? data = await Api.getVideoPoster(widget.api, widget.id);
      if (data != null) {
        setState(() {
          pendingState = PendingState.done;
          poster = data;
        });
      } else {
        throw const HttpException('timeout');
      }
    }
    catch (err) {
      if (mounted) {
        setState(() {
          pendingState = PendingState.fail;
        });
      }
    }
  }

  Widget get loadFail {
    return Container(
      color: Colors.red[200],
      child: const Center(
        child: Text('加载失败', style: TextStyle(fontSize: 12.0)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: SizedBox(
        child: Builder(
          builder: (BuildContext context) {
            switch (pendingState) {
              case PendingState.pending:
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Text('加载中', style: TextStyle(fontSize: 12.0)),
                  ),
                );
              case PendingState.done:
                return Image.network(
                  poster!,
                  fit: BoxFit.cover,
                  isAntiAlias: true,
                  errorBuilder:
                      (BuildContext context, Object error, StackTrace? trace) {
                    return loadFail;
                  },
                );
              case PendingState.fail:
                return loadFail;
              default:
                return Container();
            }
          },
        ),
      ),
    );
  }
}
