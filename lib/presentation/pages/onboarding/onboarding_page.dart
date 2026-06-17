import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_provider.dart';
import 'onboarding_slide.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  final bool showSwipeHint;

  const OnboardingPage({super.key, this.showSwipeHint = true});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  static const _hintDelay = Duration(seconds: 5);
  static const _hintRepeatCount = 3;

  late final PageController _pageController;
  late final AnimationController _hintController;
  late final Animation<double> _hintOffset;
  Timer? _hintTimer;
  int _currentPage = 0;
  int _hintPlayCount = 0;
  bool _showHint = false;
  bool _hintFinished = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _hintOffset = Tween<double>(begin: 56, end: -56).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
    _scheduleSwipeHint();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _hintController.removeStatusListener(_onHintStatus);
    _pageController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref.read(onboardingStorageProvider).markOnboardingSeen();
    ref.invalidate(hasSeenOnboardingProvider);
    if (mounted) context.go('/authChoice');
  }

  void _onPageChanged(int page) {
    _hintTimer?.cancel();
    _stopSwipeHintAnimation();

    setState(() {
      _currentPage = page;
      _showHint = false;
    });

    if (page == 0 && !_hintFinished) {
      _scheduleSwipeHint();
    }
  }

  void _scheduleSwipeHint() {
    _hintTimer?.cancel();
    if (!widget.showSwipeHint || _currentPage != 0 || _hintFinished) return;

    _hintTimer = Timer(_hintDelay, () {
      if (!mounted || _currentPage != 0 || _hintFinished) return;
      _startSwipeHintAnimation();
    });
  }

  void _startSwipeHintAnimation() {
    _hintPlayCount = 0;
    setState(() => _showHint = true);
    _hintController.removeStatusListener(_onHintStatus);
    _hintController.addStatusListener(_onHintStatus);
    _hintController.forward(from: 0);
  }

  void _onHintStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _currentPage != 0) {
      return;
    }

    _hintPlayCount++;
    if (_hintPlayCount >= _hintRepeatCount) {
      _hintFinished = true;
      _stopSwipeHintAnimation();
      setState(() => _showHint = false);
      return;
    }

    _hintController.forward(from: 0);
  }

  void _stopSwipeHintAnimation() {
    _hintController.removeStatusListener(_onHintStatus);
    _hintController.stop();
    _hintController.reset();
  }

  Widget _buildSwipeHintAnimation() {
    if (!_showHint ||
        !widget.showSwipeHint ||
        _currentPage != 0 ||
        _hintFinished) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerRight,
        child: AnimatedBuilder(
          animation: _hintOffset,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_hintOffset.value, 0),
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 28),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.back_hand_outlined,
              size: 44,
              color: OnboardingSlide.brandColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int slideCount) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Row(
          children: List.generate(slideCount, (index) {
            final isActive = index == _currentPage;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                margin: EdgeInsets.only(
                  right: index == slideCount - 1 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? OnboardingSlide.brandColor
                      : const Color(0xFFD6DBF4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  List<Widget> _buildSlides() {
    return [
      OnboardingSlide(
        title: '',
        illustration: const WelcomeIllustration(),
        onSkip: _finishOnboarding,
      ),
      OnboardingSlide(
        title: 'Как все устроено',
        illustration: const AddMedicineIllustration(),
        onSkip: _finishOnboarding,
      ),
      OnboardingSlide(
        title: 'Профили, подопечные,\nсписки лекарств',
        illustration: const ProfilesIllustration(),
        onSkip: _finishOnboarding,
      ),
      OnboardingSlide(
        title: 'Статистика',
        illustration: const StatisticsIllustration(),
        onSkip: _finishOnboarding,
        showSkip: false,
      ),
      // OnboardingSlide(
      //   title: 'История приемов',
      //   illustration: const HistoryIllustration(),
      //   onSkip: _finishOnboarding,
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: slides,
          ),
          _buildPageIndicator(slides.length),
          _buildSwipeHintAnimation(),
        ],
      ),
    );
  }
}
