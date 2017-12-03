import 'package:flutter/material.dart';

import 'TopicTab.dart';
import 'NewsTab.dart';
import 'TechNewsTab.dart';

final List<Tab> _tabs = <String>['热门话题', '科技动态', '开发者咨询'].map((String title) => new Tab(text: title)).toList(growable: false);

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new DefaultTabController(
      length: _tabs.length,
      child: new Scaffold(
        body: new NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              new SliverAppBar(
                title: new Image.network('https://cdn.readhub.me/static/assets/png/readhub_logo_m@2x.78b35cd0.png'),
                floating: true,
                snap: true,
                bottom: new TabBar(tabs: _tabs),
              ),
            ];
          },
          body: new TabBarView(
            children: <Widget>[
              new TopicTab(),
              new NewsTab(),
              new TechNewsTab(),
            ]
          ),
        ),
        floatingActionButton: new Builder(
          builder: (BuildContext context) {
            return new FloatingActionButton(
              onPressed: () => _backTop(context),
              child: new Icon(Icons.vertical_align_top),
            );
          },
        ),
      ),
    );
  }

  void _backTop(BuildContext context) {
    ScrollController scrollController = PrimaryScrollController.of(context);
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }
  }
}
