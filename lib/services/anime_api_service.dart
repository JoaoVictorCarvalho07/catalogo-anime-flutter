import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/anime.dart';
import '../models/anime_page.dart';
import 'api_exception.dart';

class AnimeApiService {
  AnimeApiService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static const pageSize = 20;
  static const _host = 'kitsu.io';
  static const _animePath = '/api/edge/anime';
  static const _headers = {'Accept': 'application/vnd.api+json'};
  static const _unexpectedResponse =
      'O serviço de animes respondeu de um jeito inesperado. Tente novamente.';

  final http.Client _client;
  final Duration timeout;

  Future<AnimePage> fetchPage({int offset = 0}) async {
    final body = await _getJson(Uri.https(_host, _animePath, {
      'page[limit]': '$pageSize',
      'page[offset]': '$offset',
      'sort': '-userCount',
    }));
    final items = _animeList(body);
    final links = body['links'];
    final hasNext = links is Map && links['next'] != null && items.isNotEmpty;
    return AnimePage(
      items: items,
      nextOffset: hasNext ? offset + pageSize : null,
    );
  }

  Future<Anime?> searchFirst(String query) async {
    final results = await searchSuggestions(query, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  Future<List<Anime>> searchSuggestions(String query, {int limit = 6}) async {
    final body = await _getJson(Uri.https(_host, _animePath, {
      'filter[text]': query,
      'page[limit]': '$limit',
    }));
    return _animeList(body);
  }

  Future<Anime> fetchDetail(String id) async {
    final body = await _getJson(
      Uri.https(_host, '$_animePath/$id', {'include': 'genres'}),
    );
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const ApiException(_unexpectedResponse);
    }
    final included = body['included'];
    return Anime.fromKitsuJson(
      data,
      included: included is List ? included : const [],
    );
  }

  List<Anime> _animeList(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is! List) throw const ApiException(_unexpectedResponse);
    return data
        .whereType<Map<String, dynamic>>()
        .map(Anime.fromKitsuJson)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response =
          await _client.get(uri, headers: _headers).timeout(timeout);
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'O serviço de animes demorou demais para responder. Tente novamente.',
      );
    } on FormatException {
      throw const ApiException(_unexpectedResponse);
    } on Exception {
      throw const ApiException(
        'Sem conexão com o serviço de animes. Verifique sua internet e tente novamente.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    if (status == 404) {
      throw const ApiException('Esse anime não foi encontrado.');
    }
    if (status == 429) {
      throw const ApiException(
        'Muitas requisições em sequência. Aguarde alguns segundos e tente de novo.',
      );
    }
    if (status >= 500) {
      throw const ApiException(
        'O serviço de animes está fora do ar no momento. Tente novamente mais tarde.',
      );
    }
    if (status != 200) {
      throw ApiException('Não foi possível carregar os animes (erro $status).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(_unexpectedResponse);
    }
    return decoded;
  }
}
