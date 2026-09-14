import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/watched_provider.dart';
import 'screens/auth_gate.dart';
import 'services/anime_api_service.dart';

class CatalogoAnimeApp extends StatelessWidget {
  const CatalogoAnimeApp({
    super.key,
    required this.api,
    required this.auth,
    required this.favorites,
    required this.watched,
  });

  final AnimeApiService api;
  final AuthProvider auth;
  final FavoritesProvider favorites;
  final WatchedProvider watched;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AnimeApiService>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<FavoritesProvider>.value(value: favorites),
        ChangeNotifierProvider<WatchedProvider>.value(value: watched),
      ],
      child: MaterialApp(
        title: 'Catálogo de Animes',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const AuthGate(),
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3949AB),
        brightness: brightness,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
  }
}
