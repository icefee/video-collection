import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './detail.dart';
import '../tool/api.dart';
import '../widgets/poster.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  int apiServer = 0;
  List<SearchVideo> videoList = [];
  bool loading = false;

  final storage = const FlutterSecureStorage();

  ScrollController listController = ScrollController();

  @override
  void initState() {
    super.initState();

    restoreSetting();
  }

  Future<void> restoreSetting() async {
    String? value = await storage.read(key: 'server_id');
    if (value != null) {
      setState(() {
        apiServer = int.tryParse(value) ?? 0;
      });
    }
  }

  Future<void> getSearch(String s) async {
    setState(() {
      loading = true;
    });
    removeSnackBar();
    try {
      String wd = s;
      bool prefer = false;
      if (wd.startsWith(r'$')) {
        wd = wd.substring(1);
        prefer = true;
      }
      SearchVideoList result =
          await Api.getSearchVideo(apiServer, SearchQuery(wd, prefer));
      if (mounted) {
        setState(() {
          loading = false;
          videoList = result.data;
        });
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          listController.animateTo(0,
              duration: const Duration(milliseconds: 200), curve: Curves.ease);
        });
      }
    } catch (err) {
      showSnackBar('获取搜索结果失败', () => getSearch(s));
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getVideoInfo(String key, int id) async {
    setState(() {
      loading = true;
    });
    removeSnackBar();
    try {
      VideoInfo? videoInfo = await Api.getVideoDetail(apiServer, key, id);
      if (videoInfo != null) {
        VideoSource videoSource = videoInfo.dataList.first;
        String title = videoInfo.name;
        Video video = videoSource.urls.length > 1
            ? Series(title, videoSource.urls.length, '{0}',
                videoSource.urls.map((VideoItem item) => [item.url]).toList())
            : Film(title, videoSource.urls.first.url);
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => VideoDetail(video: video)));
        }
      } else {
        throw 'failed';
      }
    } catch (err) {
      showSnackBar('获取内容详情失败', () => getVideoInfo(key, id));
    }
    setState(() {
      loading = false;
    });
  }

  void showSnackBar(String message, VoidCallback onRetry) {
    removeSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: '重试',
        onPressed: onRetry,
        textColor: Colors.white,
      ),
    ));
  }

  void removeSnackBar() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
  }

  Future<void> openLink(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> generateDataUrl(String key, int id) async {
    removeSnackBar();
    setState(() {
      loading = true;
    });
    try {
      VideoInfo? videoInfo = await Api.getVideoDetail(apiServer, key, id);
      if (null != videoInfo && mounted) {
        Map infoMap = videoInfo.toMap();
        String json = jsonEncode({'api': key, 'id': id, 'video': infoMap});
        String dataUrl = Uri.encodeComponent(base64.encode(utf8.encode(json)));
        openLink('${Api.staticBaseUrl}/video?d=$dataUrl');
      } else {
        throw 'failed';
      }
    } catch (err) {
      showSnackBar('获取内容详情失败', () => generateDataUrl(key, id));
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> showSetting() async {
    int? serverId = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('选择服务器'),
            contentPadding: const EdgeInsets.all(10.0),
            children: [
              const SizedBox(
                height: 10.0,
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context, 0),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio<int>(
                          value: 0,
                          groupValue: apiServer,
                          onChanged: (int? value) => Navigator.pop(context, 0)),
                      const Text('netlify.app')
                    ],
                  )),
              TextButton(
                  onPressed: () => Navigator.pop(context, 1),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Radio<int>(
                          value: 1,
                          groupValue: apiServer,
                          onChanged: (int? value) => Navigator.pop(context, 0)),
                      const Text('onrender.com')
                    ],
                  ))
            ],
          );
        });
    if (serverId != null) {
      setState(() {
        apiServer = serverId;
      });
      storage.write(key: 'server_id', value: serverId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        actions: [
          IconButton(onPressed: showSetting, icon: const Icon(Icons.settings))
        ],
      ),
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
                controller: listController,
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
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(videoList[sourceIndex].name),
                                    RatingBarIndicator(
                                      rating: videoList[sourceIndex].rating,
                                      itemBuilder: (context, index) => Icon(
                                          Icons.star,
                                          color:
                                              Theme.of(context).primaryColor),
                                      itemCount: 5,
                                      itemSize: 16.0,
                                      direction: Axis.horizontal,
                                    )
                                  ],
                                ),
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
                                                  Expanded(
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(
                                                          width: 105,
                                                          child: Poster(
                                                              serverId:
                                                                  apiServer,
                                                              api: videoList[
                                                                      sourceIndex]
                                                                  .key,
                                                              id: video.id),
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            height: 105 * 1.5,
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
                                                                Text(
                                                                  video.name,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          20),
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  softWrap:
                                                                      true,
                                                                  maxLines: 2,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Chip(
                                                                      label: Text(
                                                                          video
                                                                              .type,
                                                                          style:
                                                                              const TextStyle(fontSize: 14)),
                                                                      backgroundColor:
                                                                          Theme.of(context)
                                                                              .secondaryHeaderColor,
                                                                    ),
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              8.0),
                                                                      child: Text(
                                                                          video
                                                                              .note,
                                                                          style: TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.grey[500])),
                                                                    )
                                                                  ],
                                                                ),
                                                                Expanded(
                                                                  child:
                                                                      Container(
                                                                          alignment: Alignment
                                                                              .bottomLeft,
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              TextButton(
                                                                                onPressed: () async {
                                                                                  await openLink('${Api.getServer(apiServer)}/video/${videoList[sourceIndex].key}/${video.id}');
                                                                                },
                                                                                style: TextButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                                                                                child: const Text('网页播放'),
                                                                              ),
                                                                              const SizedBox(
                                                                                width: 10,
                                                                              ),
                                                                              TextButton(
                                                                                onPressed: () => generateDataUrl(videoList[sourceIndex].key, video.id),
                                                                                style: TextButton.styleFrom(side: BorderSide(width: 1.0, color: Theme.of(context).primaryColor)),
                                                                                child: const Text('数据链接'),
                                                                              ),
                                                                            ],
                                                                          )),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
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
                      alignment: Alignment.center,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                            color: Colors.black.withAlpha(200),
                            borderRadius: BorderRadius.circular(4.0)),
                        padding: const EdgeInsets.all(16.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
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
