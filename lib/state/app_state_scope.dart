import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// -----------------------------------------------------------------------------
/// DIFFUSION DE L'ÉTAT GLOBAL
/// -----------------------------------------------------------------------------
/// Rôle équivalent à `provider` : rend l'instance d'`[AppState]` accessible à
/// tout le widget situé en dessous, et reconstruit automatiquement les widgets
/// qui l'ont lu lorsqu'une commande est créée ou qu'un statut change.
///
/// Deux modes de lecture :
///   - `[watch]` : dans `build()`, pour afficher l'état (la vue se reconstruit).
///   - `[read]`  : dans un callback (bouton, onChanged), pour déclencher une
///                 action sans créer de dépendance de reconstruction.
/// -----------------------------------------------------------------------------
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  /// Lecture réactive — à utiliser dans `build()`.
  static AppState watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope est introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }

  /// Lecture non réactive — à utiliser dans les gestionnaires d'événements.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope est introuvable dans l\'arbre de widgets.');
    return scope!.notifier!;
  }
}
