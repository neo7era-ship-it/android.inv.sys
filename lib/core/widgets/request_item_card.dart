import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/request/domain/request_item.dart';
import '../../core/widgets/voice_input_button.dart';

class RequestItemCard extends StatelessWidget {
  final RequestItem item;
  final int displayIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onNotesEdit;
  final bool isListeningQuantity;
  final bool isListeningNotes;
  final VoidCallback onVoiceQuantity;
  final VoidCallback onVoiceNotes;

  const RequestItemCard({
    super.key, required this.item, required this.displayIndex, required this.onEdit,
    required this.onDelete, required this.onQuantityChanged, required this.onNotesEdit,
    this.isListeningQuantity = false, this.isListeningNotes = false,
    required this.onVoiceQuantity, required this.onVoiceNotes,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle), alignment: Alignment.center, child: Text('$displayIndex', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(width: 12),
            Expanded(child: Text(item.itemName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit, size: 22), color: AppTheme.primaryColor),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 22), color: AppTheme.errorColor),
          ]),
          const Divider(height: 16),
          Row(children: [
            const Text('Quantity: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            IconButton(onPressed: item.quantity > 0 ? () => onQuantityChanged(item.quantity - 1) : null, icon: const Icon(Icons.remove_circle_outline), iconSize: 28, color: AppTheme.primaryColor),
            Container(width: 56, height: 40, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryColor, width: 1.5), borderRadius: BorderRadius.circular(8)), child: Text('${item.quantity}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
            IconButton(onPressed: () => onQuantityChanged(item.quantity + 1), icon: const Icon(Icons.add_circle_outline), iconSize: 28, color: AppTheme.primaryColor),
            VoiceInputButton(isListening: isListeningQuantity, onTap: onVoiceQuantity, size: 40),
          ]),
          const SizedBox(height: 8),
          InkWell(onTap: onNotesEdit, child: Row(children: [
            const Icon(Icons.note_alt_outlined, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(item.notes?.isNotEmpty == true ? item.notes! : 'Add notes...', style: TextStyle(fontSize: 15, color: item.notes?.isNotEmpty == true ? Colors.black87 : Colors.grey, fontStyle: item.notes?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
            VoiceInputButton(isListening: isListeningNotes, onTap: onVoiceNotes, size: 36),
          ])),
        ],
      ),
    ),
  );
}
