import 'package:flutter/widgets.dart';

final class Gt7AssetManifest {
  const Gt7AssetManifest._();

  static const packageName = 'gt7_design_system';

  static const raceTacticianLogo = 'assets/images/logo_race_tactician.png';
  static const raceTacticianLogoDark =
      'assets/images/logo_race_tactician_black.png';
  static const bananaLogo = 'assets/images/logo_banana.png';
  static const bananaLogoDark = 'assets/images/logo_banana_black.png';

  static AssetImage image(String assetName) {
    return AssetImage(assetName, package: packageName);
  }
}
