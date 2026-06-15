import 'package:flutter/material.dart';

class AuthChoiceRow extends StatelessWidget {
  static const brandColor = Color(0xFF202D85);
  static const labelColor = Color(0xFF7E9A40);
  static const accentColor = Color(0xFFE4A46A);
  static const figureColor = Color(0xFF9E9E9E);

  final String label;
  final String buttonText;
  final Widget illustration;
  final VoidCallback? onPressed;

  const AuthChoiceRow({
    super.key,
    required this.label,
    required this.buttonText,
    required this.illustration,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        illustration,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: labelColor,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandColor,
                  side: const BorderSide(color: brandColor),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WalkingStickFigure extends StatelessWidget {
  const WalkingStickFigure({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 18,
            child: Column(
              children: const [
                _SpeedLine(width: 18),
                SizedBox(height: 4),
                _SpeedLine(width: 14),
                SizedBox(height: 4),
                _SpeedLine(width: 10),
              ],
            ),
          ),
          const Icon(
            Icons.directions_walk_rounded,
            size: 42,
            color: AuthChoiceRow.figureColor,
          ),
        ],
      ),
    );
  }
}

class HeartStickFigure extends StatelessWidget {
  const HeartStickFigure({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DecoratedStickFigure(
      decoration: Positioned(
        left: 4,
        top: 8,
        child: Icon(
          Icons.favorite_border_rounded,
          size: 22,
          color: AuthChoiceRow.accentColor,
        ),
      ),
      icon: Icons.accessibility_new_rounded,
    );
  }
}

class LoginStickFigure extends StatelessWidget {
  const LoginStickFigure({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DecoratedStickFigure(
      decoration: Positioned(
        left: 2,
        top: 12,
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 20,
          color: AuthChoiceRow.accentColor,
        ),
      ),
      icon: Icons.person_outline_rounded,
    );
  }
}

class _DecoratedStickFigure extends StatelessWidget {
  final Widget decoration;
  final IconData icon;

  const _DecoratedStickFigure({required this.decoration, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          decoration,
          Icon(icon, size: 42, color: AuthChoiceRow.figureColor),
        ],
      ),
    );
  }
}

class _SpeedLine extends StatelessWidget {
  final double width;

  const _SpeedLine({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 2,
      child: const ColoredBox(color: AuthChoiceRow.accentColor),
    );
  }
}
