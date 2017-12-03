import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:readhub_flutter/models/NewsTabModel.dart';

import 'package:readhub_flutter/store/news.dart';
import 'package:readhub_flutter/store/store.dart';

import 'package:readhub_flutter/widgets/NewsTile.dart';
import 'package:readhub_flutter/widgets/FetchProgressPlaceholder.dart';

typedef Future<Null> AsyncStoreAction(Store<AppState> store);

@immutable
class NewsStream extends StatelessWidget {
  NewsStream({
    @required this.converter,
    @required this.newerNewsAction,
    @required this.moreNewsAction,
  });

  final StoreConverter<AppState, NewsTabModel> converter;
  final AsyncStoreAction newerNewsAction;
  final AsyncStoreAction moreNewsAction;

  void _fetchMoreNews(BuildContext context) {
    Store<AppState> store = new StoreProvider.of(context).store;
    store.dispatch(moreNewsAction);
  }

  Widget _buildItem(BuildContext context, NewsTabModel model, int index) {
    if (index < model.latestNews.length) {
      WebNews news = model.latestNews[index];
      return new NewsTile(key: new ObjectKey(news), news: news, maxLines: 3);
    }
    if (index > model.latestNews.length) {
      return null;
    }
    return new FetchProgressPlaceholder(progress: model.fetchProgress, action: () { _fetchMoreNews(context); });
  }

  @override
  Widget build(BuildContext context) {
    BorderSide borderSide = new BorderSide(color: Theme.of(context).dividerColor, width: 0.0);
    Store<AppState> store = new StoreProvider<AppState>.of(context).store;
    return new StoreConnector<AppState, NewsTabModel>(
      converter: converter,
      builder: (BuildContext context, NewsTabModel model) {
        return new Container(
          color: Theme.of(context).canvasColor,
          child: new RefreshIndicator(
            onRefresh: () async {
              await newerNewsAction(store);
            },
            child: new ListView.builder(
              addAutomaticKeepAlives: false,
              itemBuilder: (BuildContext context, int index) {
                Widget item = _buildItem(context, model, index);
                if (item == null) {
                  return null;
                }
                BorderSide bottom = BorderSide.none, top = BorderSide.none;
                if (index < model.latestNews.length-1) {
                  bottom = borderSide;
                } else if (index == model.latestNews.length && index != 0) {
                  top = borderSide;
                }
                return new DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: new BoxDecoration(
                    border: new Border(top: top, bottom: bottom),
                  ),
                  child: new Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(top: 8.0, bottom: 4.0),
                    child: item,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}