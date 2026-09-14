import 'package:flutter/foundation.dart';

import '../models/anime.dart';
import '../services/local_store.dart';

abstract class AnimeListProvider extends ChangeNotifier {
  AnimeListProvider(this._store, this._keyPrefix);

  final LocalStore _store;
  final String _keyPrefix;
  final Map<String, Anime> _animes = {};
  String? _user;

  List<Anime> get animes => _animes.values.toList().reversed.toList(growable: false);
  bool get isEmpty => _animes.isEmpty;

  bool contains(String animeId) => _animes.containsKey(animeId);

  void bindUser(String? user) {
    if (user == _user) return;
    _user = user;
    _animes.clear();
    if (user != null) _loadFrom(_store.readJson(_storageKey(user)));
    notifyListeners();
  }

  Future<bool> toggle(Anime anime) async {
    final user = _user;
    if (user == null) return false;
    final added = _animes.remove(anime.id) == null;
    if (added) _animes[anime.id] = anime;
    notifyListeners();
    await _store.writeJson(
      _storageKey(user),
      _animes.values.map((item) => item.toSummaryJson()).toList(),
    );
    return added;
  }

  String _storageKey(String user) => '$_keyPrefix:$user';

  void _loadFrom(Object? raw) {
    if (raw is! List) return;
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final anime = Anime.fromSummaryJson(item);
      _animes[anime.id] = anime;
    }
  }
}
