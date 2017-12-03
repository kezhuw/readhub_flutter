import 'package:meta/meta.dart';

import 'news.dart';

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
  });

  final String id;
  final String title;
  final String summary;
  final List<WebNews> news;
  final String order;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime publishDate;

  List<WebNews> get nonDuplicatedNews {
    return news.fold(<WebNews>[], (List<WebNews> acc, WebNews next) {
      if (acc.isNotEmpty && acc.last.duplicateId == next.duplicateId) {
        acc[acc.length - 1] = acc.last.merge(next);
        return acc;
      }
      return acc..add(next);
    });
  }

  factory Topic.fromJsonObject(Map json) {
    final List<WebNews> news = ((json["newsArray"] ?? []) as List<Map>).map((m) => new WebNews.fromJsonObject(m)).toList();
    final List<Map> traces = json["timeline"] == null ? null : json["timeline"]["topics"] as List<Map>;
    if (traces == null) {
      return new Topic(
        id: json["id"].toString(),
        title: json["title"],
        summary: json["summary"],
        news: news,
        order: json["order"].toString(),
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        publishDate: DateTime.parse(json["publishDate"]),
      );
    }
    final List<TopicTrace> timeline = traces.map((m) => new TopicTrace.fromJsonObject(m)).toList();
    return new TracedTopic(
      id: json["id"].toString(),
      title: json["title"],
      summary: json["summary"],
      news: news,
      order: json["order"].toString(),
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      publishDate: DateTime.parse(json["publishDate"]),
      timeline: timeline,
    );
  }
}

@immutable
class TracedTopic extends Topic {
  const TracedTopic({
    String id,
    String title,
    String summary,
    List<WebNews> news,
    String order,
    DateTime createdAt,
    DateTime updatedAt,
    DateTime publishDate,
    this.timeline,
  }) : super(
    id: id,
    title: title,
    summary: summary,
    news: news,
    order: order,
    createdAt: createdAt,
    updatedAt: updatedAt,
    publishDate: publishDate,
  );

  final List<TopicTrace> timeline;
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
