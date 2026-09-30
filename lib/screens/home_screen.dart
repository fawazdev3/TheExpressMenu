import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../widgets/role_toggle.dart';
import 'client/menu_screen.dart';
import 'restaurant/restaurant_orders_screen.dart';

/// -----------------------------------------------------------------------------
/// ÉCRAN D'ACCUEIL DE LA DÉMO
/// -----------------------------------------------------------------------------
/// Affiche le nom du restaurant et le bouton de bascule entre les deux vues :
///   0 -> Vue client    (parcourir le menu et commander)
///   1 -> Vue restaurant (recevoir et suivre les commandes)
///
/// L'`IndexedStack` conserve l'état des deux vues (position de défilement,
/// texte saisi...) : passer de l'une à l'autre ne détruit rien.
///
/// Aucune authentification dans cette démo : la bascule remplace la connexion
/// et le rôle de l'utilisateur.
/// -----------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Index de la vue affichée : 0 = client, 1 = restaurant.
  int _vue = 0;

  @override
  Widget build(BuildContext context) {
    // Lecture réactive : la pastille de commandes à traiter se met à jour seule.
    final state = AppStateScope.watch(context);

    return Scaffold(
      body: Column(
        children: <Widget>[
          _EnTete(
            indexVue: _vue,
            commandesATraiter: state.nombreCommandesEnCours,
            onVueChangee: (index) => setState(() => _vue = index),
          ),
          Expanded(
            child: IndexedStack(
              index: _vue,
              children: const <Widget>[MenuScreen(), RestaurantOrdersScreen()],
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête commun : identité du restaurant + bascule de vue.
class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.indexVue,
    required this.onVueChangee,
    required this.commandesATraiter,
  });

  final int indexVue;
  final ValueChanged<int> onVueChangee;
  final int commandesATraiter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                // Logo officiel « Le Menu Express » (assiette + texte intégré).
                // Il remplace l'emoji de démonstration. Taille volontairement
                // modeste : le nom reste écrit en texte juste à côté, donc la
                // marque reste lisible même quand le logo est réduit.
                Image.asset(
                  'assets/images/logo-menu-express.png',
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  semanticLabel: 'Logo Le Menu Express',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Le Menu Express',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Cuisine maison • retrait ou livraison',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7A6A60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            RoleToggle(
              index: indexVue,
              onChanged: onVueChangee,
              compteurCommandes: commandesATraiter,
            ),
          ],
        ),
      ),
    );
  }
}
