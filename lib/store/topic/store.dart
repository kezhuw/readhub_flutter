import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'package:storey/storey.dart';

import 'package:readhub_flutter/configs/configs.dart';
import 'package:readhub_flutter/envs/api.dart';
import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/topic.dart';

class TopicState {
  final Map<String, Topic> _topics = new Map<String, Topic>();
  final Map<String, dynamic> _fetchingTopics = new Map<String, dynamic>();

  Topic getTopic(String topicId) => _topics[topicId];

  FetchProgress getTopicFetchProgress(String topicId) {
    dynamic progress = _fetchingTopics[topicId];
    if (progress == null) {
      return FetchProgress.none;
    }
    if (progress is Future) {
      return FetchProgress.busy;
    }
    return new FetchProgress.error(progress);
  }

  Future<Topic> _fetchTopic(String topicId) async {
    final Response response = await api.get('/topic/$topicId');
    Map<String, dynamic> result = JSON.decode(response.body);
    return new Topic.fromJsonObject(result, emptyTimeline: const []);
  }

  void requestTopicFetch(String topicId) {
    Topic topic = _topics[topicId];
    if (topic != null && topic.whole) {
      return;
    }
    dynamic progress = _fetchingTopics[topicId];
    if (progress == null || progress is! Future) {
      _fetchingTopics[topicId] = _fetchTopic(topicId).timeout(kNetworkTimeoutDuration);
    }
  }

  Future<Topic> waitTopicFetch(String topicId) async {
    Topic topic = _topics[topicId];
    if (topic != null && topic.whole) {
      return new Future<Topic>.value(topic);
    }
    dynamic progress = _fetchingTopics[topicId];
    assert(progress != null);
    if (progress is Future) {
      return progress as Future<Topic>;
    }
    return new Future<Topic>.error(progress);
  }

  void completeTopicFetch({String topicId, Topic topic, dynamic error}) {
    assert(topic == null || error == null);
    if (error != null) {
      assert(error is! Future);
      _fetchingTopics[topicId] = error;
      return;
    }
    assert(topic.whole);
    _topics[topicId] = topic;
    _fetchingTopics.remove(topicId);
  }


  Future<List<Topic>> _newerTopicsFuture;
  String get _newerTopicsCursor => _topics[_latestTopics.first].order;

  Future<Iterable<String>> _fetchNewerTopicIds() async {
    assert(_latestTopics.isNotEmpty);
    final String latestCursor = _newerTopicsCursor;
    final Response response = await api.get('/topic/newCount?latestCursor=$latestCursor');
    Map<String, dynamic> result = JSON.decode(response.body);
    Iterable<String> topicIds = (result['data'] as List<Map<String, dynamic>>).map((Map<String, dynamic> json) => json['id'] as String);
    return topicIds;
  }

  Future<List<Topic>> _fetchNewerTopics() async {
    Iterable<String> topicIds = await _fetchNewerTopicIds();
    Iterable<Future<Topic>> futures = topicIds.map(_fetchTopic);
    Stream<Topic> stream = new Stream<Topic>.fromFutures(futures);
    return await stream.toList();
  }

  String requestNewerTopics() {
    if (_newerTopicsFuture != null) {
      return null;
    }
    if (_latestTopics.isEmpty) {
      return null;
    }
    _newerTopicsFuture = _fetchNewerTopics().timeout(kNetworkTimeoutDuration);
    return _newerTopicsCursor;
  }

  void completeNewerTopics({String cursor, List<Topic> topics}) {
    if  (cursor == null || _latestTopics.isEmpty || cursor != _newerTopicsCursor) {
      return;
    }
    if (topics.isNotEmpty) {
      topics.sort((Topic a, Topic b) => int.parse(b.order) - int.parse(a.order));
      Iterable<String> topicIds = topics.map((Topic topic) => topic.id);
      _topics.addAll(new Map<String, Topic>.fromIterables(topicIds, topics));
      _latestTopics.insertAll(0, topicIds);
    }
    _newerTopicsFuture = null;
  }

  Future<List<Topic>> waitNewerTopics() async {
    return _newerTopicsFuture ?? new Future<List<Topic>>.value(const <Topic>[]);
  }


  final List<String> _latestTopics = [];
  dynamic _moreTopicsFetchProgress;

  List<Topic> get latestTopics => _latestTopics.map((String id) => _topics[id]).toList(growable: false);

  FetchProgress get moreTopicFetchProgress {
    if (_moreTopicsFetchProgress == null) {
      return FetchProgress.none;
    }
    if (identical(_moreTopicsFetchProgress, FetchProgress.completed)) {
      return FetchProgress.completed;
    }
    if (_moreTopicsFetchProgress is Future) {
      return FetchProgress.busy;
    }
    return new FetchProgress.error(_moreTopicsFetchProgress);
  }

  String _moreTopicsCursor() {
    return _latestTopics.isEmpty ? "" : _topics[_latestTopics.last].order;
  }

  Future<List<Topic>> _fetchMoreTopics() async {
    const int pageSize = 10;
    final String lastCursor = _moreTopicsCursor();
    final Response response = await api.get('/topic?lastCursor=$lastCursor&pageSize=$pageSize');
    Map result = JSON.decode(response.body);
    final List<Topic> topics = (result["data"] as List<Map<String, dynamic>>).map((m) => new Topic.fromJsonObject(m)).toList();
    return topics;
  }

  String requestMoreTopics() {
    if (identical(_moreTopicsFetchProgress, FetchProgress.completed)) {
      return null;
    }
    if (_moreTopicsFetchProgress is Future) {
      return null;
    }
    _moreTopicsFetchProgress = _fetchMoreTopics().timeout(kNetworkTimeoutDuration);
    return _latestTopics.isEmpty ? "" : _topics[_latestTopics.last].order;
  }

  Future<Iterable<Topic>> waitMoreTopic() async {
    assert(_moreTopicsFetchProgress != null);
    if (identical(_moreTopicsFetchProgress, FetchProgress.completed)) {
      return new Future<Iterable<Topic>>.value(const Iterable<Topic>.empty());
    }
    if (_moreTopicsFetchProgress is! Future) {
      return new Future<Iterable<Topic>>.error(_moreTopicsFetchProgress);
    }
    return _moreTopicsFetchProgress as Future<Iterable<Topic>>;
  }

  void completeMoreTopics({@required String cursor, Iterable<Topic> topics, dynamic error}) {
    if (cursor == null) {
      return;
    }
    assert(topics == null || error == null);
    assert(cursor == _moreTopicsCursor());
    _moreTopicsFetchProgress = error;
    if (topics == null) {
      return;
    }
    if (topics.isEmpty) {
      _moreTopicsFetchProgress = FetchProgress.completed;
      return;
    }
    Iterable<String> ids = topics.map((Topic t) => t.id);
    topics.forEach((Topic t) {
      _topics.putIfAbsent(t.id, () => t);
    });
    _latestTopics.addAll(ids);
  }
}


@immutable
class RequestTopicFetchAction extends Action {
  const RequestTopicFetchAction(this.topicId);

  final String topicId;
}

@immutable
class CompleteTopicFetchAction extends Action {
  const CompleteTopicFetchAction({@required this.topicId, this.topic, this.error});

  final String topicId;
  final Topic topic;
  final dynamic error;
}

TopicState handleRequestTopicFetchAction(TopicState state, RequestTopicFetchAction action) {
  return state..requestTopicFetch(action.topicId);
}

TopicState handleCompleteTopicFetchAction(TopicState state, CompleteTopicFetchAction action) {
  return state..completeTopicFetch(topicId: action.topicId, topic: action.topic, error: action.error);
}

Thunk<TopicState, Null> fetchTopic(String topicId) {
  return (Store<TopicState> store) async {
    TopicState state = store.state;
    store.dispatch(new RequestTopicFetchAction(topicId));
    try {
      final Topic topic = await state.waitTopicFetch(topicId);
      store.dispatch(new CompleteTopicFetchAction(topicId: topicId, topic: topic));
    } catch (e) {
      store.dispatch(new CompleteTopicFetchAction(topicId: topicId, error: e));
    }
  };
}

@immutable
class RequestNewerTopicsAction extends RequestAction<String> {
  RequestNewerTopicsAction();
}


@immutable
class CompleteNewerTopicsAction extends Action {
  const CompleteNewerTopicsAction({this.cursor, this.topics});

  final String cursor;
  final List<Topic> topics;
}

TopicState handleRequestNewerTopicsAction(TopicState state, RequestNewerTopicsAction action) {
  action.result = state.requestNewerTopics();
  return state;
}

TopicState handleCompleteNewerTopicsAction(TopicState state, CompleteNewerTopicsAction action) {
  return state..completeNewerTopics(cursor: action.cursor, topics: action.topics);
}

Future<Null> fetchNewerTopics(Store<TopicState> store) async {
  TopicState state = store.state;
  RequestNewerTopicsAction request = new RequestNewerTopicsAction();
  store.dispatch(request);
  String cursor = request.result;
  try {
    List<Topic> topics = await state.waitNewerTopics();
    store.dispatch(new CompleteNewerTopicsAction(cursor: cursor, topics: topics));
  } catch (e) {
    store.dispatch(new CompleteNewerTopicsAction(cursor: cursor, topics: const <Topic>[]));
  }
}

@immutable
class RequestMoreTopicsAction extends RequestAction<String> {
  RequestMoreTopicsAction();
}

@immutable
class CompleteMoreTopicsAction extends Action {
  const CompleteMoreTopicsAction({@required this.cursor, this.topics, this.error});

  final String cursor;
  final Iterable<Topic> topics;
  final dynamic error;
}

TopicState handleRequestMoreTopicsAction(TopicState state, RequestMoreTopicsAction action) {
  action.result = state.requestMoreTopics();
  return state;
}

TopicState handleCompleteMoreTopicsAction(TopicState state, CompleteMoreTopicsAction action) {
  return state..completeMoreTopics(cursor: action.cursor, topics: action.topics, error: action.error);
}

Future<Null> fetchMoreTopics(Store<TopicState> store) async {
  TopicState state = store.state;
  RequestMoreTopicsAction request = new RequestMoreTopicsAction();
  store.dispatch(request);
  String cursor = request.result;
  try {
    final Iterable<Topic> topics = await state.waitMoreTopic();
    store.dispatch(new CompleteMoreTopicsAction(cursor: cursor, topics: topics));
  } on Exception catch (e) {
    store.dispatch(new CompleteMoreTopicsAction(cursor: cursor, error: e));
  }
}

final Reducer<TopicState> _reducer = new MergedTypedReducer<TopicState>(
  [
    new ProxyTypedReducer<TopicState, RequestTopicFetchAction>(handleRequestTopicFetchAction),
    new ProxyTypedReducer<TopicState, CompleteTopicFetchAction>(handleCompleteTopicFetchAction),
    new ProxyTypedReducer<TopicState, RequestNewerTopicsAction>(handleRequestNewerTopicsAction),
    new ProxyTypedReducer<TopicState, CompleteNewerTopicsAction>(handleCompleteNewerTopicsAction),
    new ProxyTypedReducer<TopicState, RequestMoreTopicsAction>(handleRequestMoreTopicsAction),
    new ProxyTypedReducer<TopicState, CompleteMoreTopicsAction>(handleCompleteMoreTopicsAction),
  ]
);

Store<TopicState> createTopicStore(String name) {
  return new Store<TopicState>(
    name: name,
    initialState: new TopicState(),
    reducer: _reducer,
  );
}
