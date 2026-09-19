import 'dart:convert';

import 'package:catalogo_anime/services/anime_api_service.dart';
import 'package:catalogo_anime/services/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

Matcher _apiError(String fragment) => throwsA(
      isA<ApiException>().having((e) => e.message, 'message', contains(fragment)),
    );

void main() {
  test('fetchPage pede o offset certo e calcula a próxima página', () async {
    late Uri requested;
    final api = AnimeApiService(
      client: MockClient((request) async {
        requested = request.url;
        return _json({
          'data': [
            {
              'id': '1',
              'attributes': {'canonicalTitle': 'Cowboy Bebop'},
            },
          ],
          'links': {'next': 'https://kitsu.io/next'},
        });
      }),
    );

    final page = await api.fetchPage(offset: 20);

    expect(requested.queryParameters['page[offset]'], '20');
    expect(requested.queryParameters['page[limit]'], '${AnimeApiService.pageSize}');
    expect(page.items.single.title, 'Cowboy Bebop');
    expect(page.nextOffset, 20 + AnimeApiService.pageSize);
  });

  test('fetchPage sem links.next encerra a paginação', () async {
    final api = AnimeApiService(
      client: MockClient((_) async => _json({
            'data': [
              {'id': '1', 'attributes': <String, dynamic>{}},
            ],
            'links': <String, dynamic>{},
          })),
    );

    final page = await api.fetchPage();

    expect(page.hasNext, isFalse);
  });

  test('searchFirst devolve null quando não há resultado', () async {
    late Uri requested;
    final api = AnimeApiService(
      client: MockClient((request) async {
        requested = request.url;
        return _json({'data': <Object>[]});
      }),
    );

    expect(await api.searchFirst('zzz'), isNull);
    expect(requested.queryParameters['filter[text]'], 'zzz');
  });

  test('fetchDetail lê gêneros do included', () async {
    final api = AnimeApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/edge/anime/12');
        return _json({
          'data': {
            'id': '12',
            'attributes': {'canonicalTitle': 'One Piece'},
          },
          'included': [
            {
              'type': 'genres',
              'attributes': {'name': 'Adventure'},
            },
          ],
        });
      }),
    );

    final anime = await api.fetchDetail('12');

    expect(anime.genres, ['Adventure']);
  });

  test('servidor fora do ar vira mensagem amigável', () {
    final api = AnimeApiService(client: MockClient((_) async => http.Response('', 503)));
    expect(api.fetchPage(), _apiError('fora do ar'));
  });

  test('falha de conexão vira mensagem amigável', () {
    final api = AnimeApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(api.fetchPage(), _apiError('Sem conexão'));
  });

  test('resposta que não é JSON vira mensagem amigável', () {
    final api = AnimeApiService(
      client: MockClient((_) async => http.Response('<html>', 200)),
    );
    expect(api.fetchPage(), _apiError('inesperado'));
  });

  test('demora além do timeout vira mensagem amigável', () {
    final api = AnimeApiService(
      timeout: const Duration(milliseconds: 10),
      client: MockClient(
        (_) => Future.delayed(
          const Duration(milliseconds: 200),
          () => _json({'data': <Object>[]}),
        ),
      ),
    );
    expect(api.fetchPage(), _apiError('demorou'));
  });

  test('searchSuggestions pede várias opções e devolve a lista', () async {
    late Uri requested;
    final api = AnimeApiService(
      client: MockClient((request) async {
        requested = request.url;
        return _json({
          'data': [
            {'id': '1', 'attributes': {'canonicalTitle': 'Naruto'}},
            {'id': '2', 'attributes': {'canonicalTitle': 'Naruto Shippuden'}},
          ],
        });
      }),
    );

    final results = await api.searchSuggestions('naruto');

    expect(requested.queryParameters['filter[text]'], 'naruto');
    expect(requested.queryParameters['page[limit]'], '6');
    expect(results.map((anime) => anime.title), ['Naruto', 'Naruto Shippuden']);
  });
}
