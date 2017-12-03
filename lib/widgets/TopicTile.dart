import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:readhub_flutter/store/topic.dart';
import 'package:readhub_flutter/store/news.dart';
import 'package:readhub_flutter/widgets/ListNews.dart';
import 'package:readhub_flutter/widgets/pages/TopicPage.dart';
import 'package:readhub_flutter/widgets/ElapsedTimeText.dart';

@immutable
class TopicTile extends StatefulWidget {
  const TopicTile({
    Key key,
    this.topic,
    this.maxNews,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
  }) : super(key: key);

  final Topic topic;
  final int maxNews;
  final EdgeInsets padding;

  @override
  _TopicTileState createState() => new _TopicTileState();
}

class _TopicTileState extends State<TopicTile> {
  Object openStateKey;
  bool expanded = false;
  Widget tickingTitle;
  PageStorageBucket bucket;

  void toggle() {
    setState(() {
      expanded = !expanded;
    });
    PageStorage.of(context).writeState(context, expanded, identifier: openStateKey);
  }

  void setTickingTitle() {
    TextTheme textTheme = Theme.of(context).textTheme;
    tickingTitle = new ElapsedTimeTitle(
      title: widget.topic.title,
      style: textTheme.title,
      time: widget.topic.publishDate,
      timeStyle: textTheme.subhead.copyWith(color: Colors.black54),
    );
  }

  @override
  void initState() {
    super.initState();
    openStateKey = new ValueKey('topics/${widget.topic.id}/expanded');
    expanded = PageStorage.of(context).readState(context, identifier: openStateKey) ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setTickingTitle();
  }

  @override
  void didUpdateWidget(TopicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic == oldWidget.topic) {
      return;
    }
    setTickingTitle();
  }

  void enterTopic() {
    Navigator.of(context).push(new MaterialPageRoute(
      builder: (BuildContext context) {
        return new TopicPage(topicId: widget.topic.id);
      }
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      List<WebNews> nonDuplicatedNews = widget.topic.nonDuplicatedNews;
      if (widget.maxNews != null) {
        nonDuplicatedNews = nonDuplicatedNews.take(widget.maxNews).toList();
      }
      return new Material(
        type: MaterialType.card,
        elevation: 2.0,
        child: new Padding(
          padding: widget.padding.copyWith(bottom: 0.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              new GestureDetector(
                onTap: toggle,
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    tickingTitle,
                    new Container(
                      margin: const EdgeInsets.symmetric(vertical: 12.0),
                      child: new Text(widget.topic.summary, style: const TextStyle(height: 1.8)),
                    ),
                  ],
                ),
              ),
              new ListNews(news: nonDuplicatedNews),
              new GestureDetector(
                onTap: enterTopic,
                behavior: HitTestBehavior.opaque,
                child: new Container(
                  decoration: new BoxDecoration(
                    border: new Border(top: new BorderSide(color: Theme.of(context).dividerColor, width: 0.0)),
                  ),
                  margin: const EdgeInsets.only(top: 4.0),
                  padding: new EdgeInsets.symmetric(vertical: widget.padding.bottom),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Text('查看话题'),
                      const Icon(Icons.arrow_right, color: Colors.black54),
                    ],
                  ),

                ),
              ),
            ],
          ),
        )
      );
    }
    return new GestureDetector(
      onTap: toggle,
      child: new Padding(
        padding: widget.padding,
        child: tickingTitle,
      ),
    );
  }
}
