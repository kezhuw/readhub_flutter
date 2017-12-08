import 'package:meta/meta.dart';

import 'package:readhub_flutter/models/news.dart';

@immutable
class Topic {
  const Topic({
    this.id,
    this.title,
    this.summary,
    this.news,
    this.order,
    this.createdAt,
    this.updatedAt,
    this.publishDate,
    this.timeline,
  });

  final String id;
  final String title;
  final String summary;
  final List<WebNews> news;
  final String order;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishDate;

  final List<TopicTrace> timeline;

  bool get whole => timeline != null;

  List<WebNews> get nonDuplicatedNews {
    return news.fold(<WebNews>[], (List<WebNews> acc, WebNews next) {
      if (acc.isNotEmpty && acc.last.duplicateId == next.duplicateId) {
        acc[acc.length - 1] = acc.last.merge(next);
        return acc;
      }
      return acc..add(next);
    });
  }

  factory Topic.fromJsonObject(Map json, {List<TopicTrace> emptyTimeline}) {
    final List<WebNews> news = ((json["newsArray"] ?? []) as List<Map>).map((m) => new WebNews.fromJsonObject(m)).toList();
    final List<Map> traces = json["timeline"] == null ? const [] : json["timeline"]["topics"] as List<Map>;
    final List<TopicTrace> timeline = traces.map((m) => new TopicTrace.fromJsonObject(m)).toList();
    return new Topic(
      id: json["id"].toString(),
      title: json["title"],
      summary: json["summary"],
      news: news,
      order: json["order"].toString(),
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      publishDate: DateTime.parse(json["publishDate"]),
      timeline: timeline.isEmpty ? emptyTimeline : timeline,
    );
  }
}

@immutable
class TopicTrace {
  const TopicTrace({
    this.id,
    this.title,
    this.createAt,
  });

  final String id;
  final String title;
  final DateTime createAt;

  factory TopicTrace.fromJsonObject(Map json) {
    return new TopicTrace(
      id: json["id"].toString(),
      title: json["title"],
      createAt: DateTime.parse(json["createdAt"]),
    );
  }
}
