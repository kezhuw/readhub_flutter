import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';

import 'package:readhub_flutter/store/store.dart';

import 'package:readhub_flutter/models/NewsTabModel.dart';

import 'package:readhub_flutter/widgets/NewsStream.dart';

NewsTabModel _fromStore(Store<AppState> store) {
  AppState state = store.state;
  return new NewsTabModel(
    latestNews: state.techNews.latestNews,
    fetchProgress: state.techNews.moreNewsFetchProgress,
  );
}

@immutable
class TechNewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new NewsStream(
      converter: _fromStore,
      newerNewsAction: fetchNewerTechNews,
      moreNewsAction: fetchMoreTechNews
    );
  }
}


