import 'package:flutter/material.dart';
import '../tool/api.dart';
import '../pages/video_collection.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  List<VideoSection> videos = [];
  VideoSection? activeSection;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getVideoSource();
  }

  Future<void> getVideoSource() async {
    RequestData? requestData = await Api.getSourceData(Api.source);
    if (requestData != null) {
      videos = requestData.videos;
      if (videos.isNotEmpty) {
        activeSection = videos.first;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频文件夹'),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage('assets/cover.jpeg')
                ),
                color: Colors.indigo,
              ),
              child: Container(),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: videos.length,
                itemBuilder: (BuildContext context, int index) {
                  VideoSection section = videos[index];
                  return ListTile(
                      leading: const Icon(Icons.video_collection),
                      title: Text(section.section),
                      onTap: () {
                        activeSection = section;
                        setState(() {});
                        Navigator.pop(context);
                      },
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16.0,
                      )
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    Divider(height: 1, color: Colors.grey[300]),
              ),
            )
          ],
        ),
      ),
      body: activeSection == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : VideoCollection(
              section: activeSection!,
            ),
    );
  }
}
