import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import 'package:readhub_flutter/configs/configs.dart';
import 'package:readhub_flutter/envs/api.dart';
import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/news.dart';

class NewsState {
  NewsState({@required this.endpoint, List<WebNews> news}) : _news = news ?? <WebNews>[];

  final List<WebNews> _news;
  final String endpoint;
  List<WebNews> get latestNews => _news;

  Future<Iterable<WebNews>> _fetchMoreNews({final DateTime after, final int pageSize = 10}) async {
    final DateTime lastTimestamp = after ?? (_news.isEmpty ? new DateTime.now() : _news.last.publishDate);
    final Response response = await api.get('$endpoint?lastCursor=${lastTimestamp.millisecondsSinceEpoch}&pageSize=$pageSize');
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
    _newerNewsFetchProgress = _fetchMoreNews(after: cursor).timeout(kNetworkTimeoutDuration);
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
    _moreNewsFetchProgress = _fetchMoreNews().timeout(kNetworkTimeoutDuration);
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
