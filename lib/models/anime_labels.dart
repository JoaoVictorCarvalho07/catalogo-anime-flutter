import 'anime.dart';

const _notInformed = 'Não informado';

extension AnimeLabels on Anime {
  String get typeLabel => switch (showType?.toLowerCase()) {
        'tv' => 'Série de TV',
        'movie' => 'Filme',
        'ova' => 'OVA',
        'ona' => 'ONA',
        'special' => 'Especial',
        'music' => 'Clipe musical',
        null => _notInformed,
        final other => other,
      };

  String get statusLabel => switch (status?.toLowerCase()) {
        'finished' => 'Finalizado',
        'current' => 'Em exibição',
        'upcoming' => 'Em breve',
        'tba' => 'A anunciar',
        'unreleased' => 'Não lançado',
        null => _notInformed,
        final other => other,
      };

  String get episodesLabel => switch (episodeCount) {
        null => _notInformed,
        1 => '1 episódio',
        final count => '$count episódios',
      };

  String get ratingLabel {
    final rating = averageRating;
    if (rating == null) return 'Sem avaliação';
    return '${rating.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  String get startDateLabel {
    final date = startDate;
    if (date == null) return _notInformed;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  String get ageRatingLabel => ageRating ?? _notInformed;
}
