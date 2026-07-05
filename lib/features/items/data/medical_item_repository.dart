import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/medical_item.dart';

class MedicalItemRepository {
  final DatabaseHelper _dbHelper;
  MedicalItemRepository({required DatabaseHelper dbHelper}) : _dbHelper = dbHelper;

  Future<List<MedicalItem>> getAllItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.medicalItemsTable, orderBy: 'itemName ASC');
    return maps.map((m) => MedicalItem.fromMap(m)).toList();
  }

  Future<List<MedicalItem>> searchItems(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(AppConstants.medicalItemsTable, where: 'itemName LIKE ?', whereArgs: ['%$query%'], orderBy: 'itemName ASC', limit: 50);
    return maps.map((m) => MedicalItem.fromMap(m)).toList();
  }

  Future<int> insertItemsBatch(List<MedicalItem> items) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      for (final item in items) {
        final existing = await txn.query(AppConstants.medicalItemsTable, where: 'itemName = ?', whereArgs: [item.itemName], limit: 1);
        if (existing.isEmpty) {
          await txn.insert(AppConstants.medicalItemsTable, item.toMap());
          count++;
        }
      }
    });
    return count;
  }

  Future<int> deleteAllItems() async {
    final db = await _dbHelper.database;
    return await db.delete(AppConstants.medicalItemsTable);
  }

  Future<int> getItemCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${AppConstants.medicalItemsTable}');
    return result.first['count'] as int? ?? 0;
  }

  Future<int> replaceAllItems(List<MedicalItem> items) async {
    final db = await _dbHelper.database;
    int count = 0;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.medicalItemsTable);
      for (final item in items) {
        await txn.insert(AppConstants.medicalItemsTable, item.toMap());
        count++;
      }
    });
    return count;
  }
}
