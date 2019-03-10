import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

const COLOR = Colors.teal;
const TITLE = "Reddit Flutter Viewer";

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      title: TITLE,
      theme: ThemeData(
        primarySwatch: COLOR
      ),
      home: PostList(title: TITLE)
    );
  }
}

class PostList extends StatefulWidget {
  final String title;

  PostList({Key key, this.title}) : super(key: key);

  @override
  PostListState createState() => PostListState();
}

class PostListState extends State<PostList> {
  final GlobalKey<RefreshIndicatorState> key = GlobalKey<RefreshIndicatorState>();
  List<Post> posts;

  @override
  Widget build(BuildContext c) =>
    Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        key: key,
        onRefresh: refresh,
        child: Container(
          color: Colors.grey.shade300,
          child: ListView.builder(
            padding: EdgeInsets.all(4.0),
            itemCount: posts?.length ?? 0,
            itemBuilder: (_, int i) {
              return getItem(i);
            },
          )
        )),
    );

  Widget getItem(int i) {
    final post = posts.elementAt(i);
    final vPad = SizedBox(height: 8);
    final bold = TextStyle(fontWeight: FontWeight.bold);
    var columnChildren = <Widget>[
      Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("${post.title}", style: Theme.of(context).textTheme.title),
              vPad,
              getDesc(post),
              vPad,
              Row(
                children: <Widget>[
                  Text("${post.comCount} comments", style: bold),
                  Text("${post.score} pts", style: bold)
                ],
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              )
            ]
          )
      )];

    if (post.hasImage()) {
      columnChildren.insert(0, getImgContainer(
        Image(image: CachedNetworkImageProvider(post.imgUrl), fit: BoxFit.fitWidth)
      ));
    }

    return Column(
      children: <Widget>[
        Card(
          child: InkWell(
            splashColor: COLOR.withAlpha(70),
            onTap: () { launch(post.url); },
            child: Column(children: columnChildren),
          ),
          elevation: 2.0,
        ),
        SizedBox(height: 2)
      ],
    );
  }

  Widget getImgContainer(Widget child) => ClipRRect(
    borderRadius: new BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)),
    child: SizedBox(
      width: double.infinity,
      height: 250.0,
      child: child,
    ),
  );

  Widget getDesc(Post p) => RichText(
    text: new TextSpan(
      style: Theme.of(context).textTheme.subhead,
      children: <TextSpan>[
        TextSpan(text: "By "),
        TextSpan(text: "u/${p.author}", style: TextStyle(color: COLOR)),
        TextSpan(text: " to "),
        TextSpan(text: "${p.sub}", style: TextStyle(color: COLOR)),
        TextSpan(text: " at "),
        TextSpan(text: "${p.domain}", style: TextStyle(color: COLOR))
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    // Initial refresh
    WidgetsBinding.instance.addPostFrameCallback( (_) {
      if (posts == null || posts.isEmpty) {
        key.currentState.show();
      }
    });
  }

  Future<void> refresh() {
    return getPosts()
      .then((p) {
        setState(() => posts = p);
      })
      .timeout(const Duration(seconds: 5))
      .catchError((e) => print(e));
  }
}

Future<List<Post>> getPosts() async {
  final response = await http.get("https://www.reddit.com/hot.json");
  return Post.fromJsonToPostList(response.body);
}

class Post {
  final String title, author, sub, imgUrl, url, domain;
  final int score, comCount;

  const Post(
    this.title,
    this.author,
    this.score,
    this.comCount,
    this.sub,
    this.imgUrl,
    this.url,
    this.domain
  );

  bool hasImage() => imgUrl != null &&
      imgUrl.isNotEmpty &&
      imgUrl != "self" &&
      imgUrl != "default";

  factory Post.fromJson(Map<String, dynamic> json) {
    final obj = json['data'];
    return Post(obj['title'],
      obj['author'],
      obj['score'],
      obj['num_comments'],
      obj['subreddit_name_prefixed'],
      obj['thumbnail'],
      obj['url'],
      obj['domain']);
  }

  static List<Post> fromJsonToPostList(String json) {
    final posts = convert.jsonDecode(json)['data']['children'];
    final list = List<Post>();
    posts.forEach((postMap) => list.add(Post.fromJson(postMap)));
    return list;
  }
}