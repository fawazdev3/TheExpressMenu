import 'package:flutter/material.dart';

import '../../models/menu_item.dart';
import '../../state/app_state_scope.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/menu_item_card.dart';
import 'checkout_screen.dart';

/// -----------------------------------------------------------------------------
/// VUE CLIENT — la carte du restaurant
/// -----------------------------------------------------------------------------
/// Liste les articles du menu avec leur prix en FCFA et un bouton d'ajout.
/// Une barre de panier fixe en bas affiche le nombre d'articles et le total,
/// et mène à l'écran de commande. La barre n'apparaît que si le panier
/// contient au moins un article.
/// -----------------------------------------------------------------------------
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lecture réactive : la liste et la barre de panier se reconstruisent
    // automatiquement à chaque ajout ou retrait d'article.
    final state = AppStateScope.watch(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notre carte')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: <Widget>[
          // Bandeau d'information sur les conditions de commande.
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cremeClair,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Text('🛵', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Commande à emporter ou en livraison.\nPaiement au retrait / à la réception.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisChaud,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...state.menu.map(
            (MenuItem item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MenuItemCard(
                emoji: item.emoji,
                nom: item.nom,
                prix: item.prix,
                quantite: state.quantiteDansPanier(item.id),
                onAjouter: () => AppStateScope.read(context).ajouterAuPanier(item),
                onIncrementer: () => AppStateScope.read(context).incrementer(item.id),
                onDecrementer: () => AppStateScope.read(context).decrementer(item.id),
              ),
            ),
          ),
        ],
      ),
      // Barre fixe en bas : nombre d'articles + total + bouton Commander.
      bottomNavigationBar: CartBar(
        nombreArticles: state.nombreArticles,
        total: state.totalPanier,
        onCommander: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
        ),
      ),
    );
  }
}
