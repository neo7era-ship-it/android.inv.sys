import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/docx_utils.dart';
import '../../../core/database/database_helper.dart';
import '../../items/data/medical_item_repository.dart';
import '../../items/presentation/items_bloc.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});
  @override State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;
  String _statusMessage = '';
  int _importedCount = 0;
  int _totalItems = 0;
  String? _selectedFileName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import Master List')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.description, size: 48, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          Text('Import Word Document', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Select a .docx file containing the master list. Each line becomes an item.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ]))),
        const SizedBox(height: 24),
        if (_selectedFileName != null) Card(color: Colors.blue[50], child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.insert_drive_file, color: AppTheme.primaryColor), const SizedBox(width: 8), Expanded(child: Text(_selectedFileName!, style: const TextStyle(fontSize: 14)))]))),
        if (_isImporting) ...[const SizedBox(height: 20), const LinearProgressIndicator(), const SizedBox(height: 12), Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))],
        if (_importedCount > 0 && !_isImporting) Card(color: Colors.green[50], child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [const Icon(Icons.check_circle, color: Colors.green, size: 48), const SizedBox(height: 8), Text('Import Complete!', style: Theme.of(context).textTheme.titleMedium), Text('$_importedCount items imported (Total: $_totalItems)')]))),
        const Spacer(),
        ElevatedButton.icon(onPressed: _isImporting ? null : () => _pickAndImport(true), icon: const Icon(Icons.upload_file), label: const Text('Replace All Items')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _isImporting ? null : () => _pickAndImport(false), icon: const Icon(Icons.add), label: const Text('Add to Existing Items')),
      ],
    )),
  );

  Future<void> _pickAndImport(bool replace) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['docx']);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() { _selectedFileName = file.name; _isImporting = true; _statusMessage = 'Reading document...'; _importedCount = 0; });

      List<String> lines;
      if (file.path != null) {
        lines = await DocxUtils.extractTextFromFile(file.path!);
      } else if (file.bytes != null) lines = DocxUtils.extractTextFromBytes(file.bytes!);
      else throw Exception('Cannot read file');

      setState(() => _statusMessage = 'Parsing items...');
      final items = DocxUtils.parseItemsFromText(lines);
      if (items.isEmpty) { setState(() { _isImporting = false; _statusMessage = 'No items found'; }); return; }

      setState(() => _statusMessage = 'Saving to database...');
      if (mounted) context.read<ItemsBloc>().add(ImportItems(items, replaceExisting: replace));

      final repo = MedicalItemRepository(dbHelper: DatabaseHelper());
      final allItems = await repo.getAllItems();
      setState(() { _isImporting = false; _importedCount = items.length; _totalItems = allItems.length; _statusMessage = ''; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${items.length} items')));
    } catch (e) {
      setState(() { _isImporting = false; _statusMessage = 'Error: ${e.toString()}'; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
}
