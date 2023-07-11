import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './detail.dart';
import '../tool/api.dart';
import '../widgets/loading.dart';
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
  String searchKeyword = '';

  TextEditingController searchFieldController = TextEditingController();
  FocusNode focusNode = FocusNode();

  final storage = const FlutterSecureStorage();

  ScrollController listController = ScrollController();

  @override
  void initState() {
    super.initState();

    restoreSetting();
  }

  String createId(String key, int id) {
    return base64.encode(utf8.encode('$key|$id')).replaceAll(RegExp(r'={1,2}$'), '');
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
    try {
      String wd = s;
      bool prefer = false;
      if (wd.startsWith(r'$')) {
        wd = wd.substring(1);
        prefer = true;
      }
      SearchVideoList? result = await Api.getSearchVideo(apiServer, SearchQuery(wd, prefer));
      if (result != null) {
        setState(() {
          videoList = result.data;
        });
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          listController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.ease);
        });
      } else {
        throw 'Get search result failed.';
      }
    } catch (err) {
      bool? result = await showError(title: '错误', msg: '获取搜索结果失败');
      if (result != null && result) {
        await getSearch(s);
      }
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> getVideoInfo(String key, int id) async {
    setState(() {
      loading = true;
    });
    try {
      VideoInfo? videoInfo = await Api.getVideoDetail(apiServer, createId(key, id));
      if (videoInfo != null) {
        VideoSource videoSource = videoInfo.dataList.first;
        String title = videoInfo.name;
        Video video = videoSource.urls.length > 1
            ? Series(
                title, videoSource.urls.length, '{0}', videoSource.urls.map((VideoItem item) => [item.url]).toList())
            : Film(title, videoSource.urls.first.url);
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => VideoDetail(video: video)));
        }
      } else {
        throw 'failed';
      }
    } catch (err) {
      bool? result = await showError(title: '错误', msg: '获取内容详情失败');
      if (result != null && result) {
        await getVideoInfo(key, id);
      }
    }
    setState(() {
      loading = false;
    });
  }

  Future<bool?> showError({required String title, required String msg}) async {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text(title),
              contentPadding: const EdgeInsets.symmetric(horizontal: 5),
              content: SizedBox(
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text(msg),
                    ),
                    ButtonBar(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                          child: const Text('重试'),
                        ),
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消'))
                      ],
                    )
                  ],
                ),
              ));
        });
  }

  Future<void> openLink(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> showSetting() async {
    List<String> servers = Api.servers.map((uri) => Uri.parse(uri).host.replaceFirst(RegExp(r'[\w-]+\.'), '')).toList();
    int? serverId = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('选择服务器'),
            titleTextStyle: const TextStyle(fontSize: 17.0, color: Colors.black),
            contentPadding: const EdgeInsets.all(10.0),
            children: [
              const SizedBox(
                height: 10.0,
              ),
              ...servers
                  .asMap()
                  .keys
                  .map((int index) => TextButton(
                      onPressed: () => Navigator.pop(context, index),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Radio<int>(
                              value: index,
                              groupValue: apiServer,
                              onChanged: (int? value) => Navigator.pop(context, index)),
                          Text(servers[index],
                              style:
                                  TextStyle(color: apiServer == index ? Theme.of(context).primaryColor : Colors.black))
                        ],
                      )))
                  .toList(),
            ],
          );
        });
    if (serverId != null) {
      apiServer = serverId;
      storage.write(key: 'server_id', value: serverId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        actions: [IconButton(onPressed: showSetting, icon: const Icon(Icons.settings))],
      ),
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(5.0)),
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 25,
                              child: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              autofocus: true,
                              focusNode: focusNode,
                              controller: searchFieldController,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: '输入关键词搜索'),
                              onChanged: (String text) {
                                setState(() {
                                  searchKeyword = text;
                                });
                              },
                              onSubmitted: (String text) {
                                if (text.trim().isNotEmpty) {
                                  getSearch(text);
                                }
                              },
                            ),
                          )
                        ],
                      ),
                      Positioned(
                          right: 10,
                          top: 13,
                          child: AnimatedScale(
                            scale: searchKeyword.isNotEmpty ? 1 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: InkWell(
                              child: const Icon(Icons.close, color: Colors.grey),
                              onTap: () {
                                searchFieldController.text = '';
                                if (!focusNode.hasFocus) {
                                  focusNode.requestFocus();
                                }
                                setState(() {
                                  searchKeyword = '';
                                });
                              },
                            ),
                          ))
                    ],
                  ),
                ),
              ),
              Expanded(
                  child: ListView(
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(videoList[sourceIndex].name),
                                    RatingBarIndicator(
                                      rating: videoList[sourceIndex].rating,
                                      itemBuilder: (context, index) =>
                                          Icon(Icons.star, color: Theme.of(context).primaryColor),
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
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: TextButton(
                                            style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                            onPressed: () => getVideoInfo(videoList[sourceIndex].key, video.id),
                                            child: Container(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(.4),
                                                  borderRadius: BorderRadius.circular(5.0)),
                                              clipBehavior: Clip.hardEdge,
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        SizedBox(
                                                          width: 105,
                                                          child: Poster(
                                                            src: Api.getVideoPoster(apiServer,
                                                                createId(videoList[sourceIndex].key, video.id)),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            height: 105 * 1.5,
                                                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  video.name,
                                                                  style: const TextStyle(fontSize: 20),
                                                                  overflow: TextOverflow.ellipsis,
                                                                  softWrap: true,
                                                                  maxLines: 2,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Chip(
                                                                      label: Text(video.type,
                                                                          style: const TextStyle(fontSize: 14)),
                                                                      backgroundColor:
                                                                          Theme.of(context).secondaryHeaderColor,
                                                                    ),
                                                                    Container(
                                                                      margin: const EdgeInsets.only(left: 8.0),
                                                                      child: Text(video.note,
                                                                          style: TextStyle(
                                                                              fontSize: 14, color: Colors.grey[500])),
                                                                    )
                                                                  ],
                                                                ),
                                                                Expanded(
                                                                  child: Container(
                                                                      alignment: Alignment.bottomLeft,
                                                                      child: TextButton(
                                                                        onPressed: () async {
                                                                          await openLink(Api.getDetailUrl(
                                                                              apiServer,
                                                                              createId(videoList[sourceIndex].key,
                                                                                  video.id)));
                                                                        },
                                                                        style: TextButton.styleFrom(
                                                                            backgroundColor:
                                                                                Theme.of(context).primaryColor,
                                                                            foregroundColor: Colors.white),
                                                                        child: const Text('网页播放'),
                                                                      )),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(Icons.arrow_forward_ios, size: 16.0)
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
              ))
            ],
          ),
          Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Offstage(
                offstage: !loading,
                child: const Loading(),
              ))
        ],
      ),
    );
  }
}
