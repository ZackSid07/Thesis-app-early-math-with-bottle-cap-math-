import 'package:flutter/material.dart';

class AppTheme {
  // 1. Color Palette
  static const Color primaryBlue = Color(0xFF4FACFE);
  static const Color successGreen = Color(0xFF00F260);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color background = Color(0xFFF9F9F9);

  // Define a ThemeData object using 'Nunito' as the primary font family.
  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: background,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: warningOrange,
        surface: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

// 2. BottleCapWidget
enum CapType { number, operator, equals }

class BottleCapWidget extends StatelessWidget {
  final String text;
  final CapType type;
  final double size;

  const BottleCapWidget({
    Key? key,
    required this.text,
    required this.type,
    this.size = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case CapType.number:
        backgroundColor = Colors.red;
        break;
      case CapType.operator:
        backgroundColor = AppTheme.primaryBlue;
        break;
      case CapType.equals:
        backgroundColor = Colors.white;
        textColor = Colors.black87;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        // Outer BoxShadow for elevation
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
        // RadialGradient simulates 3D depth/inner shadow on the cap
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            backgroundColor,
            Colors.black.withOpacity(0.3),
          ],
          center: Alignment.topLeft,
          radius: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 3. ToyButton
class ToyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Widget? icon;

  const ToyButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = AppTheme.primaryBlue,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30.0), // Pill-shaped button
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 6), // Prominent bottom shadow
              blurRadius: 0, // Hard edge to make it look tactile and clickable
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
