import 'anime.dart';

class AnimePage {
  const AnimePage({required this.items, required this.nextOffset});

  final List<Anime> items;
  final int? nextOffset;

  bool get hasNext => nextOffset != null;
}
