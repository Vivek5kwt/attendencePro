import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/app_cubit.dart';
import '../../screens/auth_flow.dart';
import '../../screens/home_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/walkthrough_screen.dart';
import 'routes.dart';

class AppRouterRefreshNotifier extends ChangeNotifier {
  final AppCubit appCubit;
  late final StreamSubscription _subscription;

  AppRouterRefreshNotifier(this.appCubit) {
    _subscription = appCubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AppCubit appCubit;
  late final GoRouter router;
  late final AppRouterRefreshNotifier _refreshNotifier;

  AppRouter({required this.appCubit}) {
    _refreshNotifier = AppRouterRefreshNotifier(appCubit);

    router = GoRouter(
      refreshListenable: _refreshNotifier,
      debugLogDiagnostics: false,
      routes: <GoRoute>[
        GoRoute(
          path: Routes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: Routes.walkthrough,
          name: 'walkthrough',
          builder: (context, state) => const WalkthroughScreen(),
        ),
        GoRoute(
          path: Routes.auth,
          name: 'auth',
          builder: (context, state) => const AuthFlow(),
        ),
        GoRoute(
          path: Routes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
      redirect: (BuildContext context, GoRouterState state) {
        final appState = appCubit.state;
        final location = state.uri.toString();

        if (appState is AppSplash) {
          if (location != Routes.splash) return Routes.splash;
          return null;
        } else if (appState is AppWalkthrough) {
          if (location != Routes.walkthrough) return Routes.walkthrough;
          return null;
        } else if (appState is AppAuth) {
          if (location != Routes.auth) return Routes.auth;
          return null;
        } else if (appState is AppHome) {
          if (location != Routes.home) return Routes.home;
          return null;
        }

        return null;
      },
      initialLocation: Routes.initial,
    );
  }

  void dispose() {
    _refreshNotifier.dispose();
  }
}