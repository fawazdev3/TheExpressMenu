import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// -----------------------------------------------------------------------------
/// Carte d'un article du menu : emoji, nom, prix en FCFA et bouton d'ajout.
/// Si l'article est déjà dans le panier, la carte affiche un compteur
/// « - 2 + » à la place du bouton d'ajout.
/// -----------------------------------------------------------------------------
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({
    super.key,
    required this.emoji,
    required this.nom,
    required this.prix,
    required this.quantite,
    required this.onAjouter,
    required this.onIncrementer,
    required this.onDecrementer,
  });

  /// Emoji de l'article (joue le rôle de photo).
  final String emoji;

  /// Nom de l'article.
  final String nom;

  /// Prix unitaire en FCFA.
  final int prix;

  /// Quantité déjà présente dans le panier (0 = pas encore ajouté).
  final int quantite;

  /// Ajoute une unité au panier.
  final VoidCallback onAjouter;

  /// Ajoute une unité de plus (quand l'article est déjà dans le panier).
  final VoidCallback onIncrementer;

  /// Retire une unité du panier.
  final VoidCallback onDecrementer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dansPanier = quantite > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFDF1E7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    nom,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatFcfa(prix),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!dansPanier)
              FilledButton(
                onPressed: onAjouter,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Ajouter'),
              )
            else
              _QuantiteStepper(
                quantite: quantite,
                onIncrementer: onIncrementer,
                onDecrementer: onDecrementer,
              ),
          ],
        ),
      ),
    );
  }
}

/// Petit compteur « - 2 + » affiché quand l'article est dans le panier.
class _QuantiteStepper extends StatelessWidget {
  const _QuantiteStepper({
    required this.quantite,
    required this.onIncrementer,
    required this.onDecrementer,
  });

  final int quantite;
  final VoidCallback onIncrementer;
  final VoidCallback onDecrementer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF1E7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            onPressed: onDecrementer,
            icon: const Icon(Icons.remove, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Retirer un article',
            color: AppTheme.orange,
          ),
          Text(
            '$quantite',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF2E1B12),
            ),
          ),
          IconButton(
            onPressed: onIncrementer,
            icon: const Icon(Icons.add, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Ajouter un article',
            color: AppTheme.orange,
          ),
        ],
      ),
    );
  }
}
