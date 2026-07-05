import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../domain/medical_request.dart';
import '../domain/request_item.dart';
import '../data/request_repository.dart';

abstract class RequestEvent extends Equatable { const RequestEvent(); @override List<Object?> get props => []; }
class CreateNewRequest extends RequestEvent { final String? title; final String? department; final String? requester; const CreateNewRequest({this.title, this.department, this.requester}); }
class LoadRequest extends RequestEvent { final int requestId; const LoadRequest(this.requestId); @override List<Object?> get props => [requestId]; }
class SaveRequest extends RequestEvent {}
class UpdateRequestHeader extends RequestEvent { final String? title; final String? department; final String? requester; final String? signature; const UpdateRequestHeader({this.title, this.department, this.requester, this.signature}); }
class AddItemToRequest extends RequestEvent { final String itemName; final int? itemId; const AddItemToRequest({required this.itemName, this.itemId}); }
class RemoveItemFromRequest extends RequestEvent { final int itemId; const RemoveItemFromRequest(this.itemId); @override List<Object?> get props => [itemId]; }
class UpdateItemQuantity extends RequestEvent { final int itemId; final int quantity; const UpdateItemQuantity(this.itemId, this.quantity); @override List<Object?> get props => [itemId, quantity]; }
class UpdateItemNotes extends RequestEvent { final int itemId; final String notes; const UpdateItemNotes(this.itemId, this.notes); @override List<Object?> get props => [itemId, notes]; }
class UpdateItemName extends RequestEvent { final int itemId; final String itemName; const UpdateItemName(this.itemId, this.itemName); @override List<Object?> get props => [itemId, itemName]; }
class ReorderItems extends RequestEvent { final int oldIndex; final int newIndex; const ReorderItems(this.oldIndex, this.newIndex); @override List<Object?> get props => [oldIndex, newIndex]; }
class DeleteRequestEvt extends RequestEvent { final int requestId; const DeleteRequestEvt(this.requestId); @override List<Object?> get props => [requestId]; }
class MarkAsExported extends RequestEvent {}

abstract class RequestState extends Equatable { const RequestState(); @override List<Object?> get props => []; }
class RequestInitial extends RequestState {}
class RequestLoading extends RequestState {}
class RequestEditing extends RequestState { final MedicalRequest request; final List<RequestItem> items; final bool isModified; const RequestEditing({required this.request, this.items = const [], this.isModified = false}); @override List<Object?> get props => [request, items, isModified]; RequestEditing copyWith({MedicalRequest? request, List<RequestItem>? items, bool? isModified}) => RequestEditing(request: request ?? this.request, items: items ?? this.items, isModified: isModified ?? this.isModified); }
class RequestSaved extends RequestState { final MedicalRequest request; const RequestSaved(this.request); @override List<Object?> get props => [request]; }
class RequestError extends RequestState { final String message; const RequestError(this.message); @override List<Object?> get props => [message]; }

class RequestBloc extends Bloc<RequestEvent, RequestState> {
  final RequestRepository _repository;
  RequestBloc({required RequestRepository repository}) : _repository = repository, super(RequestInitial()) {
    on<CreateNewRequest>(_onCreateNewRequest);
    on<LoadRequest>(_onLoadRequest);
    on<SaveRequest>(_onSaveRequest);
    on<UpdateRequestHeader>(_onUpdateRequestHeader);
    on<AddItemToRequest>(_onAddItemToRequest);
    on<RemoveItemFromRequest>(_onRemoveItemFromRequest);
    on<UpdateItemQuantity>(_onUpdateItemQuantity);
    on<UpdateItemNotes>(_onUpdateItemNotes);
    on<UpdateItemName>(_onUpdateItemName);
    on<ReorderItems>(_onReorderItems);
    on<MarkAsExported>(_onMarkAsExported);
  }

  Future<void> _onCreateNewRequest(CreateNewRequest event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    try {
      final request = MedicalRequest(title: event.title, date: DateTime.now().toIso8601String().split('T')[0], department: event.department, requester: event.requester, status: 'draft');
      final saved = await _repository.createRequest(request);
      emit(RequestEditing(request: saved, items: []));
    } catch (e) { emit(RequestError(e.toString())); }
  }

  Future<void> _onLoadRequest(LoadRequest event, Emitter<RequestState> emit) async {
    emit(RequestLoading());
    try {
      final request = await _repository.getRequest(event.requestId);
      if (request == null) { emit(const RequestError('Request not found')); return; }
      final items = await _repository.getRequestItems(event.requestId);
      emit(RequestEditing(request: request, items: items));
    } catch (e) { emit(RequestError(e.toString())); }
  }

  Future<void> _onSaveRequest(SaveRequest event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    try { await _repository.updateRequest(cur.request); emit(cur.copyWith(isModified: false)); emit(RequestSaved(cur.request)); emit(cur.copyWith(isModified: false)); }
    catch (e) { emit(RequestError(e.toString())); }
  }

  Future<void> _onUpdateRequestHeader(UpdateRequestHeader event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    emit(cur.copyWith(request: cur.request.copyWith(title: event.title, department: event.department, requester: event.requester, signature: event.signature), isModified: true));
  }

  Future<void> _onAddItemToRequest(AddItemToRequest event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    if (cur.items.any((i) => i.itemName.toLowerCase() == event.itemName.toLowerCase())) { emit(const RequestError('Item already in request')); emit(cur); return; }
    final newItem = RequestItem(requestId: cur.request.id!, itemId: event.itemId, itemName: event.itemName, quantity: 1, orderIndex: cur.items.length);
    final saved = await _repository.addRequestItem(newItem);
    emit(cur.copyWith(items: [...cur.items, saved], isModified: true));
  }

  Future<void> _onRemoveItemFromRequest(RemoveItemFromRequest event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    await _repository.deleteRequestItem(event.itemId);
    final updated = cur.items.where((i) => i.id != event.itemId).toList();
    emit(cur.copyWith(items: updated, isModified: true));
  }

  Future<void> _onUpdateItemQuantity(UpdateItemQuantity event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    final updated = cur.items.map((i) { if (i.id == event.itemId) { final u = i.copyWith(quantity: event.quantity); _repository.updateRequestItem(u); return u; } return i; }).toList();
    emit(cur.copyWith(items: updated, isModified: true));
  }

  Future<void> _onUpdateItemNotes(UpdateItemNotes event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    final updated = cur.items.map((i) { if (i.id == event.itemId) { final u = i.copyWith(notes: event.notes); _repository.updateRequestItem(u); return u; } return i; }).toList();
    emit(cur.copyWith(items: updated, isModified: true));
  }

  Future<void> _onUpdateItemName(UpdateItemName event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    final updated = cur.items.map((i) { if (i.id == event.itemId) { final u = i.copyWith(itemName: event.itemName); _repository.updateRequestItem(u); return u; } return i; }).toList();
    emit(cur.copyWith(items: updated, isModified: true));
  }

  Future<void> _onReorderItems(ReorderItems event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    final items = List<RequestItem>.from(cur.items);
    final item = items.removeAt(event.oldIndex);
    items.insert(event.newIndex, item);
    for (int i = 0; i < items.length; i++) { items[i] = items[i].copyWith(orderIndex: i); }
    await _repository.reorderRequestItems(cur.request.id!, items);
    emit(cur.copyWith(items: items, isModified: true));
  }

  Future<void> _onMarkAsExported(MarkAsExported event, Emitter<RequestState> emit) async {
    if (state is! RequestEditing) return;
    final cur = state as RequestEditing;
    final updated = cur.request.copyWith(status: 'exported');
    await _repository.updateRequest(updated);
    emit(cur.copyWith(request: updated, isModified: false));
  }
}
