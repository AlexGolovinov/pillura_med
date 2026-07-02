import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/data/models/add_medication_route_data.dart';
import 'package:pillura_med/data/models/medication_data.dart';
import 'package:pillura_med/data/models/share_medications_route_data.dart';
import 'package:pillura_med/presentation/pages/account_page.dart';
import 'package:pillura_med/presentation/pages/add_medication.dart';
import 'package:pillura_med/presentation/pages/add_person/add_ward.dart';
import 'package:pillura_med/presentation/pages/add_person/add_by_code_page.dart';
import 'package:pillura_med/presentation/pages/add_person/menu_add_person.dart';
import 'package:pillura_med/presentation/pages/add_person/share_medications_page.dart';
import 'package:pillura_med/presentation/pages/landing.dart';
import 'package:pillura_med/presentation/pages/medication_page.dart';
import 'package:pillura_med/presentation/pages/onboarding/auth_choice_page.dart';
import 'package:pillura_med/presentation/pages/onboarding/login_page.dart';
import 'package:pillura_med/presentation/pages/onboarding/onboarding_page.dart';
import 'package:pillura_med/presentation/pages/onboarding/register_page.dart';
import 'package:pillura_med/presentation/pages/profile_page.dart';
import 'package:pillura_med/presentation/pages/onboarding/authorization_page.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/presentation/providers/notification_provider.dart';
import 'package:pillura_med/presentation/providers/repository_provider.dart';
import 'package:pillura_med/router/scaffold_with_navbar.dart';

// Глобальный ключ навигации — создаётся один раз
final navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'go_router_key');

/// Пересчитывает redirect без пересоздания GoRouter при смене auth.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/landing',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider).value;

      if (authState == null) {
        // loading или error → ничего не делаем, остаёмся на текущем роуте
        return null;
      }

      final publicRoutes = {
        '/landing',
        '/onboarding',
        '/authChoice',
        '/login',
        '/register',
        '/welcomePage',
      };

      if (authState.isAuthenticated &&
          publicRoutes.contains(state.matchedLocation)) {
        final pendingProfileId = ref.read(pendingNotificationProfileIdProvider);
        final currentUid = ref.read(currentUserIdProvider);
        if (pendingProfileId != null &&
            currentUid != null &&
            pendingProfileId != currentUid) {
          return '/profilePage?profileUserId=$pendingProfileId';
        }
        return '/profilePage';
      }

      if (!authState.isAuthenticated &&
          !publicRoutes.contains(state.matchedLocation)) {
        return '/landing';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'Onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/authChoice',
        name: 'AuthChoice',
        builder: (context, state) => const AuthChoicePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'Login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'Register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/welcomePage',
        name: 'WelcomePage',
        builder: (context, state) => const AuthorizationPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNavBar(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medicationPage',
                name: 'MedicationPage',
                builder: (context, state) => const MedicationPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profilePage',
                name: 'ProfilePage',
                builder: (context, state) => ProfilePage(
                  initialProfileUserId:
                      state.uri.queryParameters['profileUserId'],
                ),
              ),
              GoRoute(
                path: '/account',
                name: 'Account',
                builder: (context, state) => const AccountPage(),
              ),
              GoRoute(
                path: '/addMedication',
                name: 'AddMedication',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is AddMedicationRouteData) {
                    return AddMedicationPage(routeData: extra);
                  }
                  if (extra is MedicationData) {
                    return AddMedicationPage(
                      routeData: AddMedicationRouteData(medicationData: extra),
                    );
                  }
                  return const AddMedicationPage();
                },
              ),
              GoRoute(
                path: '/shareMedications',
                name: 'ShareMedications',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is ShareMedicationsRouteData) {
                    return ShareMedicationsPage(
                      initialUserId: extra.initialUserId,
                    );
                  }
                  return const ShareMedicationsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                name: 'MenuAddPerson',
                builder: (context, state) => const MenuAddPerson(),
                routes: [
                  GoRoute(
                    path: 'by-code',
                    name: 'AddByCode',
                    builder: (context, state) => const AddByCodePage(),
                  ),
                  GoRoute(
                    path: 'ward',
                    name: 'AddWard',
                    builder: (context, state) => const AddWard(),
                  ),
                ],
              ),
            ],
          ),
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: '/applicationsScreen',
          //       name: 'ApplicationsScreen',
          //       builder: (context, state) => const ApplicationsScreen(),
          //     ),
          //     GoRoute(
          //       path: '/saleScreen',
          //       name: 'SaleScreen',
          //       builder: (context, state) => const SaleScreen(),
          //     ),
          //     GoRoute(
          //       path: '/addSaleScreen',
          //       name: 'AddSaleScreen',
          //       builder: (context, state) => const AddSaleScreen(),
          //     ),
          //     GoRoute(
          //       path: '/purshaseScreen',
          //       name: 'PurshaseScreen',
          //       builder: (context, state) => const PurchaseScreen(),
          //     ),
          //   ],
          // ),
          // StatefulShellBranch(
          //   routes: [
          //     GoRoute(
          //       path: '/accountSettings',
          //       name: 'accountSettings',
          //       builder: (context, state) => const AccountSettingsPage(),
          //     ),
          //   ],
          // ),
        ],
      ),
      GoRoute(
        path: '/landing',
        name: 'Landing',
        builder: (context, state) => const Landing(),
      ),
    ],
  );
});
