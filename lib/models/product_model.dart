class ProductModel {
  final String id;
  final String name;
  final String? category; // 1. Dibuat nullable (String?) agar tidak error jika di database kosong
  final double price;
  final int stock;
  final String? imageUrl; // Dibuat nullable (String?)

  ProductModel({
    required this.id,
    required this.name,
    this.category,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  // 2. Namanya diubah menjadi fromJson agar sesuai dengan supabase_service.dart yang baru
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Tanpa Nama',
      category: json['category'], 
      // 3. Supabase mengembalikan angka sebagai tipe 'num', jadi cara konversinya harus diperbaiki
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['image_url'],
    );
  }

  // 4. Namanya diubah menjadi toJson
  Map<String, dynamic> toJson() {
    return {
      // 'id': id, ---> 5. ID DIKOSONGKAN / DI-COMMENT!
      'name': name,
      'category': category,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
    };
  }
}