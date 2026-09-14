import 'dart:convert';

import 'package:catalogo_anime/providers/auth_provider.dart';
import 'package:catalogo_anime/providers/favorites_provider.dart';
import 'package:catalogo_anime/providers/watched_provider.dart';
import 'package:catalogo_anime/screens/catalog_screen.dart';
import 'package:catalogo_anime/screens/detail_screen.dart';
import 'package:catalogo_anime/services/anime_api_service.dart';
import 'package:catalogo_anime/services/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200);

Map<String, dynamic> _item(int id, String title) => {
      'id': '$id',
      'attributes': {'canonicalTitle': title, 'showType': 'TV'},
    };

http.Response _pageResponse(int offset) => _json({
      'data': [
        _item(offset + 1, 'Anime ${offset + 1}'),
        _item(offset + 2, 'Anime ${offset + 2}'),
      ],
      'links': offset == 0 ? {'next': 'https://kitsu.io/next'} : <String, dynamic>{},
    });

AnimeApiService _api({bool failFirstPage = false}) {
  var firstPageCalls = 0;
  return AnimeApiService(
    client: MockClient((request) async {
      final query = request.url.queryParameters;
      if (request.url.path != '/api/edge/anime') {
        return _json({
          'data': _item(99, 'Detalhe carregado'),
          'included': <Object>[],
        });
      }
      if (query.containsKey('filter[text]')) {
        return query['filter[text]'] == 'inexistente'
            ? _json({'data': <Object>[]})
            : _json({'data': [_item(77, 'Encontrado')]});
      }
      final offset = int.parse(query['page[offset]'] ?? '0');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (failFirstPage && offset == 0 && firstPageCalls++ == 0) {
        return http.Response('', 503);
      }
      return _pageResponse(offset);
    }),
  );
}

Future<Widget> _buildApp(AnimeApiService api) async {
  SharedPreferences.setMockInitialValues({'auth.session': 'ana'});
  final store = await LocalStore.open();
  final auth = AuthProvider(store, minimumFeedback: Duration.zero);
  final favorites = FavoritesProvider(store)..bindUser('ana');
  final watched = WatchedProvider(store)..bindUser('ana');

  return MultiProvider(
    providers: [
      Provider<AnimeApiService>.value(value: api),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
      ChangeNotifierProvider<WatchedProvider>.value(value: watched),
    ],
    child: const MaterialApp(home: CatalogScreen()),
  );
}

void main() {
  testWidgets('mostra indicador de carregamento e depois a grade', (tester) async {
    final app = await _buildApp(_api());

    await tester.pumpWidget(app);
    await tester.pump();

    expect(find.text('Carregando animes...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Anime 1'), findsOneWidget);
    expect(find.text('Anime 2'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Carregar Mais'), findsOneWidget);
  });

  testWidgets('Carregar Mais anexa a próxima página e some no fim', (tester) async {
    await tester.pumpWidget(await _buildApp(_api()));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(ElevatedButton, 'Carregar Mais');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Anime 1'), findsOneWidget);
    expect(find.text('Anime 21'), findsOneWidget);
    expect(find.text('Anime 22'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Carregar Mais'), findsNothing);
    expect(find.text('Você chegou ao fim do catálogo.'), findsOneWidget);
  });

  testWidgets('busca leva direto para a tela de detalhes', (tester) async {
    await tester.pumpWidget(await _buildApp(_api()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'one piece');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('busca sem resultado avisa e fica no catálogo', (tester) async {
    await tester.pumpWidget(await _buildApp(_api()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsNothing);
    expect(find.text('Nenhum anime encontrado para "inexistente".'), findsOneWidget);
  });

  testWidgets('busca vazia nem chama a API', (tester) async {
    await tester.pumpWidget(await _buildApp(_api()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Digite o nome de um anime para buscar.'), findsOneWidget);
  });

  testWidgets('falha na API mostra erro amigável e o retry recarrega', (tester) async {
    await tester.pumpWidget(await _buildApp(_api(failFirstPage: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('fora do ar'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Anime 1'), findsOneWidget);
  });

  testWidgets('sair encerra a sessão', (tester) async {
    await tester.pumpWidget(await _buildApp(_api()));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(CatalogScreen));
    expect(Provider.of<AuthProvider>(context, listen: false).isLoggedIn, isTrue);

    await tester.tap(find.byTooltip('Sair da conta'));
    await tester.pumpAndSettle();

    expect(Provider.of<AuthProvider>(context, listen: false).isLoggedIn, isFalse);
  });
}
