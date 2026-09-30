import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

/// -----------------------------------------------------------------------------
/// Badge coloré indiquant le statut d'une commande.
/// Une couleur par étape du workflow : orange = à traiter, bleu = en cours,
/// vert = prêt, vert foncé = terminé, rouge = refusé.
/// -----------------------------------------------------------------------------
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.statut});

  /// Statut à afficher.
  final OrderStatus statut;

  /// Couleurs (fond / texte) associées à chaque statut.
  ({Color fond, Color texte}) get _couleurs => switch (statut) {
    OrderStatus.nouvelle => (fond: const Color(0xFFFFF1DF), texte: const Color(0xFFB2620C)),
    OrderStatus.enPreparation => (fond: const Color(0xFFE7F0FC), texte: const Color(0xFF1D5FB0)),
    OrderStatus.prete => (fond: const Color(0xFFE3F6E9), texte: const Color(0xFF1E7A45)),
    OrderStatus.livreeOuRetiree => (fond: const Color(0xFFE2F1EE), texte: const Color(0xFF14655C)),
    OrderStatus.refusee => (fond: const Color(0xFFFCE8E6), texte: const Color(0xFFB3261E)),
  };

  @override
  Widget build(BuildContext context) {
    final couleurs = _couleurs;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: couleurs.fond,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: couleurs.texte,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statut.libelle,
            style: TextStyle(
              color: couleurs.texte,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « n nouvelles commandes » affiché en haut de la vue restaurant.
class CounterBadge extends StatelessWidget {
  const CounterBadge({super.key, required this.nombre});

  final int nombre;

  @override
  Widget build(BuildContext context) {
    if (nombre <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.terracotta,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$nombre',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
