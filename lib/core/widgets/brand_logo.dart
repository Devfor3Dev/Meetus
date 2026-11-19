import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Logo de la marque
///
/// L'image pour l'instant y a rien (`assets/images/brand/logo.png`). donc tant que le fichier manque, la place reste réservée
/// et vide, pour que la mise en page ne bouge pas le jour où on trouvera le logo
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 30});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          AppAssets.brandLogo,
          height: height,
          fit: BoxFit.contain,
          semanticLabel: 'Loveline',
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
