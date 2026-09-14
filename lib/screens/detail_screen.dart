import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../models/anime_labels.dart';
import '../providers/favorites_provider.dart';
import '../providers/watched_provider.dart';
import '../services/anime_api_service.dart';
import '../services/api_exception.dart';
import '../widgets/anime_poster.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.preview});

  final Anime preview;

  static Future<void> open(BuildContext context, Anime anime) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DetailScreen(preview: anime)),
    );
  }

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final AnimeApiService _api;
  late Future<Anime> _detail;

  @override
  void initState() {
    super.initState();
    _api = context.read<AnimeApiService>();
    _detail = _api.fetchDetail(widget.preview.id);
  }

  void _retry() {
    setState(() {
      _detail = _api.fetchDetail(widget.preview.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preview.title),
        actions: [_FavoriteButton(anime: widget.preview)],
      ),
      body: FutureBuilder<Anime>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Carregando detalhes...');
          }
          final anime = snapshot.data;
          if (snapshot.hasError || anime == null) {
            return ErrorView(
              message: ApiException.describe(snapshot.error),
              onRetry: _retry,
            );
          }
          return _DetailContent(anime: anime);
        },
      ),
    );
  }
}

void _announce(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        context.select<FavoritesProvider, bool>((favorites) => favorites.contains(anime.id));

    return IconButton(
      tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      isSelected: isFavorite,
      icon: const Icon(Icons.star_border),
      selectedIcon: const Icon(Icons.star),
      onPressed: () async {
        final favorites = context.read<FavoritesProvider>();
        final added = await favorites.toggle(anime);
        if (!context.mounted) return;
        _announce(
          context,
          added
              ? '"${anime.title}" adicionado aos favoritos.'
              : '"${anime.title}" removido dos favoritos.',
        );
      },
    );
  }
}

class _WatchedButton extends StatelessWidget {
  const _WatchedButton({required this.anime});

  final Anime anime;

  Future<void> _toggle(BuildContext context) async {
    final watched = context.read<WatchedProvider>();
    final added = await watched.toggle(anime);
    if (!context.mounted) return;
    _announce(
      context,
      added
          ? '"${anime.title}" marcado como assistido.'
          : '"${anime.title}" removido dos assistidos.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWatched =
        context.select<WatchedProvider, bool>((watched) => watched.contains(anime.id));
    final style = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size.fromHeight(52)),
    );

    return isWatched
        ? FilledButton.icon(
            onPressed: () => _toggle(context),
            style: style,
            icon: const Icon(Icons.task_alt),
            label: const Text('Assistido · toque para desmarcar'),
          )
        : OutlinedButton.icon(
            onPressed: () => _toggle(context),
            style: style,
            icon: const Icon(Icons.add_task),
            label: const Text('Marcar como assistido'),
          );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.anime});

  final Anime anime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: AnimePoster(
                        url: anime.largePosterUrl ?? anime.posterUrl,
                        title: anime.title,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(anime.title, style: theme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 16),
              _WatchedButton(anime: anime),
              const SizedBox(height: 24),
              _InfoRow(label: 'Tipo', value: anime.typeLabel),
              _InfoRow(label: 'Situação', value: anime.statusLabel),
              _InfoRow(label: 'Episódios', value: anime.episodesLabel),
              _InfoRow(label: 'Nota média', value: anime.ratingLabel),
              _InfoRow(label: 'Estreia', value: anime.startDateLabel),
              _InfoRow(label: 'Classificação', value: anime.ageRatingLabel),
              if (anime.genres.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Gêneros'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in anime.genres) Chip(label: Text(genre)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const _SectionTitle('Sinopse'),
              Text(
                anime.synopsis ?? 'Sinopse não disponível.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
