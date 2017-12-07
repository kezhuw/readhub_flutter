import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:readhub_flutter/models/news.dart';

@immutable
class ListNews extends StatelessWidget {
  const ListNews({Key key, @required this.news}) : super(key: key);

  final Iterable<WebNews> news;

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: news.map((WebNews news) {
        return new Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: new _NewsEntry(news: news),
        );
      }).toList(),
    );
  }
}

@immutable
class _NewsEntry extends StatelessWidget {
  const _NewsEntry({Key key, @required this.news}) : super(key: key);

  final WebNews news;

  Future<Null> browseNews() async {
    final String url = news.mobileUrl ?? news.url;
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: new GestureDetector(
        onTap: browseNews,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Container(
                  decoration: new ShapeDecoration(shape: new CircleBorder(side: new BorderSide(color: Colors.grey[400], width: 2.0))),
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.only(right: 8.0),
                ),
                new Expanded(child: new Text(news.title)),
              ],
            ),
            new Row(
              children: <Widget>[
                new SizedBox(width: 16.0),
                new Expanded(
                  child: new Text(news.siteName, style: Theme.of(context).textTheme.body1.copyWith(color: Colors.black54)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
