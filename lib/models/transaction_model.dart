import 'product_model.dart';

// ── 1. MODEL UNTUK DETAIL ITEM KERANJANG ──
class TransactionItemModel {
  final String? id;
  final ProductModel product;
  final int quantity;
  final double price;

  TransactionItemModel({
    this.id,
    required this.product,
    required this.quantity,
    required this.price,
  });

  // Ganti fromMap menjadi fromJson agar cocok dengan Supabase
  factory TransactionItemModel.fromJson(Map<String, dynamic> json) {
    return TransactionItemModel(
      id: json['id']?.toString(),
      // Supabase mengembalikan relasi tabel products di dalam key 'products'
      product: ProductModel.fromJson(json['products'] ?? {}),
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id biasanya dikosongkan saat insert
      'quantity': quantity,
      'price': price,
      // product_id diurus di service saat insert
    };
  }
}

// ── 2. MODEL UNTUK STRUK UTAMA ──
class TransactionModel {
  final String id;
  final List<TransactionItemModel> items;
  final double totalAmount;
  final DateTime? date;
  final String? cashierEmail;
  final String? paymentMethod; // Tambahkan jika ada
  final String? status; // Tambahkan jika ada

  TransactionModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    this.date,
    this.cashierEmail,
    this.paymentMethod,
    this.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Menangkap array transaction_items dari Supabase
    var itemsList = json['transaction_items'] as List? ?? [];
    List<TransactionItemModel> parsedItems = 
        itemsList.map((i) => TransactionItemModel.fromJson(i)).toList();

    return TransactionModel(
      id: json['id'].toString(),
      items: parsedItems,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0, 
      date: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      cashierEmail: json['cashier_email'],
      paymentMethod: json['payment_method'] ?? 'Tunai', // Sesuaikan defaultnya
      status: json['status'] ?? 'Completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // id dikosongkan karena auto-generate UUID
      'total_amount': totalAmount,
      'cashier_email': cashierEmail,
      'payment_method': paymentMethod,
      'status': status,
    };
  }
}