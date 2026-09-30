import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/order_card.dart';
import '../../widgets/status_badge.dart';

/// -----------------------------------------------------------------------------
/// VUE RESTAURANT — liste des commandes reçues
/// -----------------------------------------------------------------------------
/// Les commandes sont triées de la plus récente à la plus ancienne. Chaque carte
/// affiche le numéro, le client, les articles, le mode, le total, le statut et
/// les actions correspondant à ce statut :
///
///   nouvelle       -> "Accepter"  / "Refuser"
///   en_preparation -> "Marquer prête"
///   prete          -> "Livrée / Retirée"
///
/// En production, chaque action déclenchera un `PATCH /api/commandes/{id}/`
/// et la liste sera rafraîchie par polling (ou WebSocket) au lieu de l'état local.
/// -----------------------------------------------------------------------------
class RestaurantOrdersScreen extends StatelessWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lecture réactive : la liste se reconstruit à chaque changement de statut
    // et à chaque nouvelle commande créée depuis la vue client.
    final state = AppStateScope.watch(context);
    final commandes = state.commandes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            const Text('Commandes'),
            const SizedBox(width: 8),
            CounterBadge(nombre: state.nombreCommandesEnCours),
          ],
        ),
        actions: <Widget>[
          // Remet la démo à zéro : pratique pour présenter l'app plusieurs fois.
          IconButton(
            onPressed: commandes.isEmpty
                ? null
                : () => _confirmerReinitialisation(context),
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Réinitialiser la démo',
          ),
        ],
      ),
      body: commandes.isEmpty
          ? const EmptyState(
              emoji: '🧾',
              titre: 'Aucune commande pour le moment',
              message:
                  "Les commandes passées depuis la vue client apparaîtront ici "
                  "instantanément.",
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: commandes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final commande = commandes[index];
                return OrderCard(
                  commande: commande,
                  onActionPrincipale: () {
                    // Accepter -> En préparation -> Prête -> Livrée / Retirée
                    AppStateScope.read(context).appliquerActionPrincipale(
                      commande.id,
                    );
                  },
                  onRefuser: () =>
                      _confirmerRefus(context, commande, state),
                  onSupprimer: () =>
                      AppStateScope.read(context).supprimerCommande(commande.id),
                );
              },
            ),
    );
  }

  /// Demande confirmation avant de faire passer une commande en « refusée ».
  Future<void> _confirmerRefus(
    BuildContext context,
    Order commande,
    AppState state,
  ) async {
    final accepter = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Refuser la commande ?'),
        content: Text(
          'La commande ${commande.id} de ${commande.nomClient} sera marquée '
          'comme refusée.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB3261E)),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
    if (accepter ?? false) {
      state.changerStatut(commande.id, OrderStatus.refusee);
    }
  }

  /// Vide la liste des commandes après confirmation.
  Future<void> _confirmerReinitialisation(BuildContext context) async {
    // L'état est récupéré avant l'attente : plus besoin du `context` ensuite.
    final state = AppStateScope.read(context);
    final accepter = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réinitialiser la démo ?'),
        content: const Text(
          'Toutes les commandes (et le panier en cours) seront effacées.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (accepter ?? false) {
      state.reinitialiser();
    }
  }
}
