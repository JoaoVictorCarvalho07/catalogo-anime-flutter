import '../services/local_store.dart';
import 'anime_list_provider.dart';

class WatchedProvider extends AnimeListProvider {
  WatchedProvider(LocalStore store) : super(store, 'watched');
}
