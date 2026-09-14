import 'package:flutter/material.dart';

class AnimePoster extends StatelessWidget {
  const AnimePoster({super.key, required this.url, required this.title});

  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _PosterPlaceholder(title: title);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      semanticLabel: 'Pôster de $title',
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest);
      },
      errorBuilder: (context, error, stackTrace) => _PosterPlaceholder(title: title),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: 'Imagem indisponível para $title',
      child: ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
