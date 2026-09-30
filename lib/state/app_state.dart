import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import '../models/order.dart';

/// -----------------------------------------------------------------------------
/// ÉTAT GLOBAL DE LA DÉMO (ChangeNotifier)
/// -----------------------------------------------------------------------------
/// Unique source de vérité de l'application : elle contient le menu, le panier
/// du client et les commandes reçues par le restaurant. **Tout est en mémoire** :
/// rien n'est persisté, tout est perdu à la fermeture de l'application.
///
/// Choix technique : `ChangeNotifier` + `InheritedNotifier` (voir
/// `app_state_scope.dart`) plutôt que le package `provider` ou Riverpod.
/// C'est le mécanisme natif de Flutter, donc aucune dépendance à ajouter et
/// `flutter run` fonctionne immédiatement. Si un jour Riverpod est souhaité, seul
/// `AppState` est à réécrire : les écrans ne font qu'appeler ses méthodes.
///
/// BRANCHEMENT API (Django REST) :
///   Ce fichier est LE SEUL à modifier pour passer en production.
///   - `MenuItem.menuDemo` -> GET /api/menu/
///   - `creerCommande`     -> POST /api/commandes/
///   - `changerStatut`     -> PATCH /api/commandes/{id}/
///   - `reinitialiser`     -> DELETE /api/commandes/ (utile pour la démo)
/// -----------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  AppState({List<MenuItem>? menu})
    : _menu = List<MenuItem>.of(menu ?? MenuItem.menuDemo);

  /// Menu du restaurant (données mock pour l'instant).
  final List<MenuItem> _menu;

  /// Index du menu par identifiant : accès rapide lors du calcul du panier.
  late final Map<String, MenuItem> _menuParId = <String, MenuItem>{
    for (final item in _menu) item.id: item,
  };

  /// Panier du client : identifiant de l'article -> quantité.
  final Map<String, int> _panier = <String, int>{};

  /// Commandes reçues, dans l'ordre de création (la plus récente en tête).
  final List<Order> _commandes = <Order>[];

  /// Compteur servant à générer les numéros de commande ("CMD-001"...).
  int _compteurCommande = 0;

  // ===========================================================================
  // MENU
  // ===========================================================================

  List<MenuItem> get menu => List<MenuItem>.unmodifiable(_menu);

  // ===========================================================================
  // PANIER (vue client)
  // ===========================================================================

  /// Copie en lecture seule du panier (identifiant -> quantité).
  Map<String, int> get panier => Map<String, int>.unmodifiable(_panier);

  /// Nombre total d'articles dans le panier (toutes lignes confondues).
  int get nombreArticles =>
      _panier.values.fold(0, (somme, quantite) => somme + quantite);

  /// Vrai si aucun article n'a été ajouté.
  bool get panierVide => _panier.isEmpty;

  /// Le panier converti en lignes de commande (utilisé par le récapitulatif).
  List<OrderLine> get lignesPanier => _panier.entries
      .map((entree) {
        final item = _menuParId[entree.key];
        return item == null
            ? null
            : OrderLine.depuisMenuItem(item, quantite: entree.value);
      })
      .whereType<OrderLine>()
      .toList(growable: false);

  /// Total du panier en FCFA.
  int get totalPanier =>
      lignesPanier.fold(0, (somme, ligne) => somme + ligne.totalLigne);

  /// Quantité d'un article précis dans le panier (0 si absent).
  int quantiteDansPanier(String itemId) => _panier[itemId] ?? 0;

  /// Ajoute une unité d'un article au panier.
  void ajouterAuPanier(MenuItem item) {
    _panier[item.id] = (_panier[item.id] ?? 0) + 1;
    notifyListeners();
  }

  /// Incrémente / décrémente la quantité d'un article. À 0, l'article est retiré.
  void changerQuantite(String itemId, int quantite) {
    if (quantite <= 0) {
      _panier.remove(itemId);
    } else {
      _panier[itemId] = quantite;
    }
    notifyListeners();
  }

  void incrementer(String itemId) =>
      changerQuantite(itemId, quantiteDansPanier(itemId) + 1);

  void decrementer(String itemId) =>
      changerQuantite(itemId, quantiteDansPanier(itemId) - 1);

  /// Vide entièrement le panier.
  void viderPanier() {
    if (_panier.isEmpty) return;
    _panier.clear();
    notifyListeners();
  }

  // ===========================================================================
  // COMMANDES (vue restaurant)
  // ===========================================================================

  /// Toutes les commandes, **plus récentes en premier**.
  List<Order> get commandes {
    final triees = List<Order>.of(_commandes)
      ..sort((a, b) => b.creeeLe.compareTo(a.creeeLe));
    return List<Order>.unmodifiable(triees);
  }

  /// Commandes sur lesquelles le restaurant doit encore agir.
  List<Order> get commandesEnCours =>
      commandes.where((commande) => !commande.statut.estTerminee).toList();

  /// Nombre de commandes « en cours » (affiché en en-tête de la vue restaurant).
  int get nombreCommandesEnCours => commandesEnCours.length;

  /// Vrai si la commande demandée existe encore dans la liste.
  bool existe(String id) => _commandes.any((commande) => commande.id == id);

  /// ---------------------------------------------------------------------------
  /// Valide le panier en cours et crée une commande au statut « nouvelle ».
  /// Retourne la commande créée pour l'afficher sur l'écran de confirmation.
  /// (Avec une vraie API : `POST /api/commandes/` puis lecture de la réponse.)
  /// ---------------------------------------------------------------------------
  Order creerCommande({
    required String nomClient,
    required String telephone,
    required DeliveryMode mode,
    String? adresse,
  }) {
    final commande = Order(
      id: _genererId(),
      nomClient: nomClient,
      telephone: telephone,
      mode: mode,
      // L'adresse n'a de sens qu'en livraison.
      adresse: mode == DeliveryMode.livraison ? adresse : null,
      articles: lignesPanier,
      total: totalPanier,
      statut: OrderStatus.nouvelle,
      creeeLe: DateTime.now(),
    );

    _commandes.insert(0, commande);
    _compteurCommande++;
    // Le panier est vidé : le client ne peut pas commander deux fois le même panier.
    _panier.clear();
    notifyListeners();
    return commande;
  }

  /// Fait avancer (ou reculer) le statut d'une commande.
  void changerStatut(String id, OrderStatus statut) {
    final index = _commandes.indexWhere((commande) => commande.id == id);
    if (index == -1) return;
    _commandes[index] = _commandes[index].copieAvec(statut: statut);
    notifyListeners();
  }

  /// Applique l'action principale correspondant au statut
  /// (Accepter -> en préparation -> prête -> livrée).
  void appliquerActionPrincipale(String id) {
    Order? commande;
    for (final candidate in _commandes) {
      if (candidate.id == id) {
        commande = candidate;
        break;
      }
    }
    final suivant = commande?.statut.suivant;
    if (commande != null && suivant != null) {
      changerStatut(id, suivant);
    }
  }

  /// Supprime définitivement une commande de la liste.
  void supprimerCommande(String id) {
    _commandes.removeWhere((commande) => commande.id == id);
    notifyListeners();
  }

  /// Remet la démo à zéro (panier vide, aucune commande). Pratique pour
  /// présenter l'app plusieurs fois de suite à un restaurateur.
  void reinitialiser() {
    _commandes.clear();
    _panier.clear();
    _compteurCommande = 0;
    notifyListeners();
  }

  /// Numéro de commande lisible et séquentiel : CMD-001, CMD-002...
  String _genererId() =>
      'CMD-${(_compteurCommande + 1).toString().padLeft(3, '0')}';
}
