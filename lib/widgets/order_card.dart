import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'status_badge.dart';

/// -----------------------------------------------------------------------------
/// Carte d'une commande reçue, affichée dans la vue restaurant.
/// Contient le numéro, le client, les articles, le mode, le total, le badge de
/// statut et les boutons d'action correspondant au statut courant.
///
/// Logique des actions (à traduire en PATCH /api/commandes/{id}/ côté Django) :
///   nouvelle          -> "Accepter" (en_preparation) | "Refuser" (refusee)
///   en_preparation    -> "Marquer prête" (prete)
///   prete             -> "Livrée / Retirée" (livree_ou_retiree)
///   livree_ou_retiree -> rien (commande clôturée)
///   refusee           -> rien, avec possibilité de la retirer de la liste
/// -----------------------------------------------------------------------------
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.commande,
    required this.onActionPrincipale,
    required this.onRefuser,
    required this.onSupprimer,
  });

  /// Commande à afficher.
  final Order commande;

  /// Accepter / Marquer prête / Livrée : fait avancer le statut.
  final VoidCallback onActionPrincipale;

  /// Refuser une commande (« nouvelle » -> « refusee »).
  final VoidCallback onRefuser;

  /// Retire définitivement la commande de la liste.
  final VoidCallback onSupprimer;

  /// Libellé du bouton d'action principal, dépendant du statut.
  String get _libelleAction => switch (commande.statut) {
    OrderStatus.nouvelle => 'Accepter',
    OrderStatus.enPreparation => 'Marquer prête',
    OrderStatus.prete => 'Livrée / Retirée',
    OrderStatus.livreeOuRetiree || OrderStatus.refusee => '',
  };

  IconData get _iconeAction => switch (commande.statut) {
    OrderStatus.nouvelle => Icons.check,
    OrderStatus.enPreparation => Icons.soup_kitchen_outlined,
    OrderStatus.prete => Icons.delivery_dining,
    OrderStatus.livreeOuRetiree || OrderStatus.refusee => Icons.done,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- En-tête : numéro, heure, badge de statut -----------------------
            // `Wrap` (et non `Row`) : si le badge est large (« En préparation »),
            // il passe à la ligne suivante au lieu de déborder de l'écran.
            Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  commande.id,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.terracotta,
                  ),
                ),
                Text(
                  heure(commande.creeeLe),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisChaud,
                  ),
                ),
                StatusBadge(statut: commande.statut),
              ],
            ),
            const SizedBox(height: 10),

            // --- Client : nom + téléphone ---------------------------------------
            Row(
              children: <Widget>[
                const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: AppTheme.grisChaud,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    commande.nomClient,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.phone_iphone,
                  size: 16,
                  color: AppTheme.grisChaud,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    commande.telephone,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grisChaud,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // --- Mode de retrait (+ adresse si livraison) ------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  commande.mode == DeliveryMode.livraison
                      ? Icons.delivery_dining
                      : Icons.shopping_bag_outlined,
                  size: 18,
                  color: AppTheme.grisChaud,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    commande.adresse == null
                        ? commande.mode.libelle
                        : '${commande.mode.libelle} • ${commande.adresse}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.grisChaud,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            // --- Détail des articles commandés ----------------------------------
            ...commande.articles.map(
              (ligne) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: <Widget>[
                    Text(ligne.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ligne.quantite} × ${ligne.nom}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formatFcfa(ligne.totalLigne),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 18),

            // --- Total -----------------------------------------------------------
            Row(
              children: <Widget>[
                Text(
                  'Total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisChaud,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    formatFcfa(commande.total),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.terracotta,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _actions(context),
          ],
        ),
      ),
    );
  }

  /// Zone de boutons, adaptée au statut courant.
  Widget _actions(BuildContext context) {
    // Commande terminée : plus rien à faire, on affiche seulement l'information.
    if (commande.statut.estTerminee) {
      return Row(
        children: <Widget>[
          Icon(
            commande.statut == OrderStatus.refusee
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            size: 18,
            color: AppTheme.grisChaud,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              commande.statut == OrderStatus.refusee
                  ? 'Commande refusée par le restaurant'
                  : 'Commande clôturée',
              style: const TextStyle(
                color: AppTheme.grisChaud,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Permet de sortir les anciennes commandes de l'écran de démonstration.
          IconButton(
            onPressed: onSupprimer,
            icon: const Icon(Icons.delete_outline, size: 20),
            visualDensity: VisualDensity.compact,
            color: AppTheme.grisChaud,
            tooltip: 'Retirer de la liste',
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        // L'action principale occupe toute la largeur restante.
        Expanded(
          child: FilledButton.icon(
            onPressed: onActionPrincipale,
            icon: Icon(_iconeAction, size: 18),
            label: Text(_libelleAction),
          ),
        ),
        if (commande.statut == OrderStatus.nouvelle) ...<Widget>[
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onRefuser,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB3261E),
              side: const BorderSide(color: Color(0xFFE3B5B1)),
              minimumSize: const Size(0, 48),
            ),
            child: const Text('Refuser'),
          ),
        ],
      ],
    );
  }

  /// Heure de la commande au format 14:35.
  static String heure(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
