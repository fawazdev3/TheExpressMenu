import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// -----------------------------------------------------------------------------
/// Ligne de récapitulatif : emoji, nom, quantité et total de la ligne.
/// Réutilisée dans l'écran de commande (avec ajustement des quantités) et
/// dans la carte de commande côté restaurant (en lecture seule).
/// -----------------------------------------------------------------------------
class RecapLigne extends StatelessWidget {
  const RecapLigne({
    super.key,
    required this.ligne,
    this.onIncrementer,
    this.onDecrementer,
  });

  /// Ligne de commande à afficher.
  final OrderLine ligne;

  /// Si les deux callbacks sont fournis, des boutons +/- sont affichés.
  final VoidCallback? onIncrementer;

  /// Retrait d'une unité.
  final VoidCallback? onDecrementer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifiable = onIncrementer != null && onDecrementer != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          Text(ligne.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  ligne.nom,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${ligne.quantite} × ${formatFcfa(ligne.prixUnitaire)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisChaud,
                  ),
                ),
              ],
            ),
          ),
          if (modifiable) ...<Widget>[
            IconButton(
              onPressed: onDecrementer,
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              color: AppTheme.orange,
              visualDensity: VisualDensity.compact,
              tooltip: 'Retirer un exemplaire',
            ),
            Text(
              '${ligne.quantite}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            IconButton(
              onPressed: onIncrementer,
              icon: const Icon(Icons.add_circle_outline, size: 22),
              color: AppTheme.terracotta,
              visualDensity: VisualDensity.compact,
              tooltip: 'Ajouter un exemplaire',
            ),
            const SizedBox(width: 6),
          ],
          // Le prix reste visible même si le nom de l'article est très long.
          Flexible(
            child: Text(
              formatFcfa(ligne.totalLigne),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
