import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../services/local_store.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(
    this._store, {
    this.minimumFeedback = const Duration(milliseconds: 600),
  }) : _currentUser = _store.readString(_sessionKey);

  static const _usersKey = 'auth.users';
  static const _sessionKey = 'auth.session';

  final LocalStore _store;
  final Duration minimumFeedback;
  String? _currentUser;
  bool _isBusy = false;

  String? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isBusy => _isBusy;

  Future<String?> login(String username, String password) {
    final user = _normalize(username);
    return _authenticate(user, () async {
      final matches = _readUsers()[user] == _hash(user, password);
      return matches ? null : 'Usuário ou senha incorretos.';
    });
  }

  Future<String?> register(String username, String password) {
    final user = _normalize(username);
    return _authenticate(user, () async {
      final users = _readUsers();
      if (users.containsKey(user)) return 'Esse nome de usuário já está em uso.';
      users[user] = _hash(user, password);
      await _store.writeJson(_usersKey, users);
      return null;
    });
  }

  Future<void> logout() async {
    await _store.remove(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> _authenticate(
    String user,
    Future<String?> Function() check,
  ) async {
    _isBusy = true;
    notifyListeners();
    try {
      final results = await Future.wait<String?>([
        check(),
        Future<String?>.delayed(minimumFeedback),
      ]);
      final error = results.first;
      if (error == null) {
        await _store.writeString(_sessionKey, user);
        _currentUser = user;
      }
      return error;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Map<String, String> _readUsers() {
    final raw = _store.readJson(_usersKey);
    if (raw is! Map) return {};
    return raw.map((key, value) => MapEntry('$key', '$value'));
  }

  static String _normalize(String username) => username.trim().toLowerCase();

  static String _hash(String user, String password) =>
      sha256.convert(utf8.encode('$user:$password')).toString();
}
