// lib/config/router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/songs/songs_list_screen.dart';
import '../screens/songs/song_detail_screen.dart';
import '../screens/songs/song_form_screen.dart';
import '../screens/chords/chords_screen.dart';
import '../screens/fingerstyle/fingerstyle_list_screen.dart';
import '../screens/fingerstyle/fingerstyle_detail_screen.dart';
import '../screens/fingerstyle/fingerstyle_form_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // ── Shell Route (bottom nav) ─────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/songs',
          builder: (context, state) => const SongsListScreen(),
        ),
        GoRoute(
          path: '/fingerstyle',
          builder: (context, state) => const FingerstyleListScreen(),
        ),
        GoRoute(
          path: '/chords',
          builder: (context, state) => const ChordsScreen(),
        ),
      ],
    ),

    // ── Full Screen Routes ───────────────────────────────────────────────
    GoRoute(
      path: '/songs/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SongFormScreen(),
    ),
    GoRoute(
      path: '/songs/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SongDetailScreen(songId: id);
      },
    ),
    GoRoute(
      path: '/songs/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SongFormScreen(songId: id);
      },
    ),
    GoRoute(
      path: '/fingerstyle/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FingerstyleFormScreen(),
    ),
    GoRoute(
      path: '/fingerstyle/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FingerstyleDetailScreen(songId: id);
      },
    ),
    GoRoute(
      path: '/fingerstyle/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FingerstyleFormScreen(songId: id);
      },
    ),
  ],
);

// ── Bottom Nav Shell ──────────────────────────────────────────────────────────

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/songs')) return 1;
    if (location.startsWith('/fingerstyle')) return 2;
    if (location.startsWith('/chords')) return 3;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/songs');
        break;
      case 2:
        context.go('/fingerstyle');
        break;
      case 3:
        context.go('/chords');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _onNavTap(context, i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note_rounded),
            label: 'Songs',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            selectedIcon: Icon(Icons.queue_music_rounded),
            label: 'Fingerstyle',
          ),
          NavigationDestination(
            icon: Icon(Icons.piano_outlined),
            selectedIcon: Icon(Icons.piano_rounded),
            label: 'Chords',
          ),
        ],
      ),
    );
  }
}
