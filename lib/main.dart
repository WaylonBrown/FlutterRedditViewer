import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PostList(appBarTitle: 'Flutter Demo Home Page'),
    );
  }
}

class PostList extends StatefulWidget {
  const PostList({Key key, this.appBarTitle}) : super(key: key);

  final String appBarTitle;

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  List<Post> _postList;

  Future<void> _refresh() {
    print("Button clicked");

    return getPostList().then((postList) {
      setState(() => _postList = postList);
      print(_postList);
    }).catchError((e) => print(e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: ListView.builder(
          padding: EdgeInsets.all(8.0),
          itemExtent: 20.0,
          itemCount: _postList?.length ?? 0,
          itemBuilder: (BuildContext context, int index) {
            return Text("${_postList.elementAt(index).title}");
          },
        )),
    );
  }
}

Future<List<Post>> getPostList() async {
  try {
    final response = await http.get("https://www.reddit.com/hot.json");
    return Post.fromJsonToPostList(response.body);
  } catch (e) {
    print(e);
    return null;
  }
}

class Post {
  final String title, subreddit, imageUrl, url;

  // TODO: const?
  Post(this.title, this.subreddit, this.imageUrl, this.url);

  // TODO: factory needed?
  factory Post.fromJson(Map<String, dynamic> postJson) {
    final postObject = postJson['data'];
    return Post(postObject['title'],
      postObject['subreddit_name_prefixed'],
      postObject['thumbnail'],
      postObject['url']);
  }

  static List<Post> fromJsonToPostList(String json) {
    final rawPostList = convert.jsonDecode(json)['data']['children'];
    final postList = List<Post>();
    rawPostList.forEach((postMap) => postList.add(Post.fromJson(postMap)));
    return postList;
  }
}