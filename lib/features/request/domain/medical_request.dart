import 'package:equatable/equatable.dart';

class MedicalRequest extends Equatable {
  final int? id;
  final String? title;
  final String date;
  final String? department;
  final String? requester;
  final String? signature;
  final String status;

  const MedicalRequest({this.id, this.title, required this.date, this.department, this.requester, this.signature, this.status = 'draft'});

  MedicalRequest copyWith({int? id, String? title, String? date, String? department, String? requester, String? signature, String? status}) =>
      MedicalRequest(id: id ?? this.id, title: title ?? this.title, date: date ?? this.date, department: department ?? this.department, requester: requester ?? this.requester, signature: signature ?? this.signature, status: status ?? this.status);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'date': date, 'department': department, 'requester': requester, 'signature': signature, 'status': status};

  factory MedicalRequest.fromMap(Map<String, dynamic> map) => MedicalRequest(
    id: map['id'] as int?, title: map['title'] as String?, date: map['date'] as String,
    department: map['department'] as String?, requester: map['requester'] as String?,
    signature: map['signature'] as String?, status: map['status'] as String? ?? 'draft',
  );

  @override List<Object?> get props => [id, title, date, department, requester, signature, status];
}
