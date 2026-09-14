class Anime {
  const Anime({
    required this.id,
    required this.title,
    this.posterUrl,
    this.largePosterUrl,
    this.synopsis,
    this.showType,
    this.status,
    this.episodeCount,
    this.averageRating,
    this.startDate,
    this.ageRating,
    this.genres = const [],
  });

  factory Anime.fromKitsuJson(
    Map<String, dynamic> json, {
    List<dynamic> included = const [],
  }) {
    final attributes = _asMap(json['attributes']);
    final poster = _asMap(attributes['posterImage']);
    return Anime(
      id: '${json['id']}',
      title: _titleFrom(attributes),
      posterUrl: _firstUrl(poster, const ['small', 'medium', 'large', 'original']),
      largePosterUrl: _firstUrl(poster, const ['large', 'original', 'medium', 'small']),
      synopsis: _nonBlank(attributes['synopsis']),
      showType: _nonBlank(attributes['showType']),
      status: _nonBlank(attributes['status']),
      episodeCount: _asInt(attributes['episodeCount']),
      averageRating: double.tryParse('${attributes['averageRating'] ?? ''}'),
      startDate: DateTime.tryParse('${attributes['startDate'] ?? ''}'),
      ageRating: _nonBlank(attributes['ageRating']),
      genres: included
          .map(_asMap)
          .where((item) => item['type'] == 'genres')
          .map((item) => _nonBlank(_asMap(item['attributes'])['name']))
          .whereType<String>()
          .toList(growable: false),
    );
  }

  factory Anime.fromSummaryJson(Map<String, dynamic> json) {
    return Anime(
      id: '${json['id']}',
      title: _nonBlank(json['title']) ?? _unknownTitle,
      posterUrl: _nonBlank(json['posterUrl']),
      largePosterUrl: _nonBlank(json['largePosterUrl']),
      showType: _nonBlank(json['showType']),
    );
  }

  static const _unknownTitle = 'Título desconhecido';

  final String id;
  final String title;
  final String? posterUrl;
  final String? largePosterUrl;
  final String? synopsis;
  final String? showType;
  final String? status;
  final int? episodeCount;
  final double? averageRating;
  final DateTime? startDate;
  final String? ageRating;
  final List<String> genres;

  Map<String, dynamic> toSummaryJson() => {
        'id': id,
        'title': title,
        'posterUrl': posterUrl,
        'largePosterUrl': largePosterUrl,
        'showType': showType,
      };

  static String _titleFrom(Map<String, dynamic> attributes) {
    final titles = _asMap(attributes['titles']);
    return _nonBlank(attributes['canonicalTitle']) ??
        _nonBlank(titles['en']) ??
        _nonBlank(titles['en_jp']) ??
        _nonBlank(titles['ja_jp']) ??
        _unknownTitle;
  }

  static String? _firstUrl(Map<String, dynamic> poster, List<String> sizes) {
    for (final size in sizes) {
      final url = _nonBlank(poster[size]);
      if (url != null) return url;
    }
    return null;
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static int? _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse('${value ?? ''}');

  static String? _nonBlank(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
