import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../request/domain/medical_request.dart';
import '../../request/data/request_repository.dart';

abstract class HistoryEvent extends Equatable { const HistoryEvent(); @override List<Object?> get props => []; }
class LoadHistory extends HistoryEvent {}
class DeleteHistoryItem extends HistoryEvent { final int requestId; const DeleteHistoryItem(this.requestId); @override List<Object?> get props => [requestId]; }

abstract class HistoryState extends Equatable { const HistoryState(); @override List<Object?> get props => []; }
class HistoryLoading extends HistoryState {}
class HistoryLoaded extends HistoryState { final List<MedicalRequest> requests; const HistoryLoaded(this.requests); @override List<Object?> get props => [requests]; }
class HistoryEmpty extends HistoryState {}
class HistoryError extends HistoryState { final String message; const HistoryError(this.message); @override List<Object?> get props => [message]; }

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final RequestRepository _repository;
  HistoryBloc({required RequestRepository repository}) : _repository = repository, super(HistoryLoading()) {
    on<LoadHistory>(_onLoadHistory);
    on<DeleteHistoryItem>(_onDeleteHistoryItem);
  }

  Future<void> _onLoadHistory(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final requests = await _repository.getAllRequests();
      if (requests.isEmpty) {
        emit(HistoryEmpty());
      } else {
        emit(HistoryLoaded(requests));
      }
    } catch (e) { emit(HistoryError(e.toString())); }
  }

  Future<void> _onDeleteHistoryItem(DeleteHistoryItem event, Emitter<HistoryState> emit) async {
    try { await _repository.deleteRequest(event.requestId); add(LoadHistory()); }
    catch (e) { emit(HistoryError(e.toString())); }
  }
}
