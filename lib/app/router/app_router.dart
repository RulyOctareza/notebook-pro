import 'package:go_router/go_router.dart';

import 'package:notebook_pro/features/notes/presentation/screens/home_shell_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: HomeShellScreen()),
    ),
  ],
);
