import 'package:equatable/equatable.dart';

class MedicalItem extends Equatable {
  final int? id;
  final String itemName;
  final String? category;
  final String? createdAt;
  final String? updatedAt;

  const MedicalItem({this.id, required this.itemName, this.category, this.createdAt, this.updatedAt});

  MedicalItem copyWith({int? id, String? itemName, String? category, String? createdAt, String? updatedAt}) =>
      MedicalItem(id: id ?? this.id, itemName: itemName ?? this.itemName, category: category ?? this.category, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);

  Map<String, dynamic> toMap() => {'id': id, 'itemName': itemName, 'category': category, 'createdAt': createdAt, 'updatedAt': updatedAt};

  factory MedicalItem.fromMap(Map<String, dynamic> map) => MedicalItem(
    id: map['id'] as int?, itemName: map['itemName'] as String, category: map['category'] as String?,
    createdAt: map['createdAt'] as String?, updatedAt: map['updatedAt'] as String?,
  );

  @override List<Object?> get props => [id, itemName, category];
}
