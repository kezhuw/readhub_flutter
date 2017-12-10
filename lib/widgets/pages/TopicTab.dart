import 'package:meta/meta.dart';

import 'package:quiver/core.dart';
import 'package:quiver/collection.dart';

import 'package:flutter/material.dart';

import 'package:storey/storey.dart';
import 'package:flutter_storey/flutter_storey.dart';

import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/topic.dart';
import 'package:readhub_flutter/store/topic/store.dart';
import 'package:readhub_flutter/widgets/TopicTile.dart';
import 'package:readhub_flutter/widgets/FetchProgressPlaceholder.dart';

class _TopicTabModel {
  _TopicTabModel({this.latestTopics, this.fetchProgress});

  final List<Topic> latestTopics;
  final FetchProgress fetchProgress;

  @override
  bool operator ==(dynamic other) {
    if (other is! _TopicTabModel) {
      return false;
    }
    _TopicTabModel typedOther = other;
    return listsEqual(latestTopics, typedOther.latestTopics) && fetchProgress == typedOther.fetchProgress;
  }

  @override
  int get hashCode => hash2(hashObjects(latestTopics), fetchProgress);

  static _TopicTabModel fromStore(Store<TopicState> store) {
    TopicState state = store.state;
    return new _TopicTabModel(
      latestTopics: state.latestTopics,
      fetchProgress: state.moreTopicFetchProgress,
    );
  }
}

final int _kMaxDisplayTopicNews = 3;

@immutable
class TopicTab extends StatelessWidget {

  void _fetchMoreTopic(BuildContext context) {
    Store<TopicState> store = StoreProvider.of(context);
    store.dispatch(new AsyncThunkAction<TopicState, Null>(fetchMoreTopics));
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
    return new StoreConnector(
      converter: _TopicTabModel.fromStore,
      path: const <String>['topics'],
      builder: (BuildContext context, _TopicTabModel model) {
        return new Container(
          color: Theme.of(context).canvasColor,
          child: new RefreshIndicator(
            onRefresh: () {
              Store<TopicState> store = StoreProvider.of(context);
              AsyncThunkAction<TopicState, Null> action = new AsyncThunkAction<TopicState, Null>(fetchNewerTopics);
              store.dispatch(action);
              return action.result;
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
    );
  }
}
