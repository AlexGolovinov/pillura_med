import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const _seenOnboardingKey = 'seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenOnboardingKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenOnboardingKey, true);
  }
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  return OnboardingStorage();
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingStorageProvider).hasSeenOnboarding();
});
