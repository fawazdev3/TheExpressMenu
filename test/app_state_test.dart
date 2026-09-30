// -----------------------------------------------------------------------------
// Tests unitaires : formatage des montants et état global (AppState).
// Ces tests ne touchent pas l'interface : ils valident la logique métier qui
// sera réutilisée telle quelle lors du branchement sur l'API Django.
// Lancer : `flutter test`
// -----------------------------------------------------------------------------
import 'package:flutter_test/flutter_test.dart';
import 'package:test_resto/models/menu_item.dart';
import 'package:test_resto/models/order.dart';
import 'package:test_resto/state/app_state.dart';
import 'package:test_resto/utils/format.dart';

void main() {
  group('Formatage des montants en FCFA', () {
    test('sépare les milliers et ajoute la devise', () {
      const espace = ' ';
      expect(formatFcfa(500), '500 FCFA');
      expect(formatFcfa(1500), '1${espace}500 FCFA');
      expect(formatFcfa(2500), '2${espace}500 FCFA');
      expect(formatFcfa(1234567), '1${espace}234${espace}567 FCFA');
    });

    test('accorde le pluriel', () {
      expect(pluriel(0, 'article'), 'article');
      expect(pluriel(1, 'article'), 'article');
      expect(pluriel(3, 'article'), 'articles');
      expect(pluriel(1, 'commande', 'commandes'), 'commande');
    });
  });

  group('Panier du client', () {
    test('ajouter un article met à jour la quantité et le total', () {
      final state = AppState();
      expect(state.panierVide, isTrue);
      expect(state.totalPanier, 0);

      state.ajouterAuPanier(MenuItem.menuDemo[0]); // Poulet braisé : 2 500 F
      state.ajouterAuPanier(MenuItem.menuDemo[4]); // Jus de gingembre : 500 F

      expect(state.nombreArticles, 2);
      expect(state.totalPanier, 3000);
      expect(state.quantiteDansPanier('item-1'), 1);
      expect(state.lignesPanier.length, 2);
    });

    test('incrémenter / décrémenter, retrait automatique à zéro', () {
      final state = AppState();
      state.ajouterAuPanier(MenuItem.menuDemo[0]);

      state.incrementer('item-1');
      expect(state.totalPanier, 5000);

      state.decrementer('item-1');
      state.decrementer('item-1');
      expect(state.panierVide, isTrue);
      expect(state.totalPanier, 0);
    });

    test('vider le panier', () {
      final state = AppState()
        ..ajouterAuPanier(MenuItem.menuDemo[2])
        ..ajouterAuPanier(MenuItem.menuDemo[3]);
      expect(state.totalPanier, 3700);

      state.viderPanier();
      expect(state.panierVide, isTrue);
      expect(state.totalPanier, 0);
    });
  });

  group('Commandes', () {
    /// État avec un panier d'une seule ligne, prêt à être commandé.
    AppState etatAvecPanier() =>
        AppState()..ajouterAuPanier(MenuItem.menuDemo[0]);

    test('la commande créée est « nouvelle » et vide le panier', () {
      final state = etatAvecPanier();
      final commande = state.creerCommande(
        nomClient: 'Awa Diop',
        telephone: '771234567',
        mode: DeliveryMode.retrait,
        adresse: 'Cocody Angré',
      );

      expect(commande.id, 'CMD-001');
      expect(commande.statut, OrderStatus.nouvelle);
      expect(commande.total, 2500);
      expect(commande.nombreArticles, 1);
      expect(commande.adresse, isNull, reason: 'adresse ignorée en mode retrait');
      // Le panier est vidé pour éviter une double commande.
      expect(state.panierVide, isTrue);
      expect(state.commandes.length, 1);
    });

    test('en livraison, l’adresse est conservée', () {
      final state = etatAvecPanier();
      final commande = state.creerCommande(
        nomClient: 'Koffi',
        telephone: '0701122334',
        mode: DeliveryMode.livraison,
        adresse: 'Cocody Angré',
      );
      expect(commande.adresse, 'Cocody Angré');
    });

    test('les numéros de commande sont séquentiels et triés du plus récent', () {
      final state = AppState();
      for (var i = 0; i < 3; i++) {
        state.ajouterAuPanier(MenuItem.menuDemo[0]);
        state.creerCommande(
          nomClient: 'Client $i',
          telephone: '771000000',
          mode: DeliveryMode.retrait,
        );
      }
      expect(
        state.commandes.map((c) => c.id).toList(),
        <String>['CMD-003', 'CMD-002', 'CMD-001'],
        reason: 'les plus récentes doivent apparaître en premier',
      );
    });

    test('le workflow du restaurant fait avancer les statuts', () {
      final state = etatAvecPanier();
      final commande = state.creerCommande(
        nomClient: 'Awa Diop',
        telephone: '771234567',
        mode: DeliveryMode.retrait,
      );
      final id = commande.id;

      expect(state.nombreCommandesEnCours, 1);

      state.appliquerActionPrincipale(id);
      expect(state.commandes.first.statut, OrderStatus.enPreparation);

      state.appliquerActionPrincipale(id);
      expect(state.commandes.first.statut, OrderStatus.prete);

      state.appliquerActionPrincipale(id);
      expect(state.commandes.first.statut, OrderStatus.livreeOuRetiree);

      // Plus rien à faire : la commande n'est plus « en cours ».
      state.appliquerActionPrincipale(id);
      expect(state.commandes.first.statut, OrderStatus.livreeOuRetiree);
      expect(state.nombreCommandesEnCours, 0);
    });

    test('refuser puis supprimer une commande', () {
      final state = etatAvecPanier();
      final id = state
          .creerCommande(
            nomClient: 'Awa',
            telephone: '771234567',
            mode: DeliveryMode.retrait,
          )
          .id;

      state.changerStatut(id, OrderStatus.refusee);
      expect(state.commandes.first.statut, OrderStatus.refusee);
      expect(state.nombreCommandesEnCours, 0);

      state.supprimerCommande(id);
      expect(state.commandes, isEmpty);
      expect(state.existe(id), isFalse);
    });

    test('réinitialiser remet la démo à zéro', () {
      final state = etatAvecPanier();
      state.creerCommande(
        nomClient: 'Awa',
        telephone: '771234567',
        mode: DeliveryMode.retrait,
      );

      state.reinitialiser();
      expect(state.commandes, isEmpty);
      expect(state.panierVide, isTrue);

      // Le compteur de commandes repart de CMD-001.
      state.ajouterAuPanier(MenuItem.menuDemo[0]);
      final nouvelle = state.creerCommande(
        nomClient: 'Awa',
        telephone: '771234567',
        mode: DeliveryMode.retrait,
      );
      expect(nouvelle.id, 'CMD-001');
    });
  });

  group('Sérialisation (compatibilité API Django REST)', () {
    test('une commande fait un aller-retour JSON sans perte', () {
      final state = AppState()..ajouterAuPanier(MenuItem.menuDemo[0]);
      state.incrementer('item-1');
      final originale = state.creerCommande(
        nomClient: 'Awa Diop',
        telephone: '771234567',
        mode: DeliveryMode.livraison,
        adresse: 'Cocody Angré',
      );

      // Ce JSON ressemble exactement à ce que renvoie Django.
      final json = <String, dynamic>{
        'id': 'CMD-001',
        'nom_client': 'Awa Diop',
        'telephone': '771234567',
        'mode': 'livraison',
        'adresse': 'Cocody Angré',
        'articles': <Map<String, dynamic>>[
          <String, dynamic>{
            'item': 'item-1',
            'nom': 'Poulet braisé + frites',
            'prix_unitaire': 2500,
            'emoji': '🍗',
            'quantite': 2,
          },
        ],
        'total': 5000,
        'statut': 'en_preparation',
        'creee_le': originale.creeeLe.toIso8601String(),
      };

      final lue = Order.fromJson(json);
      expect(lue.id, originale.id);
      expect(lue.nomClient, 'Awa Diop');
      expect(lue.mode, DeliveryMode.livraison);
      expect(lue.adresse, 'Cocody Angré');
      expect(lue.statut, OrderStatus.enPreparation);
      expect(lue.total, 5000);
      expect(lue.articles.single.quantite, 2);
      expect(lue.toJson()['statut'], 'en_preparation');
    });

    test('le menu est convertible depuis une réponse JSON', () {
      final item = MenuItem.fromJson(<String, dynamic>{
        'id': 12,
        'nom': 'Pizza',
        'prix': 3000.0, // Django renvoie parfois un flottant
        'emoji': '🍕',
      });
      expect(item.id, '12');
      expect(item.prix, 3000);
      expect(MenuItem.menuDemo.length, 5);
    });
  });
}
