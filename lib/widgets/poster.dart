import 'package:flutter/material.dart';
import '../tool/api.dart';

class Poster extends StatefulWidget {
  final String src;

  const Poster(
      {super.key, required this.src});

  @override
  State<StatefulWidget> createState() => _Poster();
}

class _Poster extends State<Poster> {

  Widget get loadFail {
    return Image.network(
      '${Api.apiServer}/assets/image_fail.jpg',
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: SizedBox(
        child: Image.network(
          widget.src,
          fit: BoxFit.cover,
          isAntiAlias: true,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? trace) {
            return loadFail;
          },
        ),
      ),
    );
  }
}
