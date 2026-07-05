import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/medical_request.dart';
import '../domain/request_item.dart';

class RequestRepository {
  final DatabaseHelper _dbHelper;
  RequestRepository({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  Future<MedicalRequest> createRequest(MedicalRequest request) async {
    final db = await _dbHelper.database;
    final id = await db.insert(AppConstants.requestsTable, request.toMap());
    return request.copyWith(id: id);
  }

  Future<MedicalRequest?> getRequest(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.requestsTable, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return MedicalRequest.fromMap(maps.first);
  }

  Future<List<MedicalRequest>> getAllRequests() async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.requestsTable, orderBy: 'createdAt DESC');
    return maps.map((m) => MedicalRequest.fromMap(m)).toList();
  }

  Future<int> updateRequest(MedicalRequest request) async {
    final db = await _dbHelper.database;
    return await db.update(AppConstants.requestsTable, request.toMap()..['updatedAt'] = DateTime.now().toIso8601String(), where: 'id = ?', whereArgs: [request.id]);
  }

  Future<int> deleteRequest(int id) async {
    final db = await _dbHelper.database;
    await db.delete(AppConstants.requestItemsTable, where: 'requestId = ?', whereArgs: [id]);
    return await db.delete(AppConstants.requestsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<RequestItem> addRequestItem(RequestItem item) async {
    final db = await _dbHelper.database;
    final id = await db.insert(AppConstants.requestItemsTable, item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<RequestItem>> getRequestItems(int requestId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.requestItemsTable, where: 'requestId = ?', whereArgs: [requestId], orderBy: 'orderIndex ASC');
    return maps.map((m) => RequestItem.fromMap(m)).toList();
  }

  Future<int> updateRequestItem(RequestItem item) async {
    final db = await _dbHelper.database;
    return await db.update(AppConstants.requestItemsTable, item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<int> deleteRequestItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(AppConstants.requestItemsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderRequestItems(int requestId, List<RequestItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (int i = 0; i < items.length; i++) {
        await txn.update(AppConstants.requestItemsTable, {'orderIndex': i}, where: 'id = ?', whereArgs: [items[i].id]);
      }
    });
  }
}
