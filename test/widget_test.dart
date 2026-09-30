// -----------------------------------------------------------------------------
// Tests de la démo « Le Menu Express »
// -----------------------------------------------------------------------------
// Ces tests couvrent le parcours principal, de bout en bout :
//   1. l'app démarre sur la vue client, sans commande en attente ;
//   2. l'ajout au panier fait apparaître la barre de panier (nb + total) ;
//   3. la commande est validée et visible côté restaurant avec le statut
//      « Nouvelle », puis le restaurant la fait avancer jusqu'à « Livrée / Retirée » ;
//   4. le formulaire refuse les saisies invalides et le restaurant peut refuser.
//
// Lancer tous les tests : `flutter test`
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_resto/main.dart';
import 'package:test_resto/models/menu_item.dart';
import 'package:test_resto/models/order.dart';
import 'package:test_resto/screens/client/menu_screen.dart';
import 'package:test_resto/state/app_state.dart';
import 'package:test_resto/utils/format.dart';

/// Charge les vraies polices Poppins dans l'environnement de test.
/// Sans cela, Flutter substitue une police de test aux métriques arbitraires
/// et la mise en page vérifiée ici ne correspondrait pas à celle du téléphone.
Future<void> chargerPolices() async {
  for (
    final graisse in const <String>['Regular', 'Medium', 'SemiBold', 'Bold']
  ) {
    final loader = FontLoader('Poppins')
      ..addFont(rootBundle.load('assets/fonts/Poppins-$graisse.ttf'));
    await loader.load();
  }
}

void main() {
  setUpAll(chargerPolices);

  /// Démarre l'application sur une surface de type téléphone (360 x 800 px
  /// logiques) et attend la fin des animations.
  Future<void> demarrerApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LeMenuExpressApp());
    await tester.pumpAndSettle();
  }

  /// Bascule sur la vue restaurant via le bouton de toggle.
  Future<void> allerVueRestaurant(WidgetTester tester) async {
    await tester.tap(find.text('Vue restaurant'));
    await tester.pumpAndSettle();
  }

  // =========================================================================
  // Identité de l'application : police Poppins + logo officiel
  // =========================================================================

  testWidgets('Poppins est la police par défaut de toute l\'application', (
    tester,
  ) async {
    await demarrerApp(tester);
    await tester.tap(find.text('Ajouter').first);
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(MenuScreen)));

    // Les styles du thème (issus de ThemeData.fontFamily) utilisent Poppins.
    for (final style in <TextStyle?>[
      theme.textTheme.bodyMedium,
      theme.textTheme.bodyLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.titleLarge,
      theme.textTheme.headlineSmall,
      theme.primaryTextTheme.bodyMedium,
      theme.appBarTheme.titleTextStyle,
    ]) {
      expect(style?.fontFamily, 'Poppins');
    }

    /// Police RÉELLEMENT utilisée par un texte donné (style ambiant fusionné
    /// avec le style du widget). C'est ce contrôle qui a permis de détecter
    /// les libellés de boutons qui échappaient à la police du thème.
    void verifierPolice(String libelle) {
      final finder = find.text(libelle).first;
      expect(finder, findsOneWidget, reason: '$libelle est introuvable');
      final ambiant = DefaultTextStyle.of(tester.element(finder)).style;
      final effectif = ambiant.merge((tester.widget(finder) as Text).style);
      expect(
        effectif.fontFamily,
        'Poppins',
        reason: 'le texte « $libelle » n\'utilise pas Poppins',
      );
    }

    // Textes simples, titres et libellés de boutons.
    for (final libelle in <String>[
      'Poulet braisé + frites',
      'Notre carte',
      'Ajouter', // FilledButton.icon
      'Commander', // FilledButton.icon de la barre de panier
      'Vue client', // SegmentedButton de la bascule
    ]) {
      verifierPolice(libelle);
    }

    // Écran de commande : boutons, segments et champs de saisie.
    await tester.tap(find.text('Commander'));
    await tester.pumpAndSettle();
    for (final libelle in <String>[
      'Votre commande',
      'Vider', // TextButton
      'Retrait', // SegmentedButton du mode de retrait
      'Confirmer la commande', // barre de validation
    ]) {
      verifierPolice(libelle);
    }
  });

  testWidgets('Le logo officiel remplace l\'emoji dans l\'en-tête', (
    tester,
  ) async {
    await demarrerApp(tester);

    final logos = tester
        .widgetList<Image>(find.byType(Image))
        .where(
          (image) =>
              image.image is AssetImage &&
              (image.image as AssetImage).assetName.contains(
                'logo-menu-express',
              ),
        )
        .toList();

    expect(logos, hasLength(1));
    // Taille raisonnable : le nom du restaurant reste lisible en texte à côté.
    expect(tester.getSize(find.byWidget(logos.single)), const Size(52, 52));
    // L'en-tête ne déborde pas sur un écran étroit.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vue restaurant : une commande très longue reste lisible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    // Commande volontairement "pire cas" : nom long, adresse longue,
    // téléphone au format international et plusieurs articles.
    final state = AppState();
    for (final item in MenuItem.menuDemo.take(4)) {
      state.ajouterAuPanier(item);
    }
    state.creerCommande(
      nomClient: 'Mamie Alphonsine de Cocody-Danga',
      telephone: '+225 07 08 09 10 11',
      mode: DeliveryMode.livraison,
      adresse:
          'Immeuble La Fournaise, 3e etage, en face de la pharmacie '
          'Saint-Jean, Cocody Angre 8e tranche',
    );
    state.ajouterAuPanier(MenuItem.menuDemo[0]);
    state.creerCommande(
      nomClient: 'Koffi Kouassi',
      telephone: '0701122334',
      mode: DeliveryMode.retrait,
    );
    state.changerStatut('CMD-002', OrderStatus.enPreparation);

    await tester.pumpWidget(LeMenuExpressApp(state: state));
    await tester.pumpAndSettle();
    await allerVueRestaurant(tester);
    await tester.pumpAndSettle();

    // Le bandeau de statut le plus large (« En préparation ») est affiché.
    expect(find.text('En préparation'), findsOneWidget);
    // Les textes longs sont bien présents (avec troncature si nécessaire).
    expect(find.textContaining('Mamie Alphonsine'), findsOneWidget);
    expect(find.textContaining('pharmacie Saint-Jean'), findsOneWidget);
    // Aucun débordement de texte sur 360 px de large.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Démarrage : vue client, panier vide, aucune commande', (
    tester,
  ) async {
    await demarrerApp(tester);

    // Le restaurant et sa carte sont affichés.
    expect(find.text('Le Menu Express'), findsOneWidget);
    expect(find.text('Poulet braisé + frites'), findsOneWidget);

    // La barre de panier est masquée tant que le panier est vide.
    expect(find.text('Commander'), findsNothing);

    // La vue restaurant ne contient aucune commande.
    await allerVueRestaurant(tester);
    expect(find.text('Aucune commande pour le moment'), findsOneWidget);
  });

  testWidgets('Ajout au panier : la barre affiche le nombre et le total', (
    tester,
  ) async {
    await demarrerApp(tester);

    // 2 500 + 2 500 = 5 000 FCFA (le bouton « Ajouter » devient un
    // sélecteur de quantité, on clique donc sur « + »).
    await tester.tap(find.text('Ajouter').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('2 articles'), findsOneWidget);
    expect(find.text(formatFcfa(5000)), findsWidgets);
    expect(find.text('Commander'), findsOneWidget);
  });

  testWidgets('Parcours complet : commande côté client puis suivi restaurant', (
    tester,
  ) async {
    await demarrerApp(tester);

    // --- 1. Le client compose son panier -----------------------------------
    await tester.tap(find.text('Ajouter').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commander'));
    await tester.pumpAndSettle();

    // --- 2. Un formulaire incomplet ne crée aucune commande ----------------
    await tester.tap(find.text('Confirmer la commande'));
    await tester.pumpAndSettle();
    expect(find.text('Veuillez indiquer votre nom'), findsOneWidget);
    expect(find.text('Veuillez indiquer votre téléphone'), findsOneWidget);

    // --- 3. Remplissage du formulaire en mode Livraison --------------------
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom complet'),
      'Awa Diop',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Téléphone'),
      '771234567',
    );
    await tester.tap(find.text('Livraison'));
    await tester.pumpAndSettle();

    // Le champ adresse n'apparaît qu'en mode Livraison.
    expect(find.text('Adresse de livraison'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quartier, repère, Télé'),
      'Cocody Angré, face à la pharmacie',
    );

    await tester.tap(find.text('Confirmer la commande'));
    await tester.pumpAndSettle();

    // --- 4. Écran de confirmation ------------------------------------------
    expect(find.text('Commande confirmée !'), findsOneWidget);
    expect(find.text('CMD-001'), findsOneWidget);

    await tester.tap(find.text('Retour au menu'));
    await tester.pumpAndSettle();

    // Le panier a été vidé après la commande.
    expect(find.text('Commander'), findsNothing);

    // --- 5. La commande arrive côté restaurant ------------------------------
    await allerVueRestaurant(tester);
    expect(find.text('CMD-001'), findsOneWidget);
    expect(find.text('Awa Diop'), findsOneWidget);
    expect(find.text('Nouvelle'), findsOneWidget);
    // Le montant apparaît deux fois sur la carte : la ligne et le total.
    expect(find.text(formatFcfa(2500)), findsNWidgets(2));

    // --- 6. Workflow du restaurant ------------------------------------------
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();
    expect(find.text('En préparation'), findsOneWidget);

    await tester.tap(find.text('Marquer prête'));
    await tester.pumpAndSettle();
    expect(find.text('Prête'), findsOneWidget);

    await tester.tap(find.text('Livrée / Retirée'));
    await tester.pumpAndSettle();
    expect(find.text('Accepter'), findsNothing);
    expect(find.text('Marquer prête'), findsNothing);
  });

  testWidgets('Le restaurant peut refuser une commande', (tester) async {
    await demarrerApp(tester);

    await tester.tap(find.text('Ajouter').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commander'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom complet'),
      'Koffi Kouassi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Téléphone'),
      '0701122334',
    );
    await tester.tap(find.text('Confirmer la commande'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour au menu'));
    await tester.pumpAndSettle();

    await allerVueRestaurant(tester);
    await tester.tap(find.text('Refuser'));
    await tester.pumpAndSettle();
    // Confirmation dans la boîte de dialogue.
    await tester.tap(find.widgetWithText(FilledButton, 'Refuser').last);
    await tester.pumpAndSettle();

    expect(find.text('Refusée'), findsOneWidget);
    expect(find.text('Commande refusée par le restaurant'), findsOneWidget);
  });
}
