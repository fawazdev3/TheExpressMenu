import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// -----------------------------------------------------------------------------
/// Écran d'état vide : illustré, rassurant, avec un message centré.
/// Utilisé quand le restaurant n'a aucune commande à afficher.
/// -----------------------------------------------------------------------------
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.titre,
    required this.message,
  });

  /// Illustration (emojis, pour rester cohérent avec le reste de la démo).
  final String emoji;

  /// Titre court, ex : "Aucune commande pour le moment".
  final String titre;

  /// Précision affichée sous le titre.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 20),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisChaud,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
