import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:http/http.dart' as http;

import 'package:readhub_flutter/envs/http.dart';

import 'topic.dart';
import 'news.dart';

final http.Client _http = createApiClient();

const Duration _kFetchTimeoutDuration = const Duration(seconds: 12);

enum FetchStatus {
  none,
  busy,
  exception,
  completed,
}

@immutable
class FetchProgress {
  const FetchProgress._fetchProgress({@required this.status, this.exception});

  final FetchStatus status;
  final dynamic exception;

  static const none = const FetchProgress._fetchProgress(status: FetchStatus.none);
  static const busy = const FetchProgress._fetchProgress(status: FetchStatus.busy);
  static const completed = const FetchProgress._fetchProgress(status: FetchStatus.completed);

  const FetchProgress.error(this.exception) : status = FetchStatus.none;
}

class NewsState {
  NewsState({@required this.endpoint, List<WebNews> news}) : _news = news ?? <WebNews>[];

  final List<WebNews> _news;
  final String endpoint;
  List<WebNews> get latestNews => _news;

  Future<Iterable<WebNews>> _fetchMoreNews({final DateTime after, final int pageSize = 10}) async {
    final DateTime lastTimestamp = after ?? (_news.isEmpty ? new DateTime.now() : _news.last.publishDate);
    final http.Response response = await _http.get('$endpoint?lastCursor=${lastTimestamp.millisecondsSinceEpoch}&pageSize=$pageSize');
    final Map<String, dynamic> result = JSON.decode(response.body);
    final List<Map<String, dynamic>> data = result['data'];
    Iterable<WebNews> news = data.map((Map<String, dynamic> json) => new WebNews.fromJsonObject(json));
    return news;
  }

  Future<Iterable<WebNews>> _newerNewsFetchProgress;

  dynamic requestNewerNews() {
    if (_newerNewsFetchProgress != null || _news.isEmpty) {
      return null;
    }
    DateTime cursor = new DateTime.now();
    _newerNewsFetchProgress = _fetchMoreNews(after: cursor).timeout(_kFetchTimeoutDuration);
    return cursor;
  }

  Future<Iterable<WebNews>> waitNewerNews() {
    return _newerNewsFetchProgress ?? new Future<Iterable<WebNews>>.value(const Iterable<WebNews>.empty());
  }

  void completeNewerNews({@required dynamic cursor, @required Iterable<WebNews> news}) {
    if (cursor == null || _news.isEmpty) {
      return;
    }
    _newerNewsFetchProgress = null;
    if (news.isEmpty) {
      return;
    }
    final WebNews first = _news.first;
    bool overlapping = false;
    // takeWhile happens lazily, use toList to force its evaluation,
    // otherwise the side effect 'setting overlapping' won't happen.
    news = news.takeWhile((WebNews news) {
      if (news.id == first.id) {
        overlapping = true;
        return false;
      }
      return true;
    }).toList();
    if (!overlapping) {
      _news.clear();
    }
    _news.insertAll(0, news);
  }


  dynamic _moreNewsFetchProgress;

  FetchProgress get moreNewsFetchProgress {
    if (_moreNewsFetchProgress == null) {
      return FetchProgress.none;
    }
    if (identical(_moreNewsFetchProgress, FetchProgress.completed)) {
      return FetchProgress.completed;
    }
    if (_moreNewsFetchProgress is Future) {
      return FetchProgress.busy;
    }
    return new FetchProgress.error(_moreNewsFetchProgress);
  }

  void requestMoreNews() {
    if (identical(_moreNewsFetchProgress, FetchProgress.completed)) {
      return;
    }
    if (_moreNewsFetchProgress is Future) {
      return;
    }
    _moreNewsFetchProgress = _fetchMoreNews().timeout(_kFetchTimeoutDuration);
  }

  Future<Iterable<WebNews>> waitMoreNews() {
    assert(_moreNewsFetchProgress != null);
    if (identical(_moreNewsFetchProgress, FetchProgress.completed)) {
      return new Future<Iterable<WebNews>>.value(const Iterable<WebNews>.empty());
    }
    if (_moreNewsFetchProgress is! Future) {
      return new Future<Iterable<WebNews>>.error(_moreNewsFetchProgress);
    }
    return _moreNewsFetchProgress as Future<List<WebNews>>;
  }

  void completeMoreNews({Iterable<WebNews> news, dynamic error}) {
    assert(news == null || error == null);
    _moreNewsFetchProgress = error;
    if (news == null) {
      return;
    }
    if (news.isEmpty) {
      _moreNewsFetchProgress = FetchProgress.completed;
    } else {
      _news.addAll(news);
    }
  }
}

class AppState {
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
    final http.Response response = await _http.get('/topic/$topicId');
    Map<String, dynamic> result = JSON.decode(response.body);
    return new Topic.fromJsonObject(result);
  }

  void requestTopicFetch(String topicId) {
    Topic topic = _topics[topicId];
    if (topic is TracedTopic) {
      return;
    }
    dynamic progress = _fetchingTopics[topicId];
    if (progress == null || progress is! Future) {
      _fetchingTopics[topicId] = _fetchTopic(topicId).timeout(_kFetchTimeoutDuration);
    }
  }

  Future<Topic> waitTopicFetch(String topicId) async {
    Topic topic = _topics[topicId];
    if (topic is TracedTopic) {
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
    assert(topic is TracedTopic);
    _topics[topicId] = topic;
    _fetchingTopics.remove(topicId);
  }


  Future<List<Topic>> _newerTopicsFuture;
  String get _newerTopicsCursor => _topics[_latestTopics.first].order;

  Future<Iterable<String>> _fetchNewerTopicIds() async {
    assert(_latestTopics.isNotEmpty);
    final String latestCursor = _newerTopicsCursor;
    final http.Response response = await _http.get('/topic/newCount?latestCursor=$latestCursor');
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
    _newerTopicsFuture = _fetchNewerTopics().timeout(_kFetchTimeoutDuration);
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
    final http.Response response = await _http.get('/topic?lastCursor=$lastCursor&pageSize=$pageSize');
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
    _moreTopicsFetchProgress = _fetchMoreTopics().timeout(_kFetchTimeoutDuration);
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

  final NewsState news = new NewsState(endpoint: '/news');
  final NewsState techNews = new NewsState(endpoint: '/technews');
}


@immutable
class RequestTopicFetchAction {
  const RequestTopicFetchAction(this.topicId);

  final String topicId;
}

@immutable
class CompleteTopicFetchAction {
  const CompleteTopicFetchAction({@required this.topicId, this.topic, this.error});

  final String topicId;
  final Topic topic;
  final dynamic error;
}

AppState handleRequestTopicFetchAction(AppState state, RequestTopicFetchAction action) {
  return state..requestTopicFetch(action.topicId);
}

AppState handleCompleteTopicFetchAction(AppState state, CompleteTopicFetchAction action) {
  return state..completeTopicFetch(topicId: action.topicId, topic: action.topic, error: action.error);
}

ThunkAction<AppState> fetchTopic(String topicId) {
  return (Store<AppState> store) async {
    AppState state = store.state;
    store.dispatch(new RequestTopicFetchAction(topicId));
    try {
      final Topic topic = await state.waitTopicFetch(topicId);
      store.dispatch(new CompleteTopicFetchAction(topicId: topicId, topic: topic));
    } catch (e) {
      store.dispatch(new CompleteTopicFetchAction(topicId: topicId, error: e));
    }
  };
}

class RequestNewerTopicsAction {
  RequestNewerTopicsAction();

  String cursor;
}


@immutable
class CompleteNewerTopicsAction {
  const CompleteNewerTopicsAction({this.cursor, this.topics});

  final String cursor;
  final List<Topic> topics;
}

AppState handleRequestNewerTopicsAction(AppState state, RequestNewerTopicsAction action) {
  action.cursor = state.requestNewerTopics();
  return state;
}

AppState handleCompleteNewerTopicsAction(AppState state, CompleteNewerTopicsAction action) {
  return state..completeNewerTopics(cursor: action.cursor, topics: action.topics);
}

Future<Null> fetchNewerTopics(Store<AppState> store) async {
  AppState state = store.state;
  RequestNewerTopicsAction request = new RequestNewerTopicsAction();
  store.dispatch(request);
  try {
    List<Topic> topics = await state.waitNewerTopics();
    store.dispatch(new CompleteNewerTopicsAction(cursor: request.cursor, topics: topics));
  } catch (e) {
    store.dispatch(new CompleteNewerTopicsAction(cursor: request.cursor, topics: const <Topic>[]));
  }
}

class RequestMoreTopicsAction {
  RequestMoreTopicsAction();

  String cursor;
}

@immutable
class CompleteMoreTopicsAction {
  const CompleteMoreTopicsAction({@required this.cursor, this.topics, this.error});

  final String cursor;
  final Iterable<Topic> topics;
  final dynamic error;
}

AppState handleRequestMoreTopicsAction(AppState state, RequestMoreTopicsAction action) {
  action.cursor = state.requestMoreTopics();
  return state;
}

AppState handleCompleteMoreTopicsAction(AppState state, CompleteMoreTopicsAction action) {
  return state..completeMoreTopics(cursor: action.cursor, topics: action.topics, error: action.error);
}

Future<Null> fetchMoreTopics(Store<AppState> store) async {
  AppState state = store.state;
  RequestMoreTopicsAction request = new RequestMoreTopicsAction();
  store.dispatch(request);
  try {
    final Iterable<Topic> topics = await state.waitMoreTopic();
    store.dispatch(new CompleteMoreTopicsAction(cursor: request.cursor, topics: topics));
  } on Exception catch (e) {
    store.dispatch(new CompleteMoreTopicsAction(cursor: request.cursor, error: e));
  }
}


class RequestNewerNewsAction {
  RequestNewerNewsAction();

  dynamic cursor;
}

@immutable
class CompleteNewerNewsAction {
  const CompleteNewerNewsAction({this.cursor, this.news});

  final dynamic cursor;
  final Iterable<WebNews> news;
}

AppState handleRequestNewerNewsAction(AppState state, RequestNewerNewsAction action) {
  action.cursor = state.news.requestNewerNews();
  return state;
}

AppState handleCompleteNewerNewsAction(AppState state, CompleteNewerNewsAction action) {
  return state..news.completeNewerNews(cursor: action.cursor, news: action.news);
}

Future<Null> fetchNewerNews(Store<AppState> store) async {
  AppState state = store.state;
  RequestNewerNewsAction request = new RequestNewerNewsAction();
  store.dispatch(request);
  try {
    Iterable<WebNews> news = await state.news.waitNewerNews();
    store.dispatch(new CompleteNewerNewsAction(cursor: request.cursor, news: news));
  } catch (e) {
    store.dispatch(new CompleteNewerNewsAction(cursor: request.cursor, news: const Iterable<WebNews>.empty()));
  }
}


@immutable
class RequestMoreNewsAction {
  const RequestMoreNewsAction();
}

@immutable
class CompleteMoreNewsAction {
  const CompleteMoreNewsAction({this.news, this.error});

  final Iterable<WebNews> news;
  final dynamic error;
}

AppState handleRequestMoreNewsAction(AppState state, RequestMoreNewsAction action) {
  return state..news.requestMoreNews();
}

AppState handleCompleteMoreNewsAction(AppState state, CompleteMoreNewsAction action) {
  return state..news.completeMoreNews(news: action.news, error: action.error);
}

Future<Null> fetchMoreNews(Store<AppState> store) async {
  store.dispatch(const RequestMoreNewsAction());
  try {
    Iterable<WebNews> news = await store.state.news.waitMoreNews();
    store.dispatch(new CompleteMoreNewsAction(news: news));
  } catch (e) {
    store.dispatch(new CompleteMoreNewsAction(error: e));
  }
}

class RequestNewerTechNewsAction {
  RequestNewerTechNewsAction();

  dynamic cursor;
}

@immutable
class CompleteNewerTechNewsAction {
  const CompleteNewerTechNewsAction({this.cursor, this.news});

  final dynamic cursor;
  final Iterable<WebNews> news;
}

AppState handleRequestNewerTechNewsAction(AppState state, RequestNewerTechNewsAction action) {
  action.cursor = state.techNews.requestNewerNews();
  return state;
}

AppState handleCompleteNewerTechNewsAction(AppState state, CompleteNewerTechNewsAction action) {
  return state..techNews.completeNewerNews(cursor: action.cursor, news: action.news);
}

Future<Null> fetchNewerTechNews(Store<AppState> store) async {
  AppState state = store.state;
  RequestNewerTechNewsAction request = new RequestNewerTechNewsAction();
  store.dispatch(request);
  try {
    Iterable<WebNews> news = await state.techNews.waitNewerNews();
    store.dispatch(new CompleteNewerTechNewsAction(cursor: request.cursor, news: news));
  } catch (e) {
    store.dispatch(new CompleteNewerTechNewsAction(cursor: request.cursor, news: const Iterable<WebNews>.empty()));
  }
}


@immutable
class RequestMoreTechNewsAction {
  const RequestMoreTechNewsAction();
}

@immutable
class CompleteMoreTechNewsAction {
  const CompleteMoreTechNewsAction({this.news, this.error});

  final Iterable<WebNews> news;
  final dynamic error;
}

AppState handleRequestMoreTechNewsAction(AppState state, RequestMoreTechNewsAction action) {
  return state..techNews.requestMoreNews();
}

AppState handleCompleteMoreTechNewsAction(AppState state, CompleteMoreTechNewsAction action) {
  return state..techNews.completeMoreNews(news: action.news, error: action.error);
}

Future<Null> fetchMoreTechNews(Store<AppState> store) async {
  store.dispatch(const RequestMoreTechNewsAction());
  try {
    Iterable<WebNews> news = await store.state.techNews.waitMoreNews();
    store.dispatch(new CompleteMoreTechNewsAction(news: news));
  } catch (e) {
    store.dispatch(new CompleteMoreTechNewsAction(error: e));
  }
}

final Reducer<AppState> _reducer = combineTypedReducers(<ReducerBinding<AppState, dynamic>>[
  new ReducerBinding<AppState, RequestTopicFetchAction>(handleRequestTopicFetchAction),
  new ReducerBinding<AppState, CompleteTopicFetchAction>(handleCompleteTopicFetchAction),

  new ReducerBinding<AppState, RequestNewerTopicsAction>(handleRequestNewerTopicsAction),
  new ReducerBinding<AppState, CompleteNewerTopicsAction>(handleCompleteNewerTopicsAction),

  new ReducerBinding<AppState, RequestMoreTopicsAction>(handleRequestMoreTopicsAction),
  new ReducerBinding<AppState, CompleteMoreTopicsAction>(handleCompleteMoreTopicsAction),

  new ReducerBinding<AppState, RequestNewerNewsAction>(handleRequestNewerNewsAction),
  new ReducerBinding<AppState, CompleteNewerNewsAction>(handleCompleteNewerNewsAction),

  new ReducerBinding<AppState, RequestMoreNewsAction>(handleRequestMoreNewsAction),
  new ReducerBinding<AppState, CompleteMoreNewsAction>(handleCompleteMoreNewsAction),

  new ReducerBinding<AppState, RequestNewerTechNewsAction>(handleRequestNewerTechNewsAction),
  new ReducerBinding<AppState, CompleteNewerTechNewsAction>(handleCompleteNewerTechNewsAction),

  new ReducerBinding<AppState, RequestMoreTechNewsAction>(handleRequestMoreTechNewsAction),
  new ReducerBinding<AppState, CompleteMoreTechNewsAction>(handleCompleteMoreTechNewsAction),
]);

Store<AppState> createStore() {
  return new Store(
    _reducer,
    initialState: new AppState(),
    middleware: <Middleware<AppState>>[
      thunkMiddleware,
    ],
  );
}
