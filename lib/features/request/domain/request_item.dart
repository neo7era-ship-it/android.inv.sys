import 'package:equatable/equatable.dart';

class RequestItem extends Equatable {
  final int? id;
  final int requestId;
  final int? itemId;
  final String itemName;
  final int quantity;
  final String? notes;
  final int orderIndex;

  const RequestItem({this.id, required this.requestId, this.itemId, required this.itemName, this.quantity = 0, this.notes, this.orderIndex = 0});

  RequestItem copyWith({int? id, int? requestId, int? itemId, String? itemName, int? quantity, String? notes, int? orderIndex}) =>
      RequestItem(id: id ?? this.id, requestId: requestId ?? this.requestId, itemId: itemId ?? this.itemId, itemName: itemName ?? this.itemName, quantity: quantity ?? this.quantity, notes: notes ?? this.notes, orderIndex: orderIndex ?? this.orderIndex);

  Map<String, dynamic> toMap() => {'id': id, 'requestId': requestId, 'itemId': itemId, 'itemName': itemName, 'quantity': quantity, 'notes': notes, 'orderIndex': orderIndex};

  factory RequestItem.fromMap(Map<String, dynamic> map) => RequestItem(
    id: map['id'] as int?, requestId: map['requestId'] as int, itemId: map['itemId'] as int?,
    itemName: map['itemName'] as String, quantity: map['quantity'] as int? ?? 0,
    notes: map['notes'] as String?, orderIndex: map['orderIndex'] as int? ?? 0,
  );

  @override List<Object?> get props => [id, requestId, itemId, itemName, quantity, notes, orderIndex];
}
