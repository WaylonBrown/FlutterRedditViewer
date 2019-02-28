import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

const PRIMARY_COLOR = Colors.teal;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: PRIMARY_COLOR,
      ),
      home: PostList(appBarTitle: 'Flutter Reddit Viewer'),
    );
  }
}

class PostList extends StatefulWidget {
  final String appBarTitle;

  PostList({Key key, this.appBarTitle}) : super(key: key);

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
//          itemExtent: 20.0,
          itemCount: _postList?.length ?? 0,
          itemBuilder: (_, int index) {
            return Card(
                child: InkWell(
                  splashColor: PRIMARY_COLOR.withAlpha(70),
                  onTap: () { /* ... */ },
                  child: Text("${_postList.elementAt(index).title}"),
                )
            );
          },
        )),
    );
  }

  @override
  void initState() {
    super.initState();
    // Trigger an initial refresh
    WidgetsBinding.instance.addPostFrameCallback( (_) {
      if (_postList == null || _postList.isEmpty) {
        _refreshIndicatorKey.currentState.show();
      }
    });
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