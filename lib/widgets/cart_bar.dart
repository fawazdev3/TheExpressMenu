import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// -----------------------------------------------------------------------------
/// Barre de panier fixe en bas de l'écran (vue client).
/// Affiche le nombre d'articles et le total, avec un bouton « Commander ».
/// Elle disparaît complètement quand le panier est vide.
/// -----------------------------------------------------------------------------
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.nombreArticles,
    required this.total,
    required this.onCommander,
  });

  /// Nombre total d'articles dans le panier.
  final int nombreArticles;

  /// Total du panier en FCFA.
  final int total;

  /// Callback du bouton « Commander » (ouvre l'écran de commande).
  final VoidCallback onCommander;

  @override
  Widget build(BuildContext context) {
    // Rien à afficher si le panier est vide.
    if (nombreArticles == 0) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '$nombreArticles ${pluriel(nombreArticles, 'article')}',
                      style: const TextStyle(
                        color: AppTheme.grisChaud,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFcfa(total),
                      style: const TextStyle(
                        color: AppTheme.terracotta,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onCommander,
                icon: const Icon(Icons.receipt_long, size: 20),
                label: const Text('Commander'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
