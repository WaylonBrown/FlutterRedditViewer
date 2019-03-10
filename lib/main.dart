import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

const COLOR = Colors.teal;
const TITLE = "Reddit Flutter Viewer";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {

  final GlobalKey<RefreshIndicatorState> key = GlobalKey<RefreshIndicatorState>();
  List<Post> posts;

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RefreshIndicator(
        key: key,
        onRefresh: _refresh,
        child: Container(
          color: Colors.grey.shade300,
          child: ListView.builder(
            padding: EdgeInsets.all(4.0),
            itemCount: posts?.length ?? 0,
            itemBuilder: (_, int index) {
              return getListItem(index);
            },
          )
        )),
    );

  Widget getListItem(int index) {
    final post = posts.elementAt(index);
    final vPadding = SizedBox(height: 8);
    final bold = TextStyle(fontWeight: FontWeight.bold);
    var columnChildren = <Widget>[
      Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("${post.title}", style: Theme.of(context).textTheme.title),
              vPadding,
              getDescription(post),
              vPadding,
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
      columnChildren.insert(0, getImageContainer(
        Image(image: CachedNetworkImageProvider(post.imgUrl,
        errorListener: () {
          columnChildren.removeAt(0);
        }), fit: BoxFit.fitWidth),
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

  Widget getImageContainer(Widget child) => ClipRRect(
    borderRadius: new BorderRadius.only(topLeft: Radius.circular(4.0), topRight: Radius.circular(4.0)),
    child: SizedBox(
      width: double.infinity,
      height: 250.0,
      child: child,
    ),
  );

  Widget getDescription(Post post) => RichText(
    text: new TextSpan(
      style: Theme.of(context).textTheme.subhead,
      children: <TextSpan>[
        TextSpan(text: "By "),
        TextSpan(text: "u/${post.author}", style: TextStyle(color: COLOR)),
        TextSpan(text: " to "),
        TextSpan(text: "${post.sub}", style: TextStyle(color: COLOR)),
        TextSpan(text: " at "),
        TextSpan(text: "${post.domain}", style: TextStyle(color: COLOR))
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

  Future<void> _refresh() {
    return getPostList()
      .then((postList) {
        setState(() => posts = postList);
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

  factory Post.fromJson(Map<String, dynamic> postJson) {
    final obj = postJson['data'];
    final imageUrl = getImgUrl(obj);
    return Post(obj['title'],
      obj['author'],
      obj['score'],
      obj['num_comments'],
      obj['subreddit_name_prefixed'],
      imageUrl,
      obj['url'],
      obj['domain']);
  }

  // Use a higher quality image when possible
  static String getImgUrl(Map<String, dynamic> postObject) {
    String url = postObject['url'];
    if (url != null && url.isNotEmpty && (url.endsWith('.jpg')
      || url.endsWith('.png'))) {
      return url;
    } else {
      return postObject['thumbnail'];
    }
  }

  static List<Post> fromJsonToPostList(String json) {
    final posts = convert.jsonDecode(json)['data']['children'];
    final postList = List<Post>();
    posts.forEach((postMap) => postList.add(Post.fromJson(postMap)));
    return postList;
  }
}