import 'package:flutter/material.dart';
import '../tool/type.dart';
import '../pages/detail.dart';

class VideoList extends StatelessWidget {
  const VideoList({Key? key, required this.section}) : super(key: key);

  final VideoSection section;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).primaryColor.withOpacity(.2),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(width: 5, color: Theme.of(context).primaryColor)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text(section.section, style: const TextStyle(fontSize: 16.0)),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
              itemCount: section.series.length,
              itemBuilder: (BuildContext context, int index) {
                Video video = section.series[index];
                return ListTile(
                  leading: Icon(video is Series
                      ? Icons.video_collection_outlined
                      : video is Film
                          ? Icons.local_movies_outlined
                          : Icons.live_tv_outlined),
                  title: Text(video.title),
                  subtitle: video is Series ? Text('${video.episodes}集') : null,
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                    size: 16.0,
                  ),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (BuildContext context) => VideoDetail(video: video)));
                  },
                );
              },
              separatorBuilder: (BuildContext context, int index) => Divider(height: 1, color: Colors.grey[300])),
        )
      ],
    );
  }
}
