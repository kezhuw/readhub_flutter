import 'dart:async';

import 'package:meta/meta.dart';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:readhub_flutter/models/topic.dart';
import 'package:readhub_flutter/models/news.dart';

import 'news/store.dart';
import 'topic/store.dart';

export 'news/store.dart';
export 'topic/store.dart';

class AppState {
  final TopicState topics = new TopicState();
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
  return state..topics.requestTopicFetch(action.topicId);
}

AppState handleCompleteTopicFetchAction(AppState state, CompleteTopicFetchAction action) {
  return state..topics.completeTopicFetch(topicId: action.topicId, topic: action.topic, error: action.error);
}

ThunkAction<AppState> fetchTopic(String topicId) {
  return (Store<AppState> store) async {
    AppState state = store.state;
    store.dispatch(new RequestTopicFetchAction(topicId));
    try {
      final Topic topic = await state.topics.waitTopicFetch(topicId);
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
  action.cursor = state.topics.requestNewerTopics();
  return state;
}

AppState handleCompleteNewerTopicsAction(AppState state, CompleteNewerTopicsAction action) {
  return state..topics.completeNewerTopics(cursor: action.cursor, topics: action.topics);
}

Future<Null> fetchNewerTopics(Store<AppState> store) async {
  AppState state = store.state;
  RequestNewerTopicsAction request = new RequestNewerTopicsAction();
  store.dispatch(request);
  try {
    List<Topic> topics = await state.topics.waitNewerTopics();
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
  action.cursor = state.topics.requestMoreTopics();
  return state;
}

AppState handleCompleteMoreTopicsAction(AppState state, CompleteMoreTopicsAction action) {
  return state..topics.completeMoreTopics(cursor: action.cursor, topics: action.topics, error: action.error);
}

Future<Null> fetchMoreTopics(Store<AppState> store) async {
  AppState state = store.state;
  RequestMoreTopicsAction request = new RequestMoreTopicsAction();
  store.dispatch(request);
  try {
    final Iterable<Topic> topics = await state.topics.waitMoreTopic();
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
