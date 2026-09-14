import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../widgets/anime_grid.dart';
import '../widgets/empty_view.dart';
import 'detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Consumer<FavoritesProvider>(
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return const EmptyView(
              icon: Icons.star_border,
              message:
                  'Nenhum favorito ainda. Abra um anime e toque na estrela para favoritar.',
            );
          }
          return AnimeGrid(
            animes: favorites.animes,
            onTap: (anime) => DetailScreen.open(context, anime),
          );
        },
      ),
    );
  }
}
