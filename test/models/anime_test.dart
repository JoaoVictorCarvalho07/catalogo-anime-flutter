import 'package:catalogo_anime/models/anime.dart';
import 'package:catalogo_anime/models/anime_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Anime.fromKitsuJson', () {
    test('lê atributos completos e só os gêneros do included', () {
      final anime = Anime.fromKitsuJson(
        {
          'id': '7442',
          'type': 'anime',
          'attributes': {
            'canonicalTitle': 'Attack on Titan',
            'synopsis': 'Titãs atacam.',
            'showType': 'TV',
            'status': 'finished',
            'episodeCount': 25,
            'averageRating': '84.44',
            'startDate': '2013-04-07',
            'ageRating': 'R',
            'posterImage': {
              'small': 'https://img.test/small.jpg',
              'large': 'https://img.test/large.jpg',
            },
          },
        },
        included: [
          {
            'type': 'genres',
            'attributes': {'name': 'Action'},
          },
          {
            'type': 'categories',
            'attributes': {'name': 'Ignorada'},
          },
        ],
      );

      expect(anime.id, '7442');
      expect(anime.title, 'Attack on Titan');
      expect(anime.posterUrl, 'https://img.test/small.jpg');
      expect(anime.largePosterUrl, 'https://img.test/large.jpg');
      expect(anime.genres, ['Action']);
      expect(anime.typeLabel, 'Série de TV');
      expect(anime.statusLabel, 'Finalizado');
      expect(anime.episodesLabel, '25 episódios');
      expect(anime.ratingLabel, '84,4%');
      expect(anime.startDateLabel, '07/04/2013');
    });

    test('tolera pôster, episódios e sinopse ausentes', () {
      final anime = Anime.fromKitsuJson({
        'id': 12,
        'attributes': {
          'titles': {'en': 'One Piece'},
          'posterImage': null,
          'episodeCount': null,
          'synopsis': '   ',
        },
      });

      expect(anime.id, '12');
      expect(anime.title, 'One Piece');
      expect(anime.posterUrl, isNull);
      expect(anime.synopsis, isNull);
      expect(anime.episodesLabel, 'Não informado');
      expect(anime.ratingLabel, 'Sem avaliação');
    });
  });

  test('resumo persistido preserva o que a grade precisa', () {
    const original = Anime(
      id: '1',
      title: 'Cowboy Bebop',
      posterUrl: 'https://img.test/p.jpg',
      largePosterUrl: 'https://img.test/l.jpg',
      showType: 'TV',
    );

    final restored = Anime.fromSummaryJson(original.toSummaryJson());

    expect(restored.id, original.id);
    expect(restored.title, original.title);
    expect(restored.posterUrl, original.posterUrl);
    expect(restored.largePosterUrl, original.largePosterUrl);
    expect(restored.showType, original.showType);
  });
}
