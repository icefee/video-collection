import 'package:flutter/material.dart';
import './detail.dart';
import '../tool/api.dart';
import '../widgets/poster.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  List<SearchVideo> videoList = [];
  bool loading = false;

  Future<void> getSearch(String s) async {
    setState(() {
      loading = true;
    });
    try {
      SearchVideoList result = await Api.getSearchVideo(SearchQuery(s, false));
      if (mounted) {
        setState(() {
          loading = false;
          videoList = result.data;
        });
      }
    } catch (err) {
      //
    }
  }

  Future<void> getVideoInfo(String key, int id) async {
    setState(() {
      loading = true;
    });
    try {
      VideoInfo? videoInfo = await Api.getVideoDetail(key, id);
      if (videoInfo != null) {
        VideoSource videoSource = videoInfo.dataList.firstWhere(
            (e) => e.name.contains(RegExp('m3u8', caseSensitive: false)));
        if (!context.mounted) return;
        String title = videoInfo.name;
        Video video = videoSource.urls.length > 1
            ? Series(title, videoSource.urls.length, '{0}',
                videoSource.urls.map((VideoItem item) => [item.url]).toList())
            : Film(title, videoSource.urls.first.url);

        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => VideoDetail(video: video)));
      }
      setState(() {
        loading = false;
      });
    } catch (err) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('搜索')),
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(5.0)),
              padding: const EdgeInsets.only(left: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: '输入关键词搜索'),
                      onSubmitted: (String text) {
                        if (text.trim().isNotEmpty) {
                          getSearch(text);
                        }
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 40,
                    child: Icon(Icons.search, color: Colors.grey),
                  )
                ],
              ),
            ),
          ),
          Expanded(
              child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(8.0),
                children: videoList
                    .asMap()
                    .keys
                    .map((int sourceIndex) => Container(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(videoList[sourceIndex].name),
                              ),
                              Column(
                                children: videoList[sourceIndex]
                                    .data
                                    .map((SearchVideoItem video) => Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero),
                                            onPressed: () => getVideoInfo(
                                                videoList[sourceIndex].key,
                                                video.id),
                                            child: Container(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(.4),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0)),
                                              clipBehavior: Clip.hardEdge,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        width: 80,
                                                        child: Poster(
                                                            api: videoList[
                                                                    sourceIndex]
                                                                .key,
                                                            id: video.id),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(video.name,
                                                                style:
                                                                    const TextStyle(
                                                                        fontSize:
                                                                            20)),
                                                            Chip(
                                                              label: Text(
                                                                  video.type,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          14)),
                                                              backgroundColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .secondaryHeaderColor,
                                                            ),
                                                            Text(video.note,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                            .grey[
                                                                        500]))
                                                          ],
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  const Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16.0)
                                                ],
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              )
                            ],
                          ),
                        ))
                    .toList(),
              ),
              Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: Offstage(
                    offstage: !loading,
                    child: Container(
                      constraints: const BoxConstraints.expand(),
                      color: Colors.white.withOpacity(.4),
                      child: const Center(
                        child: SizedBox(
                          width: 30.0,
                          height: 30.0,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ))
            ],
          ))
        ],
      ),
    );
  }
}
