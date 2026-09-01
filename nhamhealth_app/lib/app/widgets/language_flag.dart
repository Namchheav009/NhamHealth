import 'package:flutter/material.dart';

class LanguageFlag extends StatelessWidget {
  const LanguageFlag({super.key, required this.languageCode, this.size = 34});

  final String languageCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath =
        languageCode == 'km'
            ? 'assets/icons/lang/world.png'
            : 'assets/icons/lang/circle.png';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDDE7E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1231543F),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
