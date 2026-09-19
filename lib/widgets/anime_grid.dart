import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/anime.dart';
import 'anime_card.dart';

class AnimeGrid extends StatelessWidget {
  const AnimeGrid({
    super.key,
    required this.animes,
    required this.onTap,
    this.footer,
  });

  static const _padding = 16.0;
  static const _spacing = 12.0;
  static const _maxTileWidth = 180.0;

  final List<Anime> animes;
  final ValueChanged<Anime> onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    final scaledFontSize =
        MediaQuery.textScalerOf(context).scale(titleStyle?.fontSize ?? 14);
    final titleHeight = scaledFontSize * (titleStyle?.height ?? 1.43) * 2 + 20;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth - _padding * 2;
              final columns = math.max(
                2,
                ((available + _spacing) / (_maxTileWidth + _spacing)).ceil(),
              );
              final tileWidth = (available - _spacing * (columns - 1)) / columns;

              return GridView.builder(
                padding: const EdgeInsets.all(_padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: _spacing,
                  crossAxisSpacing: _spacing,
                  mainAxisExtent: tileWidth * 1.5 + titleHeight,
                ),
                itemCount: animes.length,
                itemBuilder: (context, index) {
                  final anime = animes[index];
                  return AnimeCard(
                    key: ValueKey(anime.id),
                    anime: anime,
                    onTap: () => onTap(anime),
                  );
                },
              );
            },
          ),
        ),
        ?footer,
      ],
    );
  }
}
