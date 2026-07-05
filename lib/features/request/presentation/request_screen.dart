import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/docx_utils.dart';
import '../../../core/utils/number_parser.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/widgets/request_item_card.dart';
import '../../../core/widgets/empty_state_widget.dart';

import '../presentation/request_bloc.dart';
import '../domain/request_item.dart';
import '../../items/data/medical_item_repository.dart';
import '../../items/domain/medical_item.dart';

class RequestScreen extends StatefulWidget {
  final int? requestId;
  const RequestScreen({super.key, this.requestId});
  @override State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  late SpeechService _speech;
  bool _speechReady = false;
  String _voiceTarget = '';
  int? _voiceItemId;
  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  List<MedicalItem> _searchResults = [];

  // track whether department/requester text should be RTL
  bool _deptIsRtl = false;
  bool _reqIsRtl = false;

  @override
  void initState() {
    super.initState();
    _speech = SpeechService();
    _initSpeech();

    // detect Arabic characters in department and requester and update direction
    _deptCtrl.addListener(() {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_deptCtrl.text);
      if (hasArabic != _deptIsRtl) setState(() => _deptIsRtl = hasArabic);
    });
    _reqCtrl.addListener(() {
      final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(_reqCtrl.text);
      if (hasArabic != _reqIsRtl) setState(() => _reqIsRtl = hasArabic);
    });

    if (widget.requestId != null) {
      context.read<RequestBloc>().add(LoadRequest(widget.requestId!));
    } else {
      context.read<RequestBloc>().add(CreateNewRequest());
    }
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize();
    _speech.onResult.listen(_onSpeechResult);
    // surface errors/status to UI for easier debugging
    _speech.onError.listen((e) { if (mounted && e.isNotEmpty) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Speech error: $e'))); });
    _speech.onStatus.listen((s) => debugPrint('speech status: $s'));
  }

  void _onSpeechResult(String result) {
    if (result.isEmpty) return;
    if (_voiceTarget == 'search') { _searchCtrl.text = result; _doSearch(result); }
    else if (_voiceTarget.startsWith('qty-')) { final v = NumberParser.parse(result); if (v != null && _voiceItemId != null) context.read<RequestBloc>().add(UpdateItemQuantity(_voiceItemId!, v)); }
    else if (_voiceTarget.startsWith('notes-')) { if (_voiceItemId != null) context.read<RequestBloc>().add(UpdateItemNotes(_voiceItemId!, result)); }
    setState(() => _voiceTarget = '');
  }

  Future<void> _startVoice(String target, {int? itemId, String locale = 'en_US'}) async {
    if (!_speechReady) { _speechReady = await _speech.initialize(); if (!_speechReady) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition unavailable'))); return; } }
    setState(() { _voiceTarget = target; _voiceItemId = itemId; });
    await _speech.startListening(localeId: locale);
  }

  Future<void> _doSearch(String q) async {
    if (q.isEmpty) { setState(() => _searchResults = []); return; }
    final repo = MedicalItemRepository(dbHelper: DatabaseHelper());
    final results = await repo.searchItems(q);
    setState(() => _searchResults = results);
  }

  @override
  void dispose() { _speech.dispose(); _searchCtrl.dispose(); _titleCtrl.dispose(); _deptCtrl.dispose(); _reqCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New Request'), actions: [
      IconButton(onPressed: _export, icon: const Icon(Icons.file_download), tooltip: 'Export'),
      PopupMenuButton(itemBuilder: (_) => [const PopupMenuItem(value: 'save', child: Text('Save Draft')), const PopupMenuItem(value: 'export', child: Text('Export Word')), const PopupMenuItem(value: 'share', child: Text('Share'))], onSelected: (v) {
        if (v == 'save') { context.read<RequestBloc>().add(SaveRequest()); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved'))); }
        else if (v == 'export') _export();
        else if (v == 'share') _share();
      }),
    ]),
    body: BlocConsumer<RequestBloc, RequestState>(
      listener: (_, state) {
        if (state is RequestError) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
        if (state is RequestEditing) { _titleCtrl.text = state.request.title ?? ''; _deptCtrl.text = state.request.department ?? ''; _reqCtrl.text = state.request.requester ?? ''; }
      },
      builder: (_, state) {
        if (state is RequestLoading) return const Center(child: CircularProgressIndicator());
        if (state is RequestEditing) return _buildEditor(state);
        return const Center(child: Text('Create a new request to begin'));
      },
    ),
  );

  Widget _buildEditor(RequestEditing state) => Column(children: [
    ExpansionTile(initiallyExpanded: state.request.title == null, title: Text(state.request.title ?? 'Request Details', style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text('${state.request.date}')),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title'), onChanged: (_) => _updateHeader()),
        const SizedBox(height: 8),
        TextField(
          controller: _deptCtrl,
          decoration: const InputDecoration(labelText: 'Department'),
          onChanged: (_) => _updateHeader(),
          textAlign: _deptIsRtl ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reqCtrl,
          decoration: const InputDecoration(labelText: 'Requested By'),
          onChanged: (_) => _updateHeader(),
          textAlign: _reqIsRtl ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 16),
    ])),
    Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [Expanded(child: TextField(controller: _searchCtrl, onChanged: _doSearch, decoration: InputDecoration(hintText: 'Search items to add...', prefixIcon: const Icon(Icons.search), suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_searchCtrl.text.isNotEmpty) IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchResults = []); }),
        IconButton(icon: const Icon(Icons.mic, color: AppTheme.primaryColor), onPressed: () async { final loc = await _speech.pickLocale(['ar_SA','ar-SA','ar','en_US']); await _startVoice('search', locale: loc ?? 'en_US'); }),
      ]))))]),
      if (_searchResults.isNotEmpty) Container(constraints: BoxConstraints(maxHeight: 200), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: ListView.builder(shrinkWrap: true, itemCount: _searchResults.length, itemBuilder: (_, i) {
        final item = _searchResults[i];
        return ListTile(dense: true, title: Text(item.itemName), trailing: const Icon(Icons.add_circle, color: AppTheme.accentColor), onTap: () {
          context.read<RequestBloc>().add(AddItemToRequest(itemName: item.itemName, itemId: item.id));
          _searchCtrl.clear(); setState(() => _searchResults = []);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added: ${item.itemName}')));
        });
      })),
    ])),
    Expanded(child: state.items.isEmpty ? const EmptyStateWidget(icon: Icons.add_shopping_cart, title: 'No items added yet', subtitle: 'Search or use voice to add medical items') : ReorderableListView.builder(
      onReorder: (o, n) => context.read<RequestBloc>().add(ReorderItems(o, n)),
      itemCount: state.items.length,
      itemBuilder: (_, i) {
        final item = state.items[i];
        return RequestItemCard(key: ValueKey(item.id), item: item, displayIndex: i + 1,
          onEdit: () => _editItemDialog(item), onDelete: () => _confirmDelete(item),
          onQuantityChanged: (q) => context.read<RequestBloc>().add(UpdateItemQuantity(item.id!, q)),
          onNotesEdit: () => _notesDialog(item),
          isListeningQuantity: _voiceTarget == 'qty-${item.id}',
          isListeningNotes: _voiceTarget == 'notes-${item.id}',
          onVoiceQuantity: () async { final loc = await _speech.pickLocale(['ar_SA','ar-SA','ar','en_US']); await _startVoice('qty-${item.id}', itemId: item.id, locale: loc ?? 'en_US'); },
          onVoiceNotes: () => _startVoice('notes-${item.id}', itemId: item.id, locale: 'ar_SA'),
        );
      },
    )),
  ]);

  void _updateHeader() => context.read<RequestBloc>().add(UpdateRequestHeader(title: _titleCtrl.text, department: _deptCtrl.text, requester: _reqCtrl.text));

  void _editItemDialog(RequestItem item) {
    final nameC = TextEditingController(text: item.itemName);
    final qtyC = TextEditingController(text: item.quantity.toString());
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Edit Item'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Item Name')),
      const SizedBox(height: 12),
      TextField(controller: qtyC, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(_), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { context.read<RequestBloc>().add(UpdateItemName(item.id!, nameC.text)); final q = int.tryParse(qtyC.text); if (q != null) context.read<RequestBloc>().add(UpdateItemQuantity(item.id!, q)); Navigator.pop(_); }, child: const Text('Save')),
    ]));
  }

  void _notesDialog(RequestItem item) {
    final c = TextEditingController(text: item.notes ?? '');
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Notes'), content: TextField(controller: c, maxLines: 3), actions: [
      TextButton(onPressed: () => Navigator.pop(_), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { context.read<RequestBloc>().add(UpdateItemNotes(item.id!, c.text)); Navigator.pop(_); }, child: const Text('Save')),
    ]));
  }

  void _confirmDelete(RequestItem item) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Delete Item'), content: Text('Remove "${item.itemName}"?'), actions: [
      TextButton(onPressed: () => Navigator.pop(_), child: const Text('Cancel')),
      ElevatedButton(onPressed: () { context.read<RequestBloc>().add(RemoveItemFromRequest(item.id!)); Navigator.pop(_); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
    ]));
  }

  Future<void> _export() async {
    final s = context.read<RequestBloc>().state;
    if (s is! RequestEditing || s.items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to export'))); return; }
    try {
      final items = s.items.asMap().entries.map((e) => {'index': e.key + 1, 'itemName': e.value.itemName, 'quantity': e.value.quantity, 'notes': e.value.notes ?? ''}).toList();
      final bytes = await DocxUtils.createRequestDocx(title: s.request.title ?? 'Medical Request', date: s.request.date, department: s.request.department, requester: s.request.requester, items: items);
      final dir = await getApplicationDocumentsDirectory();
      final name = 'medical_request_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.docx';
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bytes);
      context.read<RequestBloc>().add(MarkAsExported());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $name'), action: SnackBarAction(label: 'Share', onPressed: () => Share.shareXFiles([XFile(path)]))));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'))); }
  }

  Future<void> _share() async {
    final s = context.read<RequestBloc>().state;
    if (s is! RequestEditing || s.items.isEmpty) return;
    try {
      final items = s.items.asMap().entries.map((e) => {'index': e.key + 1, 'itemName': e.value.itemName, 'quantity': e.value.quantity, 'notes': e.value.notes ?? ''}).toList();
      final bytes = await DocxUtils.createRequestDocx(title: s.request.title ?? 'Medical Request', date: s.request.date, department: s.request.department, requester: s.request.requester, items: items);
      final dir = await getApplicationDocumentsDirectory();
      final name = 'medical_request_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.docx';
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'Medical Supply Request');
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e'))); }
  }
}
