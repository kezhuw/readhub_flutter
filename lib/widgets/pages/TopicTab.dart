import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/topic.dart';
import 'package:readhub_flutter/store/store.dart';
import 'package:readhub_flutter/widgets/TopicTile.dart';
import 'package:readhub_flutter/widgets/FetchProgressPlaceholder.dart';

class _TopicTabModel {
  _TopicTabModel({this.latestTopics, this.fetchProgress});

  final List<Topic> latestTopics;
  final FetchProgress fetchProgress;
}

_TopicTabModel _fromStore(Store<AppState> store) {
  AppState state = store.state;
  return new _TopicTabModel(
    latestTopics: state.topics.latestTopics,
    fetchProgress: state.topics.moreTopicFetchProgress,
  );
}

final int _kMaxDisplayTopicNews = 3;

@immutable
class TopicTab extends StatelessWidget {

  void _fetchMoreTopic(BuildContext context) {
    Store<AppState> store = new StoreProvider.of(context).store;
    store.dispatch(fetchMoreTopics);
  }

  Widget _buildItem(BuildContext context, _TopicTabModel model, int index) {
    if (index < model.latestTopics.length) {
      Topic topic = model.latestTopics[index];
      return new TopicTile(
        key: new ObjectKey(topic),
        topic: topic,
        maxNews: _kMaxDisplayTopicNews,
      );
    }
    if (index > model.latestTopics.length) {
      return null;
    }
    return new FetchProgressPlaceholder(progress: model.fetchProgress, action: () { _fetchMoreTopic(context); });
  }

  @override
  Widget build(BuildContext context) {
    BorderSide borderSide = new BorderSide(color: Theme.of(context).dividerColor, width: 0.0);
    Store<AppState> store = new StoreProvider<AppState>.of(context).store;
    return new StoreConnector(
      builder: (BuildContext context, _TopicTabModel model) {
        return new Container(
          color: Theme.of(context).canvasColor,
          child: new RefreshIndicator(
            onRefresh: () async {
              await fetchNewerTopics(store);
            },
            child: new ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                Widget item = _buildItem(context, model, index);
                if (item == null) {
                  return null;
                }
                BorderSide bottom = BorderSide.none, top = BorderSide.none;
                if (index < model.latestTopics.length-1) {
                  bottom = borderSide;
                } else if (index == model.latestTopics.length && index != 0) {
                  top = borderSide;
                }
                return new DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: new BoxDecoration(
                    border: new Border(top: top, bottom: bottom),
                  ),
                  child: item,
                );
              }
            ),
          ),
        );
      },
      converter: _fromStore,
    );
  }
}
