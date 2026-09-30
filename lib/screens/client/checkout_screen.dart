import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../state/app_state_scope.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/recap_ligne.dart';
import 'order_confirmation_screen.dart';

/// -----------------------------------------------------------------------------
/// VUE CLIENT — écran de commande
/// -----------------------------------------------------------------------------
/// Étape 1 : récapitulatif du panier (quantités ajustables).
/// Étape 2 : informations client (nom, téléphone) et mode de retrait.
/// Étape 3 : confirmation.
///
/// Le champ « adresse » n'apparaît que si le mode « Livraison » est sélectionné.
/// La validation se fait côté client (démo sans backend) ; en production, la
/// même validation devra être refaite dans les serializers Django.
/// -----------------------------------------------------------------------------
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  /// Clé du formulaire : permet de declencher l'affichage des erreurs.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _telephoneCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();

  /// Mode de retrait sélectionné par défaut.
  DeliveryMode _mode = DeliveryMode.retrait;

  /// Sert à faire défiler l'écran vers le champ adresse lorsqu'il apparaît.
  final GlobalKey _adresseKey = GlobalKey();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.watch(context);
    final lignes = state.lignesPanier;

    // Filet de sécurité : on ne peut confirmer que si le panier n'est pas vide.
    if (lignes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Votre commande')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('🛒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Votre panier est vide.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour au menu'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Votre commande')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: <Widget>[
            _blocReapitulatif(context, state, lignes),
            const SizedBox(height: 14),
            _blocCoordonnees(),
            const SizedBox(height: 14),
            _blocMode(),
            // Champ conditionnel : affiché uniquement en mode Livraison.
            if (_mode == DeliveryMode.livraison) ...<Widget>[
              const SizedBox(height: 14),
              _blocAdresse(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _barreDeValidation(context, state.totalPanier),
    );
  }

  /// Carte « Récapitulatif » : contenu du panier et total.
  Widget _blocReapitulatif(BuildContext context, AppState state, List<OrderLine> lignes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Text('🧾', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                // Flexible : le titre ne doit pas pousser le bouton « Vider »
                // hors de l'écran sur les petits téléphones.
                Flexible(
                  child: Text(
                    'Votre commande',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: state.viderPanier,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Vider'),
                ),
              ],
            ),
            const Divider(height: 18),
            ...lignes.map(
              (ligne) => RecapLigne(
                ligne: ligne,
                onIncrementer: () =>
                    AppStateScope.read(context).incrementer(ligne.itemId),
                onDecrementer: () =>
                    AppStateScope.read(context).decrementer(ligne.itemId),
              ),
            ),
            const Divider(height: 12),
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    'Total à payer',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                Text(
                  formatFcfa(state.totalPanier),
                  style: const TextStyle(
                    color: AppTheme.terracotta,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Carte « Qui êtes-vous ? » : nom et téléphone du client.
  Widget _blocCoordonnees() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Vos informations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (valeur) => (valeur == null || valeur.trim().length < 2)
                  ? 'Veuillez indiquer votre nom'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telephoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              // Uniquement chiffres, espaces et + : évite les saisies erronées.
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[\d +]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '77 123 45 67',
                prefixIcon: Icon(Icons.phone_iphone),
              ),
              validator: (valeur) {
                final chiffres = (valeur ?? '').replaceAll(RegExp(r'\D'), '');
                if (chiffres.isEmpty) return 'Veuillez indiquer votre téléphone';
                if (chiffres.length < 8) return 'Numéro trop court';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Sélecteur Retrait / Livraison.
  Widget _blocMode() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Mode de retrait',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DeliveryMode>(
                segments: const <ButtonSegment<DeliveryMode>>[
                  ButtonSegment<DeliveryMode>(
                    value: DeliveryMode.retrait,
                    label: Text('Retrait'),
                    icon: Icon(Icons.shopping_bag_outlined, size: 18),
                  ),
                  ButtonSegment<DeliveryMode>(
                    value: DeliveryMode.livraison,
                    label: Text('Livraison'),
                    icon: Icon(Icons.delivery_dining, size: 18),
                  ),
                ],
                selected: <DeliveryMode>{_mode},
                onSelectionChanged: (selection) =>
                    _changerMode(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Champ adresse : affiché uniquement en mode Livraison.
  Widget _blocAdresse() {
    return Card(
      key: _adresseKey,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Adresse de livraison',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _adresseCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Quartier, repère, Télé',
                hintText: 'Ex : Cocody Angré, face à la pharmacie',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (valeur) {
                // Ce champ n'est validé que s'il est visible (mode Livraison).
                if (_mode != DeliveryMode.livraison) return null;
                return (valeur == null || valeur.trim().length < 5)
                    ? 'Veuillez indiquer une adresse de livraison'
                    : null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Change le mode de retrait. En passant en « Livraison », l'écran défile
  /// automatiquement pour montrer le champ adresse qui vient d'apparaître.
  void _changerMode(DeliveryMode mode) {
    setState(() => _mode = mode);
    if (mode != DeliveryMode.livraison) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexte = _adresseKey.currentContext;
      if (contexte == null) return;
      Scrollable.ensureVisible(
        contexte,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    });
  }

  /// Barre fixe du bas : total + bouton de confirmation.
  Widget _barreDeValidation(BuildContext context, int total) {
    return Material(
      color: Colors.white,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: AppTheme.grisChaud,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatFcfa(total),
                    style: const TextStyle(
                      color: AppTheme.terracotta,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _confirmer,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Confirmer la commande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Valide le formulaire, crée la commande en mémoire et ouvre la confirmation.
  void _confirmer() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final commande = AppStateScope.read(context).creerCommande(
      nomClient: _nomCtrl.text.trim(),
      telephone: _telephoneCtrl.text.trim(),
      mode: _mode,
      adresse: _adresseCtrl.text.trim(),
    );

    // `pushReplacement` : on ne revient jamais en arrière sur un formulaire déjà
    // envoyé, et le panier a été vidé par la création de la commande.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(commande: commande),
      ),
    );
  }
}
