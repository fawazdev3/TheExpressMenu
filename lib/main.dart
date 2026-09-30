import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'theme/app_theme.dart';

/// -----------------------------------------------------------------------------
/// Le Menu Express — démonstration de commande en ligne
/// -----------------------------------------------------------------------------
/// Démarrage de l'application :
///   1. création de l'état global en mémoire (`AppState`, avec le menu mock) ;
///   2. diffusion de cet état à toute l'arborescence via `AppStateScope` ;
///   3. affichage de l'écran d'accueil, qui porte la bascule Vue client /
///      Vue restaurant.
///
/// Aucune dépendance externe, aucun appel réseau : tout est local à la démo.
/// -----------------------------------------------------------------------------
void main() {
  runApp(const LeMenuExpressApp());
}

class LeMenuExpressApp extends StatelessWidget {
  const LeMenuExpressApp({super.key, this.state});

  /// État injectable : la démo n'en a pas besoin, mais les tests s'en servent
  /// pour afficher directement une commande prête (voir test/widget_test.dart).
  final AppState? state;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      // L'instance créée ici est partagée par tous les écrans et vit tant que
      // l'application est ouverte. (En production : `ChangeNotifierProvider`.)
      state: state ?? AppState(),
      child: MaterialApp(
        title: 'Le Menu Express',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
