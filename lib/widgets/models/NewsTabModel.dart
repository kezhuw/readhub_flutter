import 'package:quiver/core.dart';
import 'package:quiver/collection.dart';

import 'package:storey/storey.dart';

import 'package:readhub_flutter/utils/FetchProgress.dart';
import 'package:readhub_flutter/models/news.dart';
import 'package:readhub_flutter/store/news/store.dart';

class NewsTabModel {
  const NewsTabModel({this.latestNews, this.fetchProgress});

  final List<WebNews> latestNews;
  final FetchProgress fetchProgress;

  @override
  bool operator ==(dynamic other) {
    if (other is! NewsTabModel) {
      return false;
    }
    NewsTabModel typedOther = other;
    return listsEqual(latestNews, typedOther.latestNews) && fetchProgress == typedOther.fetchProgress;
  }

  @override
  int get hashCode => hash2(hashObjects(latestNews), fetchProgress);

  static NewsTabModel fromStore(Store<NewsState> store) {
    NewsState state = store.state;
    return new NewsTabModel(
      latestNews: state.latestNews,
      fetchProgress: state.moreNewsFetchProgress,
    );
  }
}
