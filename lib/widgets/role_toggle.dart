import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// -----------------------------------------------------------------------------
/// Bouton de bascule entre les deux vues de la démo :
/// « Vue client » (commander) et « Vue restaurant » (gérer les commandes).
/// Situé en haut de l'écran d'accueil, il permet de montrer les deux rôles
/// depuis un seul téléphone, sans authentification.
/// -----------------------------------------------------------------------------
class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.index,
    required this.onChanged,
    this.compteurCommandes = 0,
  });

  /// Index de la vue sélectionnée (0 = client, 1 = restaurant).
  final int index;

  /// Callback appelé avec le nouvel index.
  final ValueChanged<int> onChanged;

  /// Nombre de commandes à traiter, affiché en pastille sur l'onglet restaurant.
  final int compteurCommandes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int>(
        segments: <ButtonSegment<int>>[
          const ButtonSegment<int>(
            value: 0,
            label: Text('Vue client'),
            icon: Icon(Icons.restaurant_menu, size: 18),
          ),
          ButtonSegment<int>(
            value: 1,
            label: const Text('Vue restaurant'),
            icon: Badge(
              isLabelVisible: compteurCommandes > 0,
              label: Text('$compteurCommandes'),
              backgroundColor: AppTheme.orange,
              child: const Icon(Icons.storefront, size: 18),
            ),
          ),
        ],
        selected: <int>{index},
        onSelectionChanged: (selection) => onChanged(selection.first),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
          // Ce style REMPLACE le style ambiant : la famille doit être indiquée,
          // sinon les libellés de la bascule n'utiliseraient pas Poppins.
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(
              fontFamily: AppTheme.police,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
