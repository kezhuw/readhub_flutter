import 'package:storey/storey.dart';

import 'news/store.dart';
import 'topic/store.dart';

export 'news/store.dart';
export 'topic/store.dart';

class AppState {
  const AppState();
}

Store<AppState> createStore() {
  return new Store<AppState>(
    name: 'app',
    initialState: const AppState(),
    reducer: null,
    children: [createTopicStore('topics'), createNewsStore('news', '/news'), createNewsStore('technews', '/technews')],
    middlewares: [thunkMiddleware],
  );
}
