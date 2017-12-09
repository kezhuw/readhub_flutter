import 'package:meta/meta.dart';

import 'package:flutter/material.dart';

import 'package:readhub_flutter/store/news/store.dart';

import 'package:readhub_flutter/widgets/models/NewsTabModel.dart';

import 'package:readhub_flutter/widgets/NewsStream.dart';

@immutable
class NewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new NewsStream(
      path: const <String>['news'],
      converter: NewsTabModel.fromStore,
      newerNewsAction: fetchNewerNews,
      moreNewsAction: fetchMoreNews
    );
  }
}


