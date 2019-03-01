import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

const PRIMARY_COLOR = Colors.teal;


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reddit Flutter Viewer',
      theme: ThemeData(
        primarySwatch: PRIMARY_COLOR,
      ),
      home: PostList(appBarTitle: 'Flutter Reddit Viewer'),
      debugShowCheckedModeBanner: false
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

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refresh,
        child: Container(
          color: Colors.grey.shade300,
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: _postList?.length ?? 0,
            itemBuilder: (_, int index) {
              return getListItem(index);
            },
          )
        )),
    );

  Widget getListItem(int index) {
    final post = _postList.elementAt(index);
    final verticalPadding = SizedBox(height: 8);
    var columnChildren = <Widget>[
      Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("${post.title}", style: Theme.of(context).textTheme.title),
              verticalPadding,
              getPostDescriptionText(post),
              verticalPadding,
              Row(
                children: <Widget>[
                  Text("${post.commentCount} comments", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${post.score} pts", style: TextStyle(fontWeight: FontWeight.bold))
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              )
            ]
          )
      )];

    // TODO: If image doesn't work out, can add bold "text", "image", or "video" based
    // TODO: on this logic and is is_video
    if (post.hasImage()) {
      columnChildren.insert(0, getImageContainer(
        Image(image: CachedNetworkImageProvider(post.imageUrl,
        errorListener: () {
          columnChildren.removeAt(0);
        }), fit: BoxFit.fitWidth),
      ));
    }

    return Card(
      child: InkWell(
        splashColor: PRIMARY_COLOR.withAlpha(70),
        onTap: () { launch(post.url); },
        child: Column(children: columnChildren),
      ),
      elevation: 2.0,
    );
  }

  Widget getImageContainer(Widget child) => ClipRRect(
    borderRadius: new BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)),
    child: SizedBox(
      width: double.infinity,
      height: 200.0,
      child: child,
    ),
  );

  Widget getPostDescriptionText(Post post) => RichText(
    text: new TextSpan(
      style: Theme.of(context).textTheme.subhead,
      children: <TextSpan>[
        TextSpan(text: "By "),
        TextSpan(text: "u/${post.author}", style: TextStyle(color: PRIMARY_COLOR)),
        TextSpan(text: " to "),
        TextSpan(text: "${post.subreddit}", style: TextStyle(color: PRIMARY_COLOR)),
        TextSpan(text: " at "),
        TextSpan(text: "${post.domain}", style: TextStyle(color: PRIMARY_COLOR))
      ],
    ),
  );

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

  Future<void> _refresh() {
    print("Refresh triggered");

    return getPostList()
      .then((postList) {
        setState(() => _postList = postList);
        print(_postList);
      })
      .timeout(const Duration(seconds: 5))
      .catchError((e) => print(e));
  }
}

Future<List<Post>> getPostList() async {
  final response = await http.get("https://www.reddit.com/hot.json");
  return Post.fromJsonToPostList(response.body);
}

class Post {
  final String title, author, subreddit, imageUrl, url, domain;
  final int score, commentCount;

  // TODO: const?
  Post(
    this.title,
    this.author,
    this.score,
    this.commentCount,
    this.subreddit,
    this.imageUrl,
    this.url,
    this.domain
  );

  bool hasImage() => imageUrl != null &&
      imageUrl.isNotEmpty &&
      imageUrl != "self" &&
      imageUrl != "default";

  // TODO: factory needed?
  factory Post.fromJson(Map<String, dynamic> postJson) {
    final postObject = postJson['data'];
    return Post(postObject['title'],
      postObject['author'],
      postObject['score'],
      postObject['num_comments'],
      postObject['subreddit_name_prefixed'],
      postObject['thumbnail'],
      postObject['url'],
      postObject['domain']);
  }

  static List<Post> fromJsonToPostList(String json) {
    final rawPostList = convert.jsonDecode(json)['data']['children'];
    final postList = List<Post>();
    rawPostList.forEach((postMap) => postList.add(Post.fromJson(postMap)));
    return postList;
  }
}