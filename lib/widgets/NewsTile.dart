import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:readhub_flutter/store/news.dart';

import 'package:readhub_flutter/widgets/ElapsedTimeText.dart';

@immutable
class NewsTile extends StatelessWidget {
  NewsTile({Key key, this.news, this.maxLines}) : storageKey = new ValueKey('/news/${news.id}/browsed'), super(key: key);

  final WebNews news;
  final int maxLines;
  final Object storageKey;

  Future<Null> browseNews(BuildContext context) async {
    final String url = news.mobileUrl ?? news.url;
    PageStorage.of(context).writeState(context, true, identifier: storageKey);
    (context as Element).markNeedsBuild();
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  String _buildNewsSource(String siteName, String authorName) {
    final List<String> source = <String>[siteName];
    if (authorName != null && authorName.isNotEmpty) {
      source.add(authorName);
    }
    return source.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = Theme.of(context).textTheme.title;
    final TextStyle bodyStyle = Theme.of(context).textTheme.body1.copyWith(height: 1.5);
    final bool browsed = PageStorage.of(context).readState(context, identifier: storageKey) ?? false;
    if (browsed) {
      titleStyle = bodyStyle.copyWith(fontSize: titleStyle.fontSize, fontWeight: titleStyle.fontWeight);
    }

    return new InkWell(
      onTap: () {
        browseNews(context);
      },
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Text(news.title, style: titleStyle),
          new Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: new Text(news.summary?.replaceAll(new RegExp('\n'), ' ') ?? '', maxLines: maxLines, style: bodyStyle)
          ),
          new ElapsedTimeTitle(title: _buildNewsSource(news.siteName, news.authorName), style: bodyStyle, time: news.publishDate),
        ],
      ),
    );
  }
}
