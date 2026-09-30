import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// -----------------------------------------------------------------------------
/// VUE CLIENT — écran de confirmation
/// -----------------------------------------------------------------------------
/// Affiche le numéro de commande généré et un message de confirmation, puis
/// permet de revenir au menu. Le client n'a rien à payer ici (démo sans
/// paiement) : le restaurant rappelle simplement ce numéro.
/// -----------------------------------------------------------------------------
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.commande});

  /// Commande qui vient d'être créée.
  final Order commande;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: <Widget>[
            const Center(child: Text('🎉', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 20),
            Text(
              'Commande confirmée !',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Merci ${commande.nomClient}, nous avons bien reçu votre commande.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisChaud,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Numéro de commande : à conserver / à communiquer au restaurant.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Votre numéro de commande',
                      style: TextStyle(
                        color: AppTheme.grisChaud,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      commande.id,
                      style: const TextStyle(
                        color: AppTheme.terracotta,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      commande.mode == DeliveryMode.livraison
                          ? 'Livraison prévue à : ${commande.adresse}'
                          : 'Retrait au restaurant • ${commande.resumeArticles}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisChaud,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Rappel de la commande passée.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Récapitulatif',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...commande.articles.map(
                      (ligne) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: <Widget>[
                            Text(
                              '${ligne.quantite} ×',
                              style: const TextStyle(
                                color: AppTheme.grisChaud,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ligne.nom,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                formatFcfa(ligne.totalLigne),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            formatFcfa(commande.total),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.terracotta,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Le restaurant a reçu votre commande et vous rappellera au '
              '${commande.telephone} pour finaliser.${commande.adresse == null ? '' : '\nLivraison à : ${commande.adresse}.'}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisChaud,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      // Barre fixe du bas : l'action principale reste visible sans défilement.
      bottomNavigationBar: _barreRetour(context),
    );
  }

  /// Barre du bas : bouton de retour au menu.
  Widget _barreRetour(BuildContext context) => Material(
    color: Colors.white,
    elevation: 12,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            // On dépile les écrans (commande -> confirmation) pour revenir au menu.
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.restaurant_menu, size: 20),
            label: const Text('Retour au menu'),
          ),
        ),
      ),
    ),
  );
}
