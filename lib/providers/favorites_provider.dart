import '../services/local_store.dart';
import 'anime_list_provider.dart';

class FavoritesProvider extends AnimeListProvider {
  FavoritesProvider(LocalStore store) : super(store, 'favorites');
}
