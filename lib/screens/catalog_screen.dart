import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/anime.dart';
import '../providers/auth_provider.dart';
import '../services/anime_api_service.dart';
import '../services/api_exception.dart';
import '../widgets/anime_grid.dart';
import '../widgets/anime_search_field.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';
import 'watched_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final List<Anime> _animes = [];
  late final AnimeApiService _api;
  late Future<void> _initialLoad;
  int? _nextOffset;
  bool _isLoadingMore = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _api = context.read<AnimeApiService>();
    _initialLoad = _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final page = await _api.fetchPage();
    _animes
      ..clear()
      ..addAll(page.items);
    _nextOffset = page.nextOffset;
  }

  void _retryFirstPage() {
    setState(() {
      _initialLoad = _loadFirstPage();
    });
  }

  Future<void> _loadMore() async {
    final offset = _nextOffset;
    if (offset == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await _api.fetchPage(offset: offset);
      if (!mounted) return;
      final knownIds = _animes.map((anime) => anime.id).toSet();
      setState(() {
        _animes.addAll(page.items.where((anime) => !knownIds.contains(anime.id)));
        _nextOffset = page.nextOffset;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.message,
        action: SnackBarAction(label: 'Tentar novamente', onPressed: _loadMore),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showMessage('Digite o nome de um anime para buscar.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);
    try {
      final anime = await _api.searchFirst(query);
      if (!mounted) return;
      if (anime == null) {
        _showMessage('Nenhum anime encontrado para "$query".');
        return;
      }
      _openDetail(anime);
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _openDetail(Anime anime) => DetailScreen.open(context, anime);

  void _openSuggestion(Anime anime) {
    _searchFocusNode.unfocus();
    _openDetail(anime);
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  Future<void> _logout() => context.read<AuthProvider>().logout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Animes'),
        actions: [
          IconButton(
            tooltip: 'Ver favoritos',
            icon: const Icon(Icons.star_outline),
            onPressed: () => _push(const FavoritesScreen()),
          ),
          IconButton(
            tooltip: 'Ver animes assistidos',
            icon: const Icon(Icons.task_alt),
            onPressed: () => _push(const WatchedScreen()),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          Expanded(
            child: FutureBuilder<void>(
              future: _initialLoad,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Carregando animes...');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    message: ApiException.describe(snapshot.error),
                    onRetry: _retryFirstPage,
                  );
                }
                if (_animes.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off,
                    message: 'Nenhum anime disponível no momento.',
                  );
                }
                return AnimeGrid(
                  animes: _animes,
                  onTap: _openDetail,
                  footer: _buildFooter(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final field = AnimeSearchField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      loadSuggestions: _api.searchSuggestions,
      onSubmitted: _search,
      onSuggestionSelected: _openSuggestion,
    );
    final button = ElevatedButton(
      onPressed: _isSearching ? null : _search,
      style: ElevatedButton.styleFrom(minimumSize: const Size(96, 56)),
      child: _isSearching
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                semanticsLabel: 'Buscando anime',
              ),
            )
          : const Text('Buscar'),
    );
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: isLargeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [field, const SizedBox(height: 8), button],
            )
          : Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: 12),
                button,
              ],
            ),
    );
  }

  Widget _buildFooter() {
    final Widget content = _nextOffset == null
        ? const Text(
            'Você chegou ao fim do catálogo.',
            textAlign: TextAlign.center,
          )
        : _isLoadingMore
            ? const CircularProgressIndicator(
                semanticsLabel: 'Carregando mais animes',
              )
            : ElevatedButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Carregar Mais'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
              );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Center(child: content),
    );
  }
}
