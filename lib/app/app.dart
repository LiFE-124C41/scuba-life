import 'package:flutter/material.dart';
import '../features/logbook/interface/views/dive_log_page.dart';
import '../features/my_gear/interface/views/my_gear_page.dart';
import '../features/schedule/interface/views/schedule_page.dart';

class ScubaLifeApp extends StatelessWidget {
  const ScubaLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: const MainNavigationScreen(),
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

