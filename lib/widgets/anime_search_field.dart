import 'package:flutter/material.dart';

import '../models/anime.dart';
import '../models/anime_labels.dart';
import '../services/api_exception.dart';
import 'anime_poster.dart';

class AnimeSearchField extends StatefulWidget {
  const AnimeSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.loadSuggestions,
    required this.onSubmitted,
    required this.onSuggestionSelected,
  });

  static const minQueryLength = 2;
  static const debounce = Duration(milliseconds: 350);

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<List<Anime>> Function(String query) loadSuggestions;
  final VoidCallback onSubmitted;
  final ValueChanged<Anime> onSuggestionSelected;

  @override
  State<AnimeSearchField> createState() => _AnimeSearchFieldState();
}

class _AnimeSearchFieldState extends State<AnimeSearchField> {
  int _latestRequest = 0;

  Future<Iterable<Anime>> _suggestionsFor(TextEditingValue value) async {
    final query = value.text.trim();
    final request = ++_latestRequest;
    if (query.length < AnimeSearchField.minQueryLength) return const [];
    await Future<void>.delayed(AnimeSearchField.debounce);
    if (request != _latestRequest) return const [];
    try {
      return await widget.loadSuggestions(query);
    } on ApiException {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<Anime>(
        textEditingController: widget.controller,
        focusNode: widget.focusNode,
        displayStringForOption: (anime) => anime.title,
        optionsBuilder: _suggestionsFor,
        onSelected: widget.onSuggestionSelected,
        fieldViewBuilder: (context, controller, focusNode, _) => TextField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => widget.onSubmitted(),
          decoration: const InputDecoration(
            labelText: 'Buscar anime pelo nome',
            hintText: 'Ex.: One Piece',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        optionsViewBuilder: (context, onSelected, options) => _SuggestionList(
          width: constraints.maxWidth,
          options: options.toList(growable: false),
          onSelected: onSelected,
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.width,
    required this.options,
    required this.onSelected,
  });

  final double width;
  final List<Anime> options;
  final ValueChanged<Anime> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final anime = options[index];
                return ListTile(
                  leading: ExcludeSemantics(
                    child: SizedBox(
                      width: 40,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimePoster(url: anime.posterUrl, title: anime.title),
                      ),
                    ),
                  ),
                  title: Text(
                    anime.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(anime.typeLabel),
                  onTap: () => onSelected(anime),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
