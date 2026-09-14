import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/watched_provider.dart';
import '../widgets/anime_grid.dart';
import '../widgets/empty_view.dart';
import 'detail_screen.dart';

class WatchedScreen extends StatelessWidget {
  const WatchedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistidos')),
      body: Consumer<WatchedProvider>(
        builder: (context, watched, _) {
          if (watched.isEmpty) {
            return const EmptyView(
              icon: Icons.task_alt,
              message:
                  'Nenhum anime assistido ainda. Abra um anime e toque em "Marcar como assistido".',
            );
          }
          return AnimeGrid(
            animes: watched.animes,
            onTap: (anime) => DetailScreen.open(context, anime),
          );
        },
      ),
    );
  }
}
