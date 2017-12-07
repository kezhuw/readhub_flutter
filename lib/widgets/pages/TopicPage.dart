import 'package:meta/meta.dart';

import 'package:quiver/core.dart';

import 'package:flutter/material.dart';

import 'package:storey/storey.dart';
import 'package:flutter_storey/flutter_storey.dart';

import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/topic.dart';
import 'package:readhub_flutter/store/store.dart';
import 'package:readhub_flutter/widgets/ListNews.dart';
import 'package:readhub_flutter/widgets/FetchProgressPlaceholder.dart';

class _TopicModel {
  const _TopicModel({this.topicId, this.topic, this.fetchProgress});

  final String topicId;
  final Topic topic;
  final FetchProgress fetchProgress;

  @override
  bool operator ==(dynamic other) {
    if (other is! _TopicModel) {
      return false;
    }
    _TopicModel typedOther = other;
    return topicId == typedOther.topicId && topic == typedOther.topic && fetchProgress == typedOther.fetchProgress;
  }

  @override
  int get hashCode => hash3(topicId, topic, fetchProgress);

  static _TopicModel fromStore(Store<TopicState> store, String topicId) {
    TopicState state = store.state;
    return new _TopicModel(topicId: topicId, topic: state.getTopic(topicId), fetchProgress: state.getTopicFetchProgress(topicId));
  }
}

@immutable
class _Topic extends StatelessWidget {
  const _Topic({Key key, @required this.model}) : super(key: key);

  final _TopicModel model;

  Color _timelineColor(BuildContext context) {
    return Theme.of(context).canvasColor;
  }

  Widget _buildTopicTrace(BuildContext context, TopicTrace trace) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new SizedBox(
            width: 48.0,
            child: new Center(child: new Text('${trace.createAt.month}.${trace.createAt.day}')),
          ),
          const SizedBox(width: 16.0),
          new Expanded(
            child: new GestureDetector(
              child: new Text(trace.title),
              onTap: () {
                Navigator.of(context).push(new MaterialPageRoute(
                  builder: (BuildContext context) {
                    return new TopicPage(topicId: trace.id);
                  }
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    assert(model.topic != null);
    Widget timeline;
    if (model.topic is! TracedTopic) {
      timeline = new FetchProgressPlaceholder(progress: model.fetchProgress, action: () { _fetchTopic(context); });
    } else {
      final TracedTopic topic = model.topic as TracedTopic;
      if (topic.timeline == null || topic.timeline.isEmpty) {
        timeline = const Center(child: const Text('无相关事件'));
      }
      Iterable<Widget> traces = topic.timeline.map((TopicTrace trace) => _buildTopicTrace(context, trace));
      timeline = new Column(
        children: ListTile.divideTiles(tiles: traces, context: context).toList(),
      );
    }

    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 16.0),
            child: new Text('相关事件'),
          ),
          new Container(
            decoration: new BoxDecoration(
              border: new Border(
                top: new BorderSide(width: 0.0, color: Theme.of(context).dividerColor),
                bottom: new BorderSide(width: 0.0, color: Theme.of(context).dividerColor),
              ),
              color: _timelineColor(context),
            ),
            child: timeline,
          )
        ],
      ),
    );
  }

  void _fetchTopic(BuildContext context) {
    Store<TopicState> store = StoreProvider.of(context, debugTypeMatcher: const TypeMatcher<TopicState>());
    store.dispatch(new ThunkAction<TopicState, Null>(fetchTopic(model.topicId)));
  }

  Widget _buildBody(BuildContext context) {
    final Topic topic = model.topic;
    if (topic == null) {
      return new FetchProgressPlaceholder(progress: model.fetchProgress, action: () { _fetchTopic(context); });
    }
    TextTheme textTheme = Theme.of(context).textTheme;
    Widget timeline = _buildTimeline(context);
    return new Scrollbar(
      child: new SingleChildScrollView(
        child: new Container(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Padding(
                padding: new EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: new Column(
                  children: <Widget>[
                    new Text(topic.title, style: textTheme.title.copyWith(fontSize: textTheme.display1.fontSize)),
                    new SizedBox(height: 16.0, width: double.infinity),
                    new Text(topic.summary, style: textTheme.body1.copyWith(height: 1.8)),
                    new ListNews(news: topic.nonDuplicatedNews),
                  ],
                ),
              ),
              timeline,
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            new SliverAppBar(
              title: new Image.network('https://cdn.readhub.me/static/assets/png/readhub_logo_m@2x.78b35cd0.png'),
            ),
          ];
        },
        body: _buildBody(context),
      ),
    );
  }
}

@immutable
class TopicPage extends StatelessWidget {
  const TopicPage({Key key, this.topicId}) : super(key: key);

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return new StoreConnector<TopicState, _TopicModel>(
      converter: (Store<TopicState> store) {
        return _TopicModel.fromStore(store, topicId);
      },
      path: const [const ValueKey<String>('topics')],
      equals: identical,
      builder: (BuildContext context, _TopicModel model) {
        return new _Topic(model: model);
      },
    );
  }
}
