import 'package:readhub_flutter/store/news.dart';
import 'package:readhub_flutter/utils/FetchProgress.dart';

class NewsTabModel {
  const NewsTabModel({this.latestNews, this.fetchProgress});

  final List<WebNews> latestNews;
  final FetchProgress fetchProgress;
}
