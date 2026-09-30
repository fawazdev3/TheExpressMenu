/// -----------------------------------------------------------------------------
/// FORMATAGE DES MONTANTS (FCFA)
/// -----------------------------------------------------------------------------
/// Petit utilitaire maison : évite d'ajouter la dépendance `intl` (et le
/// `NumberFormat` associé) pour un simple séparateur de milliers.
///   formatFcfa(2500) -> "2 500 FCFA"
/// -----------------------------------------------------------------------------
library;

String formatFcfa(int montant) {
  final chiffres = montant.abs().toString();
  final tampon = StringBuffer();
  for (var i = 0; i < chiffres.length; i++) {
    // Espace insécable (U+00A0) tous les 3 chiffres en partant de la droite :
    // le montant ne peut jamais être coupé en fin de ligne.
    if (i > 0 && (chiffres.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(chiffres[i]);
  }
  final signe = montant < 0 ? '-' : '';
  return '$signe$tampon FCFA';
}

/// Accorde un nom au pluriel : "0 article" / "1 article" / "3 articles".
String pluriel(int nombre, String singulier, [String? plurielForme]) =>
    nombre <= 1 ? singulier : (plurielForme ?? '${singulier}s');
