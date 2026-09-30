# Le Menu Express — démo de commande en ligne

Application Flutter de démonstration pour un restaurant fictif, **« Le Menu Express »**.
Elle permet de montrer à un restaurateur le principe d'une commande en ligne sur
mobile : le client commande, le restaurant traite la commande étape par étape.

**Tout est en mémoire :** aucun backend, aucun appel réseau, aucune authentification,
aucun paiement. Les données disparaissent à la fermeture de l'application.

## Lancer la démo

```bash
flutter pub get   # aucune dépendance externe : juste la vérification du projet
flutter run       # Android, iOS, Web ou Windows
flutter test      # 20 tests : parcours complet + identité visuelle + logique métier
```

## Identité visuelle

### Police : Poppins

Les quatre graisses fournies sont déclarées dans `pubspec.yaml`
(`Regular` 400, `Medium` 500, `SemiBold` 600, `Bold` 700).
`ThemeData.fontFamily: 'Poppins'` dans `lib/theme/app_theme.dart` en fait la police
par défaut : **aucun `Text` n'a besoin de préciser sa police**, y compris les
styles déjà stylés (barre de titre, boutons, champs de saisie), qui héritent de la
famille du thème.

> Les tests chargent les vrais fichiers `.ttf` (`FontLoader`) : les tests de mise
> page utilisent donc les vraies métriques de Poppins et détecteraient un
> débordement de texte qu'un test avec la police de substitution laisserait passer.

### Logo et icône

| Fichier | Rôle |
| ------- | ---- |
| `assets/images/logo-icone-seule.png` | Source 1024² fournie (assiette + couverts). |
| `assets/images/logo-menu-express.png` | Logo complet 1024², affiché dans l'en-tête (52 × 52). |
| `assets/images/logo-app-icon.png` | Icône **pleine et opaque** 1024², générée (iOS, macOS, Windows, Android legacy, web). |
| `assets/images/logo-icone-foreground.png` | Calque **avant** adaptatif 1024² transparent, généré (Android API 26+). |

Le logo fourni a des angles arrondis transparents et un fond en dégradé, ce qui est
incompatible avec les exigences des plateformes (iOS : icône pleine, Android :
calque avant + fond uni). Le script `tool/generate_app_icons.ps1` produit donc les
deux variantes nécessaires :

- il extrait l'assiette et les couverts sur fond transparent (leur couleur crème
  et brique ne se confond pas avec le dégradé du fond), puis la réduit à **54 % du
  canevas** — elle reste ainsi entière dans la zone sûre des icônes adaptatives
  (66 dp sur 108 dp) et lisible dans la barre des tâches comme en notification ;
- il referme les coins arrondis par extension de bord pour obtenir une icône
  carrée pleine, sans couture visible ;
- il régénère aussi les icônes web (`web/icons/`, `web/favicon.png`), que
  `flutter_launcher_icons` ne traite pas.

**Régénérer après un changement de logo :**

```bash
# 1. remplacer assets/images/logo-icone-seule.png
powershell -ExecutionPolicy Bypass -File tool\generate_app_icons.ps1
# 2. régénérer les icônes de chaque plateforme
dart run flutter_launcher_icons
```

## Fonctionnalités

### Vue client

- Liste du menu : emoji, nom, prix en FCFA, bouton « Ajouter » (puis sélecteur de quantité).
- Barre de panier fixe en bas : nombre d'articles, total et bouton « Commander »
  (masquée tant que le panier est vide).
- Écran de commande : récapitulatif avec ajustement des quantités, nom, téléphone,
  sélecteur Retrait / Livraison, champ **adresse affiché uniquement en Livraison**.
  Le passage en « Livraison » fait défiler l'écran vers le champ adresse.
- Écran de confirmation : numéro de commande, message et bouton « Retour au menu ».

### Vue restaurant

- Liste des commandes reçues, **plus récentes en haut**, avec un compteur de commandes
  à traiter (pastille sur l'onglet de bascule).
- Chaque commande affiche : numéro, heure, nom du client, téléphone, mode (+ adresse),
  articles commandés, total en FCFA et badge de statut coloré.
- Actions selon le statut :

| Statut              | Actions disponibles                          |
| ------------------- | -------------------------------------------- |
| `nouvelle`          | « Accepter » (→ `en_preparation`), « Refuser » (→ `refusee`) |
| `en_preparation`    | « Marquer prête » (→ `prete`)                |
| `prete`             | « Livrée / Retirée » (→ `livree_ou_retiree`) |
| `livree_ou_retiree` | Commande clôturée, bouton de retrait         |
| `refusee`           | Commande refusée, bouton de retrait          |

- Message « Aucune commande pour le moment » si la liste est vide.
- Bouton « Réinitialiser la démo » (⤺) dans la barre du haut pour repartir de zéro.

## Organisation du code

```
lib/
├── main.dart                        Point d'entrée : crée l'état et l'application
├── models/
│   ├── menu_item.dart               MenuItem + données de démonstration
│   └── order.dart                   Order, OrderLine, DeliveryMode, OrderStatus
├── state/
│   ├── app_state.dart               ChangeNotifier : panier + commandes
│   └── app_state_scope.dart         InheritedNotifier (équivalent de Provider)
├── screens/
│   ├── home_screen.dart             En-tête restaurant + bascule Vue client / restaurant
│   ├── client/
│   │   ├── menu_screen.dart         La carte et la barre de panier
│   │   ├── checkout_screen.dart     Récapitulatif + nom / téléphone / mode / adresse
│   │   └── order_confirmation_screen.dart
│   └── restaurant/
│       └── restaurant_orders_screen.dart
├── widgets/                         role_toggle, menu_item_card, cart_bar,
│                                    status_badge, order_card, recap_ligne, empty_state
├── theme/app_theme.dart             Palette terracotta / orange, fond crème
└── utils/format.dart                Formatage des montants (2 500 FCFA)
test/
├── widget_test.dart                 Parcours de bout en bout dans l'interface
└── app_state_test.dart              Logique métier + sérialisation JSON
```

## Gestion d'état

`AppState` (un `ChangeNotifier`) détient le menu, le panier et les commandes.
Il est diffusé à toute l'application par `AppStateScope`, un `InheritedNotifier` :
c'est le mécanisme **natif** de Flutter, équivalent au package `provider` mais sans
dépendance à ajouter. Les écrans lisent l'état avec :

- `AppStateScope.watch(context)` dans `build()` → l'écran se reconstruit tout seul ;
- `AppStateScope.read(context)` dans un bouton → déclenchement d'action.

## Brancher une vraie API Django REST

Les modèles sont **déjà alignés sur la sérialisation Django** : `fromJson` / `toJson`
sont écrits, et `apiValue` reprend exactement les valeurs des `choices` du modèle
(`retrait` / `livraison`, `nouvelle` / `en_preparation` / `prete` / `livree_ou_retiree` / `refusee`).

Exemple de modèle Django attendu :

```python
class LigneCommande(models.Model):
    commande = models.ForeignKey(Commande, related_name="articles", on_delete=models.CASCADE)
    item = models.ForeignKey(MenuItem, on_delete=models.PROTECT)
    nom = models.CharField(max_length=120)          # figé au moment de la commande
    prix_unitaire = models.PositiveIntegerField()    # idem
    emoji = models.CharField(max_length=8, blank=True)
    quantite = models.PositiveIntegerField(default=1)

class Commande(models.Model):
    nom_client = models.CharField(max_length=120)
    telephone = models.CharField(max_length=30)
    mode = models.CharField(max_length=10, choices=[("retrait", "Retrait"), ("livraison", "Livraison")])
    adresse = models.CharField(max_length=255, null=True, blank=True)
    statut = models.CharField(max_length=20, choices=[
        ("nouvelle", "Nouvelle"), ("en_preparation", "En préparation"),
        ("prete", "Prête"), ("livree_ou_retiree", "Livrée / Retirée"), ("refusee", "Refusée"),
    ], default="nouvelle")
    total = models.PositiveIntegerField()
    creee_le = models.DateTimeField(auto_now_add=True)
```

Le plan de branchement, dans l'ordre :

1. **Ajouter la dépendance** `http` dans `pubspec.yaml` (ou `dio`).
2. **`AppState` est le seul fichier à modifier** pour passer en production :
   - `MenuItem.menuDemo` → `GET /api/menu/` (à remplacer par un `FutureBuilder`) ;
   - `creerCommande(...)` → `POST /api/commandes/`, en envoyant
     `{'nom_client': …, 'telephone': …, 'mode': …, 'adresse': …, 'articles': [...]}`.
     **Le total doit être recalculé par le serveur**, jamais par le client ;
   - `changerStatut(id, statut)` → `PATCH /api/commandes/{id}/` avec `{"statut": "…"}` ;
   - `reinitialiser()` → `DELETE /api/commandes/` (facultatif, bouton de démo).
3. **Rafraîchir la vue restaurant** : `ListView.separated` devient un `FutureBuilder`
   sur `GET /api/commandes/?ordering=-creee_le`, avec un `Timer.periodic` de quelques
   secondes ou une notification WebSocket.
4. **Ajouter l'authentification** : remplacer la bascule « Vue client / Vue restaurant »
   par une vraie connexion, et la `DeliveryMode` par des frais de livraison calculés
   côté serveur.

Le groupe de tests « Sérialisation » de `test/app_state_test.dart` montre la forme
exacte du JSON attendu et continuera de servir de garde-fou après le branchement.

## Limites assumées pour cette démo

- Les prix sont des entiers en FCFA (pas de centimes) et ne sont pas affectés par de la TVA.
- Pas de paiement, pas de géolocalisation, pas de compte client, pas de notification push.
- Les commandes refusées restent visibles avec un badge rouge (et peuvent être retirées
  de la liste) plutôt que d'être supprimées : cela montre tout le workflow au restaurateur.
