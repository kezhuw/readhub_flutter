import 'package:storey/storey.dart';

import 'package:flutter/widgets.dart';

import 'news/store.dart';
import 'topic/store.dart';

export 'news/store.dart';
export 'topic/store.dart';

class AppState {
  const AppState();
}

Store<AppState> createStore() {
  return new Store<AppState>(
    initialState: const AppState(),
    reducer: null,
    children: <ValueKey<String>, Store<dynamic>>{
      const ValueKey<String>("topics"): createTopicStore(),
      const ValueKey<String>('news') : createNewsStore('/news'),
      const ValueKey<String>('technews') : createNewsStore('/technews'),
    },
    middlewares: [thunkMiddleware],
  );
}
