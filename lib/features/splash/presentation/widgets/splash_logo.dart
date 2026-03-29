import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo_white.svg',
      width: 140,
      fit: BoxFit.contain,
    );
  }
}
