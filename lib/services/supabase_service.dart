import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/expense_model.dart';

class SupabaseService {
  // ── 1. INISIALISASI SUPABASE CLIENT ────────────────────────────────
  static final supabase = Supabase.instance.client;

  // ── (CATATAN) BUKU RESEP MASTER (BOM) & CACHE ──────────────────────
  // Jika Anda ingin ini tersimpan di internet, Anda harus membuat 
  // tabel 'recipes' di Supabase. Untuk sementara, kita biarkan logic cache
  // lokal Anda atau sesuaikan dengan table Supabase Anda nantinya.
  static final List<Map<String, dynamic>> _productionHistoryCache = [];
  static List<Map<String, dynamic>> getProductionHistoryCache() => _productionHistoryCache;
  static void updateProductionHistoryCache(List<Map<String, dynamic>> cache) {
    _productionHistoryCache.clear();
    _productionHistoryCache.addAll(cache);
  }


  // ── 2. CRUD PRODUK ─────────────────────────────────────────────────
  static Future<List<ProductModel>> getProducts() async {
    try {
      // Mengambil data nyata dari tabel 'products'
      final response = await supabase.from('products').select();
      
      return (response as List).map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      // Sesuai best practice sebelumnya, gunakan rethrow agar jejak error mudah di-debug
      rethrow; 
    }
  }

  static Future<void> addProduct(ProductModel product) async {
    try {
      await supabase.from('products').insert(product.toJson());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateProduct(ProductModel product) async {
    try {
      await supabase.from('products').update(product.toJson()).eq('id', product.id);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteProduct(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> decreaseStock(String productId, int quantity) async {
    try {
      // Ambil stok produk saat ini
      final response = await supabase.from('products').select('stock').eq('id', productId).single();
      final currentStock = response['stock'] as int;
      
      // Hitung stok baru, pastikan tidak minus
      final newStock = (currentStock - quantity).clamp(0, 999999);
      
      // Update data stok di database
      await supabase.from('products').update({'stock': newStock}).eq('id', productId);
    } catch (e) {
      rethrow;
    }
  }


  // ── 3. TRANSAKSI ───────────────────────────────────────────────────
  static Future<List<TransactionModel>> getTransactions() async {
    try {
      // Melakukan join query untuk mengambil transaksi beserta item produknya
      final response = await supabase.from('transactions').select('''
        *,
        transaction_items (
          *,
          products (*)
        )
      ''').order('created_at', ascending: false);

      return (response as List).map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> addTransaction(TransactionModel transaction) async {
    try {
      // 1. Simpan Transaksi Utama ke tabel 'transactions'
      final trxResponse = await supabase.from('transactions').insert({
        'total_amount': transaction.totalAmount,
        // (Tambahkan field lain sesuai tabel Anda misal: 'payment_method': transaction.paymentMethod)
      }).select('id').single(); // Ambil ID transaksi yang baru saja dibuat

      final newTrxId = trxResponse['id'];

      // 2. Simpan Item-Item Transaksi ke 'transaction_items' dan kurangi stok
      for (final item in transaction.items) {
        await supabase.from('transaction_items').insert({
          'transaction_id': newTrxId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.price,
        });

        // Kurangi stok produk secara langsung di database
        await decreaseStock(item.product.id, item.quantity);
      }
    } catch (e) {
      rethrow;
    }
  }


  // ── 4. STATISTIK DASHBOARD ─────────────────────────────────────────
  static Future<double> getTotalSales() async {
    try {
      // Menghitung total transaksi langsung menggunakan data dari server
      final transactions = await getTransactions();
      return transactions.fold<double>(0, (sum, t) => sum + t.totalAmount);
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getTotalTransactions() async {
    try {
      final response = await supabase.from('transactions').select('id');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> getTotalProducts() async {
    try {
      final response = await supabase.from('products').select('id');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}