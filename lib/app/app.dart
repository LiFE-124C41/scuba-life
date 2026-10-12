import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/interface/controllers/auth_controller.dart';
import '../features/auth/interface/views/sign_in_page.dart';
import '../features/logbook/interface/views/dive_log_page.dart';
import '../features/marine_life/interface/views/marine_life_page.dart';
import '../features/my_gear/interface/views/my_gear_page.dart';
import '../features/schedule/interface/views/schedule_page.dart';

class ScubaLifeApp extends ConsumerWidget {
  const ScubaLifeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Scuba Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6), // オーシャンブルー
          brightness: Brightness.light,
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return const MainNavigationScreen();
          } else {
            return const SignInPage();
          }
        },
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => const SignInPage(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DiveLogPage(),
    MarineLifePage(),
    SchedulePage(),
    MyGearPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'ログブック',
          ),
          NavigationDestination(
            icon: Icon(Icons.set_meal_outlined),
            selectedIcon: Icon(Icons.set_meal),
            label: '生き物図鑑',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '予定管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: '機材管理',
          ),
        ],
      ),
    );
  }
}
