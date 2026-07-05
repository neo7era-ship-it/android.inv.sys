import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../import/presentation/import_screen.dart';
import '../../request/presentation/request_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../items/presentation/items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override 
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const _DashboardPage(), 
    const ItemsScreen(), 
    const HistoryScreen()
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screens[_currentIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined), 
          selectedIcon: Icon(Icons.dashboard), 
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined), 
          selectedIcon: Icon(Icons.inventory_2), 
          label: 'Items',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined), 
          selectedIcon: Icon(Icons.history), 
          label: 'History',
        ),
      ],
    ),
  );
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Medical Request'), 
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const ImportScreen()),
          ), 
          icon: const Icon(Icons.upload_file), 
          tooltip: 'Import Items',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  'Welcome to Medical Request', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
