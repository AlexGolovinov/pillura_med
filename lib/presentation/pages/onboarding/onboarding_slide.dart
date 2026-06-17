import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pillura_med/core/theme/profile_link_colors.dart';

class OnboardingSlide extends StatelessWidget {
  final String title;
  final Widget illustration;
  final String? caption;
  final VoidCallback onSkip;
  final bool showSkip;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.illustration,
    required this.onSkip,
    this.caption,
    this.showSkip = true,
  });

  static const brandColor = Color(0xFF202D85);
  static const softBlue = Color(0xFFE8EFFB);
  static const softGreen = Color(0xFFE4F3AB);
  static const softOrange = Color(0xFFFFE8CC);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 46, 24, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: brandColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: illustration,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 20),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF5A5A5A),
                ),
              ),
            ],
            const SizedBox(height: 22),
            if (showSkip)
              TextButton(
                onPressed: onSkip,
                child: const Text('Пропустить'),
              )
            else
              TextButton(
                onPressed: onSkip,
                child: Text('Начать', style: textTheme.titleMedium?.copyWith(
                  color: ProfileLinkColors.ownBorderSelected,
                  fontSize: 18,
                )),
              )
          ],
        ),
      ),
    );
  }
}

class DashedInfoCard extends StatelessWidget {
  final Widget child;

  const DashedInfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6C9), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: -20,
          bottom: -10,
          child: _PlantPot(),
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Добро пожаловать в',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF343434),
                  fontSize: 17,
                ),
              ),
              Text(
                'PILLURA-MED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: OnboardingSlide.brandColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ваш персональный\nпомощник приема лекарств',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddMedicineIllustration extends StatelessWidget {
  const AddMedicineIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedInfoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Легко добавляйте лекарства',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.add_rounded,
            size: 58,
            color: OnboardingSlide.brandColor,
          ),
          const SizedBox(height: 28),
          const Text(
            'Получайте необходимые\nнапоминания',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF4A4A4A),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.favorite_border_rounded,
            size: 38,
            color: Colors.orange.shade300,
          ),
        ],
      ),
    );
  }
}

class ProfilesIllustration extends StatelessWidget {
  const ProfilesIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedInfoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Добавляйте профили',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              _MiniProfileCard(
                label: 'Профиль',
                icon: Icons.person_outline,
                kind: _MiniProfileKind.own,
              ),
              SizedBox(width: 8),
              _MiniProfileCard(
                label: 'Мама',
                icon: Icons.person_3,
                kind: _MiniProfileKind.share,
              ),
              SizedBox(width: 8),
              _MiniProfileCard(
                label: 'кот',
                icon: Icons.pets_outlined,
                kind: _MiniProfileKind.ward,
                isSelected: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Список лекарств кота:', style: TextStyle(fontStyle: FontStyle.italic)),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8D8D8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 52,
                  decoration: BoxDecoration(
                    color: OnboardingSlide.softGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: const [
                      _Line(widthFactor: 0.95),
                      SizedBox(height: 8),
                      _Line(widthFactor: 0.75),
                      SizedBox(height: 8),
                      _Line(widthFactor: 0.88),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Делитесь списком\nс друзьями, близкими',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class StatisticsIllustration extends StatelessWidget {
  const StatisticsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedInfoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Самый частый симптом\nГоловная боль',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 22),
          const Text(
            'По болезням (кол-во раз)',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E1FF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Stack(
        alignment: Alignment.center,
        children: [
          DonutChart(
            size: 86,
            strokeWidth: 18,
            segments: const [
              DonutSegment(value: 3, color: Color(0xFF202D85)),   // ОРВИ
              DonutSegment(value: 12, color: Color(0xFFE5E1FF)),  // Простуда
            ],
          ),
        ],
      ),
                  const Text(
                    '3\n12',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: OnboardingSlide.brandColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ОРВИ'),
                  SizedBox(height: 28),
                  Text('Простуда'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryIllustration extends StatelessWidget {
  const HistoryIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return DashedInfoCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Загрузите файл\nистории приемов',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.photo_camera_outlined, color: OnboardingSlide.brandColor),
              SizedBox(width: 16),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF888888)),
              SizedBox(width: 16),
              Icon(Icons.description_outlined, color: OnboardingSlide.brandColor),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('Поиск')),
                Icon(Icons.search_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Line(widthFactor: 0.9),
                    SizedBox(height: 8),
                    _Line(widthFactor: 0.65),
                    SizedBox(height: 8),
                    _Line(widthFactor: 0.75),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              const Icon(
                Icons.touch_app_outlined,
                size: 54,
                color: Color(0xFFE7B05E),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlantPot extends StatelessWidget {
  const _PlantPot();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.eco_rounded, color: Color(0xFF4F8C43), size: 86),
        Container(
          width: 66,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFFE49A4E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

enum _MiniProfileKind { own, ward, share }

class _MiniProfileCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final _MiniProfileKind kind;
  final bool isSelected;

  const _MiniProfileCard({
    required this.label,
    required this.icon,
    required this.kind,
    this.isSelected = false,
  });

  Color get _borderColor {
    switch (kind) {
      case _MiniProfileKind.own:
        return isSelected
            ? ProfileLinkColors.ownBorderSelected
            : ProfileLinkColors.ownBorder;
      case _MiniProfileKind.ward:
        return isSelected
            ? ProfileLinkColors.wardBorderSelected
            : ProfileLinkColors.wardBorder;
      case _MiniProfileKind.share:
        return isSelected
            ? ProfileLinkColors.shareBorderSelected
            : ProfileLinkColors.shareBorder;
    }
  }

  Color get _backgroundColor {
    if (!isSelected) return Colors.white;
    switch (kind) {
      case _MiniProfileKind.own:
        return ProfileLinkColors.ownProfileSelectedBg;
      case _MiniProfileKind.ward:
        return ProfileLinkColors.wardProfileSelectedBg;
      case _MiniProfileKind.share:
        return ProfileLinkColors.shareProfileSelectedBg;
    }
  }

  Color get _iconColor {
    switch (kind) {
      case _MiniProfileKind.own:
        return isSelected
            ? ProfileLinkColors.ownBorderSelected
            : ProfileLinkColors.ownIcon;
      case _MiniProfileKind.ward:
        return isSelected
            ? ProfileLinkColors.wardBorderSelected
            : ProfileLinkColors.wardIcon;
      case _MiniProfileKind.share:
        return isSelected
            ? ProfileLinkColors.shareBorderSelected
            : ProfileLinkColors.shareIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: _iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? _borderColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double widthFactor;

  const _Line({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD7D7D7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final double size;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.segments,
    this.size = 86,
    this.strokeWidth = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: segments,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class DonutSegment {
  final double value;
  final Color color;

  const DonutSegment({required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;

  _DonutPainter({required this.segments, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);

    var startAngle = -math.pi / 1.4; // старт сверху

    for (final segment in segments) {
      final sweepAngle = 2 * math.pi * (segment.value / total);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}