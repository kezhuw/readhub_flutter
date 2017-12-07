import 'package:meta/meta.dart';

@immutable
class WebNews {
  const WebNews({
    @required this.id,
    @required this.title,
    this.summary,
    this.url,
    this.mobileUrl,
    this.siteName,
    this.siteSlug,
    this.authorName,
    this.publishDate,
    this.language,
    this.groupId = 0,
    this.duplicateId = 1,
  });

  final String id;
  final String title;
  final String summary;

  final String url;
  final String mobileUrl;
  final String siteName;
  final String siteSlug;
  final String authorName;
  final DateTime publishDate;
  final String language;

  final int groupId;
  final int duplicateId;

  factory WebNews.fromJsonObject(Map json) {
    return new WebNews(
      id: json["id"].toString(),
      title: json["title"],
      summary: json["summary"],
      url: json["url"],
      mobileUrl: json["mobileUrl"],
      siteName: json["siteName"],
      siteSlug: json["siteSlug"],
      authorName: json["authorName"],
      publishDate: DateTime.parse(json["publishDate"]),
      language: json["language"],
      groupId: json["groupId"] ?? 0,
      duplicateId: json["duplicateId"] ?? 1,
    );
  }

  WebNews merge(WebNews other) {
    return new WebNews(
      id: id,
      title: title,
      summary: summary,
      url: url,
      mobileUrl: mobileUrl,
      siteName: <String>[siteName, other.siteName].join(' / '),
      siteSlug: <String>[siteSlug, other.siteSlug].join(' / '),
      authorName: authorName,
      publishDate: publishDate,
      language: language,
      groupId: groupId,
      duplicateId: duplicateId,
    );
  }
}
