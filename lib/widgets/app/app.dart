import 'package:flutter/material.dart';

import 'package:storey/storey.dart';
import 'package:flutter_storey/flutter_storey.dart';

import 'package:readhub_flutter/store/store.dart';

import 'package:readhub_flutter/widgets/pages/MainPage.dart';
import 'package:readhub_flutter/widgets/WorldClock.dart';

final Store<AppState> store = createStore();

final Widget _app = new MaterialApp(
  title: 'Readhub',
  theme: new ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
  ),
  home: new MainPage(),
);

class ReadhubApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new StoreProvider(
      store: store,
      child: new WorldClock(
        child: _app,
      ),
    );
  }
}
