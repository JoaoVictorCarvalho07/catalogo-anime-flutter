import 'dart:convert';

import 'package:catalogo_anime/models/anime.dart';
import 'package:catalogo_anime/providers/favorites_provider.dart';
import 'package:catalogo_anime/providers/watched_provider.dart';
import 'package:catalogo_anime/screens/detail_screen.dart';
import 'package:catalogo_anime/screens/favorites_screen.dart';
import 'package:catalogo_anime/screens/watched_screen.dart';
import 'package:catalogo_anime/services/anime_api_service.dart';
import 'package:catalogo_anime/services/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _preview = Anime(id: '8133', title: 'Haikyuu!!');

final _detailBody = jsonEncode({
  'data': {
    'id': '8133',
    'attributes': {
      'canonicalTitle': 'Haikyuu!!',
      'synopsis': 'Vôlei no colegial.',
      'showType': 'TV',
      'status': 'finished',
      'episodeCount': 25,
      'averageRating': '82.93',
      'startDate': '2014-04-06',
      'ageRating': 'PG',
    },
  },
  'included': [
    {
      'type': 'genres',
      'attributes': {'name': 'Sports'},
    },
  ],
});

AnimeApiService _fakeApi() => AnimeApiService(
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode(_detailBody), 200),
      ),
    );

Widget _wrap({
  required Widget home,
  required FavoritesProvider favorites,
  required WatchedProvider watched,
}) {
  return MultiProvider(
    providers: [
      Provider<AnimeApiService>.value(value: _fakeApi()),
      ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ChangeNotifierProvider<WatchedProvider>.value(value: watched),
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FavoritesProvider favorites;
  late WatchedProvider watched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();
    favorites = FavoritesProvider(store)..bindUser('ana');
    watched = WatchedProvider(store)..bindUser('ana');
  });

  testWidgets('detalhe mostra os atributos vindos da API', (tester) async {
    await tester.pumpWidget(
      _wrap(
        home: const DetailScreen(preview: _preview),
        favorites: favorites,
        watched: watched,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tipo: Série de TV'), findsOneWidget);
    expect(find.text('Situação: Finalizado'), findsOneWidget);
    expect(find.text('Episódios: 25 episódios'), findsOneWidget);
    expect(find.text('Nota média: 82,9%'), findsOneWidget);
    expect(find.text('Estreia: 06/04/2014'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Sports'), findsOneWidget);
    expect(find.text('Vôlei no colegial.'), findsOneWidget);
  });

  testWidgets('estrela favorita e desfavorita pelo Provider', (tester) async {
    await tester.pumpWidget(
      _wrap(
        home: const DetailScreen(preview: _preview),
        favorites: favorites,
        watched: watched,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();

    expect(favorites.contains('8133'), isTrue);
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);
    expect(find.text('"Haikyuu!!" adicionado aos favoritos.'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();

    expect(favorites.isEmpty, isTrue);
    expect(find.byTooltip('Adicionar aos favoritos'), findsOneWidget);
  });

  testWidgets('botão marca e desmarca como assistido', (tester) async {
    await tester.pumpWidget(
      _wrap(
        home: const DetailScreen(preview: _preview),
        favorites: favorites,
        watched: watched,
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Marcar como assistido'));

    expect(watched.contains('8133'), isTrue);
    expect(find.text('Assistido · toque para desmarcar'), findsOneWidget);

    await _tapVisible(tester, find.text('Assistido · toque para desmarcar'));

    expect(watched.isEmpty, isTrue);
  });

  testWidgets('tela de favoritos lista e esvazia junto com o Provider', (tester) async {
    await tester.pumpWidget(
      _wrap(
        home: const FavoritesScreen(),
        favorites: favorites,
        watched: watched,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);

    await favorites.toggle(_preview);
    await tester.pumpAndSettle();

    expect(find.text('Haikyuu!!'), findsOneWidget);

    await favorites.toggle(_preview);
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhum favorito ainda'), findsOneWidget);
  });

  testWidgets('tela de assistidos lista o que foi marcado', (tester) async {
    await watched.toggle(_preview);

    await tester.pumpWidget(
      _wrap(
        home: const WatchedScreen(),
        favorites: favorites,
        watched: watched,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Haikyuu!!'), findsOneWidget);
  });
}
