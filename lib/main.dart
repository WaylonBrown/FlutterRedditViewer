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
//  int _counter = 0;
  List<Post> _postList;

  void _incrementCounter() {
    print("Button clicked");

    setState(() {
//      _counter++;
    });

    var postList = getPostList().then((postList) {
      setState(() => _postList = postList);
      print("Post list: $postList");
    }).catchError((e) => print(e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Pull down to load content',
            )//,
//            Text(
//              '$_counter',
//              style: Theme.of(context).textTheme.display1,
//            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
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
  final String title, message, subreddit, imageUrl;

  // TODO: const?
  Post(this.title, this.message, this.subreddit, this.imageUrl);

  factory Post.fromJson(Map<String, dynamic> postJson) {
    final postObject = postJson['data'];
    return Post(postObject['title'], "", "", "");
  }

  static List<Post> fromJsonToPostList(String json) {
    List<dynamic> rawPostList = convert.jsonDecode(json)['data']['children'];
    List<Post> postList = List<Post>();
    rawPostList.forEach((postMap) => postList.add(Post.fromJson((postMap as Map<String, dynamic>))));
    return postList;
  }

}