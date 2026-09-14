import 'package:catalogo_anime/models/anime.dart';
import 'package:catalogo_anime/providers/favorites_provider.dart';
import 'package:catalogo_anime/providers/watched_provider.dart';
import 'package:catalogo_anime/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const naruto = Anime(id: '11', title: 'Naruto');
  const bleach = Anime(id: '244', title: 'Bleach');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('favoritos persistem e ficam separados por usuário', () async {
    final favorites = FavoritesProvider(await LocalStore.open())..bindUser('ana');

    expect(await favorites.toggle(naruto), isTrue);
    expect(favorites.contains('11'), isTrue);

    final reopened = FavoritesProvider(await LocalStore.open())..bindUser('ana');
    expect(reopened.animes.single.title, 'Naruto');

    reopened.bindUser('bia');
    expect(reopened.isEmpty, isTrue);
  });

  test('desfavoritar remove e persiste a remoção', () async {
    final store = await LocalStore.open();
    final favorites = FavoritesProvider(store)..bindUser('ana');
    await favorites.toggle(naruto);
    await favorites.toggle(bleach);

    expect(await favorites.toggle(naruto), isFalse);

    final reopened = FavoritesProvider(store)..bindUser('ana');
    expect(reopened.animes.map((anime) => anime.id), ['244']);
  });

  test('lista mais recente aparece primeiro', () async {
    final favorites = FavoritesProvider(await LocalStore.open())..bindUser('ana');
    await favorites.toggle(naruto);
    await favorites.toggle(bleach);

    expect(favorites.animes.first.id, '244');
  });

  test('favoritos e assistidos não se misturam', () async {
    final store = await LocalStore.open();
    final favorites = FavoritesProvider(store)..bindUser('ana');
    final watched = WatchedProvider(store)..bindUser('ana');

    await watched.toggle(naruto);

    expect(watched.contains('11'), isTrue);
    expect(favorites.contains('11'), isFalse);
  });

  test('sem usuário logado nada é salvo', () async {
    final favorites = FavoritesProvider(await LocalStore.open());

    expect(await favorites.toggle(naruto), isFalse);
    expect(favorites.isEmpty, isTrue);
  });

  test('notifica ouvintes ao alternar', () async {
    final favorites = FavoritesProvider(await LocalStore.open())..bindUser('ana');
    var notifications = 0;
    favorites.addListener(() => notifications++);

    await favorites.toggle(naruto);

    expect(notifications, 1);
  });
}
