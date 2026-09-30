import 'menu_item.dart';

/// -----------------------------------------------------------------------------
/// MODÈLE : Order (et ses sous-types)
/// -----------------------------------------------------------------------------
/// Contient tout ce dont l'application a besoin pour afficher une commande,
/// côté client comme côté restaurant.
///
/// BRANCHEMENT API (Django REST) :
///   - `DeliveryMode.apiValue` et `OrderStatus.apiValue` correspondent exactement
///     aux `choices` du modèle Django, donc un simple aller-retour JSON fonctionne.
///   - Une `OrderLine` est volontairement **autonome** (elle duplique nom / prix /
///     emoji) : une commande reste donc affichable même si le menu change ou si
///     un article est supprimé côté back-office. C'est le comportement attendu
///     d'une vraie base de données (ligne de commande figée au moment de l'achat).
/// -----------------------------------------------------------------------------

/// Mode de retrait de la commande.
enum DeliveryMode {
  retrait('Retrait', 'retrait'),
  livraison('Livraison', 'livraison');

  const DeliveryMode(this.libelle, this.apiValue);

  /// Texte affiché dans l'application.
  final String libelle;

  /// Valeur stockée / échangée avec l'API.
  final String apiValue;

  static DeliveryMode depuisApi(String valeur) => DeliveryMode.values.firstWhere(
    (mode) => mode.apiValue == valeur,
    orElse: () => DeliveryMode.retrait,
  );
}

/// Cycle de vie d'une commande, géré par le restaurant.
enum OrderStatus {
  nouvelle('Nouvelle', 'nouvelle'),
  enPreparation('En préparation', 'en_preparation'),
  prete('Prête', 'prete'),
  livreeOuRetiree('Livrée / Retirée', 'livree_ou_retiree'),
  refusee('Refusée', 'refusee');

  const OrderStatus(this.libelle, this.apiValue);

  /// Texte affiché sur le badge de statut.
  final String libelle;

  /// Valeur stockée / échangée avec l'API.
  final String apiValue;

  /// Statut suivant dans le parcours normal (null une fois la commande terminée).
  /// Permet d'implémenter le workflow en une seule ligne côté back-end.
  OrderStatus? get suivant => switch (this) {
    OrderStatus.nouvelle => OrderStatus.enPreparation,
    OrderStatus.enPreparation => OrderStatus.prete,
    OrderStatus.prete => OrderStatus.livreeOuRetiree,
    OrderStatus.livreeOuRetiree || OrderStatus.refusee => null,
  };

  /// Vrai si la commande a atteint un état final (plus aucune action possible).
  bool get estTerminee =>
      this == OrderStatus.livreeOuRetiree || this == OrderStatus.refusee;

  static OrderStatus depuisApi(String valeur) => OrderStatus.values.firstWhere(
    (statut) => statut.apiValue == valeur,
    orElse: () => OrderStatus.nouvelle,
  );
}

/// Une ligne de commande : un article + une quantité.
class OrderLine {
  const OrderLine({
    required this.itemId,
    required this.nom,
    required this.prixUnitaire,
    required this.emoji,
    required this.quantite,
  });

  /// Référence vers l'article du menu (clé étrangère côté Django).
  final String itemId;

  /// Nom figé au moment de la commande.
  final String nom;

  /// Prix unitaire figé au moment de la commande (FCFA).
  final int prixUnitaire;

  /// Emoji figé au moment de la commande.
  final String emoji;

  /// Nombre d'exemplaires commandés.
  final int quantite;

  /// Total de la ligne (prix unitaire × quantité).
  int get totalLigne => prixUnitaire * quantite;

  /// Raccourci pour transformer un article du menu en ligne de commande.
  factory OrderLine.depuisMenuItem(MenuItem item, {int quantite = 1}) => OrderLine(
    itemId: item.id,
    nom: item.nom,
    prixUnitaire: item.prix,
    emoji: item.emoji,
    quantite: quantite,
  );

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    itemId: json['item']?.toString() ?? json['item_id']?.toString() ?? '',
    nom: json['nom'] as String? ?? '',
    prixUnitaire: _versEntier(json['prix_unitaire']),
    emoji: json['emoji'] as String? ?? '🍽️',
    quantite: _versEntier(json['quantite']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item': itemId,
    'nom': nom,
    'prix_unitaire': prixUnitaire,
    'emoji': emoji,
    'quantite': quantite,
  };

  OrderLine copieAvec({int? quantite}) => OrderLine(
    itemId: itemId,
    nom: nom,
    prixUnitaire: prixUnitaire,
    emoji: emoji,
    quantite: quantite ?? this.quantite,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLine && other.itemId == itemId && other.quantite == quantite;

  @override
  int get hashCode => Object.hash(itemId, quantite);

  static int _versEntier(Object? valeur) {
    if (valeur is int) return valeur;
    if (valeur is num) return valeur.round();
    return int.tryParse(valeur?.toString() ?? '') ?? 0;
  }
}

/// Une commande complète.
class Order {
  const Order({
    required this.id,
    required this.nomClient,
    required this.telephone,
    required this.mode,
    required this.adresse,
    required this.articles,
    required this.total,
    required this.statut,
    required this.creeeLe,
  });

  /// Numéro de commande affiché au client (ex : "CMD-001").
  final String id;

  /// Nom du client (champ obligatoire à la commande).
  final String nomClient;

  /// Téléphone du client (permet au restaurant de rappeler).
  final String telephone;

  /// Retrait sur place ou livraison.
  final DeliveryMode mode;

  /// Adresse de livraison — `null` en mode Retrait.
  final String? adresse;

  /// Détail des articles commandés.
  final List<OrderLine> articles;

  /// Total de la commande en FCFA (recalculé par le back-end en production).
  final int total;

  /// Statut courant, modifié par la vue restaurant.
  final OrderStatus statut;

  /// Date de création : sert à trier les commandes, plus récentes en premier.
  final DateTime creeeLe;

  /// Nombre total d'articles (toutes lignes confondues).
  int get nombreArticles =>
      articles.fold(0, (somme, ligne) => somme + ligne.quantite);

  /// Résumé court pour le client : "2 × Poulet braisé + frites, 1 × Jus de gingembre".
  String get resumeArticles =>
      articles.map((ligne) => '${ligne.quantite} × ${ligne.nom}').join(', ');

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'].toString(),
    nomClient: json['nom_client'] as String? ?? '',
    telephone: json['telephone'] as String? ?? '',
    mode: DeliveryMode.depuisApi(json['mode'] as String? ?? 'retrait'),
    adresse: json['adresse'] as String?,
    articles: ((json['articles'] as List<dynamic>?) ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(OrderLine.fromJson)
        .toList(growable: false),
    total: (json['total'] as num?)?.round() ?? 0,
    statut: OrderStatus.depuisApi(json['statut'] as String? ?? 'nouvelle'),
    creeeLe:
        DateTime.tryParse(json['creee_le'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nom_client': nomClient,
    'telephone': telephone,
    'mode': mode.apiValue,
    'adresse': adresse,
    'articles': articles.map((ligne) => ligne.toJson()).toList(),
    'total': total,
    'statut': statut.apiValue,
    'creee_le': creeeLe.toIso8601String(),
  };

  /// Retourne une copie avec un statut modifié (modèle immuable : l'état global
  /// `AppState` se charge de remplacer l'objet dans sa liste).
  Order copieAvec({OrderStatus? statut}) => Order(
    id: id,
    nomClient: nomClient,
    telephone: telephone,
    mode: mode,
    adresse: adresse,
    articles: articles,
    total: total,
    statut: statut ?? this.statut,
    creeeLe: creeeLe,
  );

  @override
  String toString() => 'Order($id, $statut, $total FCFA)';
}
