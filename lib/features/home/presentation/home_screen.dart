import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../import/presentation/import_screen.dart';
import '../../request/presentation/request_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../items/presentation/items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const _DashboardPage(), const ItemsScreen(), const HistoryScreen()];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _screens[_currentIndex],
    bottomNavigationBar: NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) => setState(() => _currentIndex = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Items'),
        NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
      ],
    ),
  );
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Medical Request'), actions: [
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())), icon: const Icon(Icons.upload_file), tooltip: 'Import Items'),
    ]),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome to Medical Request', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Text('Create medical supply requests quickly using voice or manual entry.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
          ]))),
          const SizedBox(height: 24),
          Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionCard(icon: Icons.add_circle, title: 'New Request', color: AppTheme.primaryColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(icon: Icons.upload_file, title: 'Import Items', color: AppTheme.accentColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen())))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _ActionCard(icon: Icons.search, title: 'Browse Items', color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _ActionCard(icon: Icons.history, title: 'History', color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())))),
          ]),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.lightbulb_outline, color: Colors.amber[700]), const SizedBox(width: 8), Text('Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            _tip('Tap the microphone icon to enter items by voice'),
            _tip('Supports Arabic and English speech recognition'),
            _tip('Say numbers in Arabic or English for quantities'),
            _tip('Export requests as Word documents to share'),
          ]))),
        ],
      ),
    ),
  );

  Widget _tip(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Expanded(child: Text(t, style: const TextStyle(fontSize: 14)))]));
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(child: InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    ])),
  ));
}
