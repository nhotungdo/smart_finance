import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';
import 'package:smart_finance/data/repositories/transaction_repository.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/invoice_model.dart';

class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CategoryRepository _categoryRepo;
  final TransactionRepository _transactionRepo;
  final InvoiceRepository _invoiceRepo;

  SyncService(this._categoryRepo, this._transactionRepo, this._invoiceRepo);

  Future<void> sync(String? companyId, String? userId) async {
    // 1. Push Local data to Cloud
    await _pushCategories();
    await _pushTransactions();
    await _pushInvoices();

    // 2. Pull Cloud data to Local
    // If we have a user logged in, we sync their data
    if (userId != null || companyId != null) {
      await _pullCategories(companyId, userId);
      await _pullTransactions(companyId, userId);
      await _pullInvoices(companyId, userId);
    }
  }

  Future<void> _pushCategories() async {
    final unsynced = await _categoryRepo.getUnsyncedCategories();
    if (unsynced.isEmpty) return;

    final dataToPush = unsynced.map((e) {
      final map = e.toMap();
      map.remove('is_synced'); // Remove local-only field before uploading
      return map;
    }).toList();

    try {
      await _supabase.from('categories').upsert(dataToPush);
      final syncedIds = unsynced.map((e) => e.categoryId).toList();
      await _categoryRepo.markAsSynced(syncedIds);
    } catch (e) {
      // Throw error to be caught by Provider
      throw Exception('Lỗi đẩy Categories lên cloud: $e');
    }
  }

  Future<void> _pushTransactions() async {
    final unsynced = await _transactionRepo.getUnsyncedTransactions();
    if (unsynced.isEmpty) return;

    final dataToPush = unsynced.map((e) {
      final map = e.toMap();
      map.remove('is_synced'); // Remove local-only field
      return map;
    }).toList();

    try {
      await _supabase.from('transactions').upsert(dataToPush);
      final syncedIds = unsynced.map((e) => e.transactionId).toList();
      await _transactionRepo.markAsSynced(syncedIds);
    } catch (e) {
      throw Exception('Lỗi đẩy Transactions lên cloud: $e');
    }
  }

  Future<void> _pushInvoices() async {
    final unsynced = await _invoiceRepo.getUnsyncedInvoices();
    if (unsynced.isEmpty) return;

    final dataToPush = unsynced.map((e) {
      final map = e.toMap();
      map.remove('is_synced');
      return map;
    }).toList();

    try {
      await _supabase.from('invoices').upsert(dataToPush);
      final syncedIds = unsynced.map((e) => e.id).toList();
      await _invoiceRepo.markAsSynced(syncedIds);
    } catch (e) {
      throw Exception('Lỗi đẩy Invoices lên cloud: $e');
    }
  }

  Future<void> _pullCategories(String? companyId, String? userId) async {
    try {
      var query = _supabase.from('categories').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }
      
      final response = await query;
      for (final item in response) {
        final category = CategoryModel.fromMap(item);
        await _categoryRepo.upsertCategoryFromCloud(category);
      }
    } catch (e) {
      throw Exception('Lỗi tải Categories về máy: $e');
    }
  }

  Future<void> _pullTransactions(String? companyId, String? userId) async {
    try {
      var query = _supabase.from('transactions').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else if (userId != null) {
        query = query.eq('created_by', userId);
      }
      
      final response = await query;
      for (final item in response) {
        final transaction = TransactionModel.fromMap(item);
        await _transactionRepo.upsertTransactionFromCloud(transaction);
      }
    } catch (e) {
      throw Exception('Lỗi tải Transactions về máy: $e');
    }
  }

  Future<void> _pullInvoices(String? companyId, String? userId) async {
    try {
      var query = _supabase.from('invoices').select();
      if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else if (userId != null) {
        query = query.eq('uploaded_by', userId);
      }
      
      final response = await query;
      for (final item in response) {
        final invoice = InvoiceModel.fromMap(item);
        await _invoiceRepo.upsertInvoiceFromCloud(invoice);
      }
    } catch (e) {
      throw Exception('Lỗi tải Invoices về máy: $e');
    }
  }
}
