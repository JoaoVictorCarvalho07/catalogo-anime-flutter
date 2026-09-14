import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watched_provider.dart';
import 'services/anime_api_service.dart';
import 'services/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = await LocalStore.open();
  final auth = AuthProvider(store);
  final favorites = FavoritesProvider(store);
  final watched = WatchedProvider(store);

  void bindListsToCurrentUser() {
    favorites.bindUser(auth.currentUser);
    watched.bindUser(auth.currentUser);
  }

  bindListsToCurrentUser();
  auth.addListener(bindListsToCurrentUser);

  runApp(
    CatalogoAnimeApp(
      api: AnimeApiService(),
      auth: auth,
      favorites: favorites,
      watched: watched,
    ),
  );
}
