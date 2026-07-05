import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../items/presentation/items_bloc.dart';
import '../../items/domain/medical_item.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});
  @override State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() { super.initState(); context.read<ItemsBloc>().add(LoadItems()); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Medical Items')),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: TextField(
        controller: _searchController,
        onChanged: (v) { setState(() => _query = v); context.read<ItemsBloc>().add(SearchItems(v)); },
        decoration: InputDecoration(hintText: 'Search items...', prefixIcon: const Icon(Icons.search), suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _query = ''); context.read<ItemsBloc>().add(SearchItems('')); }) : null),
      )),
      Expanded(child: BlocBuilder<ItemsBloc, ItemsState>(builder: (_, state) {
        if (state is ItemsLoading) return const Center(child: CircularProgressIndicator());
        if (state is ItemsError) return Center(child: Text('Error: ${state.message}'));
        if (state is ItemsLoaded) {
          if (state.filteredItems.isEmpty) return EmptyStateWidget(icon: _query.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined, title: _query.isNotEmpty ? 'No items found' : 'No items imported yet', subtitle: _query.isNotEmpty ? 'Try a different search' : 'Import a Word document to add items');
          return ListView.builder(itemCount: state.filteredItems.length, itemBuilder: (_, i) => _ItemTile(item: state.filteredItems[i], query: _query));
        }
        return const SizedBox.shrink();
      })),
    ]),
  );
}

class _ItemTile extends StatelessWidget {
  final MedicalItem item; final String query;
  const _ItemTile({required this.item, required this.query});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: Text('${item.id}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 14))),
    title: _highlight(item.itemName, query),
    subtitle: item.category != null ? Text(item.category!) : null,
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.pushNamed(context, '/request', arguments: {'itemName': item.itemName, 'itemId': item.id}),
  );

  Widget _highlight(String text, String q) {
    if (q.isEmpty) return Text(text);
    final idx = text.toLowerCase().indexOf(q.toLowerCase());
    if (idx == -1) return Text(text);
    return RichText(text: TextSpan(style: const TextStyle(color: Colors.black87, fontSize: 16), children: [
      TextSpan(text: text.substring(0, idx)),
      TextSpan(text: text.substring(idx, idx + q.length), style: const TextStyle(backgroundColor: Colors.yellow, fontWeight: FontWeight.bold)),
      TextSpan(text: text.substring(idx + q.length)),
    ]));
  }
}
