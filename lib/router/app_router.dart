import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillura_med/presentation/pages/add_medication.dart';
import 'package:pillura_med/presentation/pages/landing.dart';
import 'package:pillura_med/presentation/pages/medication_page.dart';
import 'package:pillura_med/presentation/pages/profile_page.dart';
import 'package:pillura_med/presentation/pages/welcome_page.dart';
import 'package:pillura_med/presentation/providers/auth_providers.dart';
import 'package:pillura_med/router/scaffold_with_navbar.dart';

// Глобальный ключ навигации — создаётся один раз
final _navigatorKey = GlobalKey<NavigatorState>(debugLabel: 'go_router_key');

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: '/landing',
    redirect: (context, state) {
      final authState = ref.watch(authNotifierProvider).value;

      if (authState == null) {
        // loading или error → ничего не делаем, остаёмся на текущем роуте
        return null;
      }

      //редиректим только если реально авторизован или нет
      // if (authState.isAuthenticated &&
      //     state.matchedLocation == '/welcomePage') {
      //   return '/profilePage';
      // }
      if (!authState.isAuthenticated &&
          state.matchedLocation != '/welcomePage') {
        return '/welcomePage';
      }

      return null;
    },
    routes: [
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
                builder: (context, state) => ProfilePage(),
              ),
              GoRoute(
                path: '/addMedication',
                name: 'AddMedication',
                builder: (context, state) => AddMedicationPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/welcomePage',
                name: 'WelcomePage',
                builder: (context, state) => const WelcomePage(),
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
