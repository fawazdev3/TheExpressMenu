/// -----------------------------------------------------------------------------
/// MODÈLE : MenuItem
/// -----------------------------------------------------------------------------
/// Représente un article du menu du restaurant.
///
/// Les prix sont des **entiers en FCFA** (le Franc CFA n'utilise pas de
/// centimes, un `double` serait source d'erreurs d'arrondi).
///
/// BRANCHEMENT API (Django REST) :
///   Les noms de champs correspondent exactement à ceux d'un
///   `serializers.ModelSerializer` sur un modèle `MenuItem(id, nom, prix, emoji)`.
///   Il suffira de remplacer `MenuItem.menuDemo` par un appel HTTP :
///
///     final reponse = await http.get(Uri.parse('$baseUrl/api/menu/'));
///     final data = jsonDecode(reponse.body) as List<dynamic>;
///     return data.cast<Map<String, dynamic>>().map(MenuItem.fromJson).toList();
///
///   Aucun autre fichier de l'app n'a besoin d'être modifié.
/// -----------------------------------------------------------------------------
class MenuItem {
  const MenuItem({
    required this.id,
    required this.nom,
    required this.prix,
    required this.emoji,
  });

  /// Identifiant unique et stable (ex : "item-1"). Sert de clé pour le panier.
  final String id;

  /// Nom affiché au client (ex : "Poulet braisé + frites").
  final String nom;

  /// Prix unitaire en FCFA.
  final int prix;

  /// Emoji utilisé comme "photo" de l'article (évite de gérer des fichiers image).
  final String emoji;

  // --- Sérialisation ----------------------------------------------------------

  /// Construit un article à partir de la réponse JSON de l'API.
  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'].toString(),
    nom: json['nom'] as String? ?? '',
    // `prix` peut arriver en int, en double (2500.0) ou en String selon le backend.
    prix: _versEntier(json['prix']),
    emoji: json['emoji'] as String? ?? '🍽️',
  );

  /// Convertit l'article en JSON (utile pour les tests et le cache local).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'nom': nom,
    'prix': prix,
    'emoji': emoji,
  };

  @override
  bool operator ==(Object other) => identical(this, other) || other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MenuItem($id, $nom, $prix FCFA)';

  static int _versEntier(Object? valeur) {
    if (valeur is int) return valeur;
    if (valeur is num) return valeur.round();
    return int.tryParse(valeur?.toString() ?? '') ?? 0;
  }

  /// ---------------------------------------------------------------------------
  /// DONNÉES MOCK : le menu du restaurant « Le Menu Express ».
  /// Remplacer par la liste renvoyée par l'API Django.
  /// ---------------------------------------------------------------------------
  static const List<MenuItem> menuDemo = <MenuItem>[
    MenuItem(id: 'item-1', nom: 'Poulet braisé + frites', prix: 2500, emoji: '🍗'),
    MenuItem(id: 'item-2', nom: 'Attiéké poisson', prix: 2000, emoji: '🐟'),
    MenuItem(id: 'item-3', nom: 'Riz sauce arachide', prix: 1500, emoji: '🍚'),
    MenuItem(id: 'item-4', nom: 'Burger maison', prix: 2200, emoji: '🍔'),
    MenuItem(id: 'item-5', nom: 'Jus de gingembre', prix: 500, emoji: '🥤'),
  ];
}
