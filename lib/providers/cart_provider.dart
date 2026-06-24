import 'package:flutter/foundation.dart';

class CartItem {
  final int productId;
  final String name;
  final double basePrice;
  final String? variantName;
  final double variantPriceDiff;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.basePrice,
    this.variantName,
    this.variantPriceDiff = 0.0,
    required this.imageUrl,
    this.quantity = 1,
  });

  double get unitPrice => basePrice + variantPriceDiff;
  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'variant': variantName,
    'base_price': basePrice,
    'variant_price_diff': variantPriceDiff,
    'unit_price': unitPrice,
    'quantity': quantity,
    'total_price': totalPrice,
  };
}

class CartProvider extends ChangeNotifier {
  int? _businessId;
  String? _businessName;
  bool _hasPosDevice = true;
  final List<CartItem> _items = [];

  int? get businessId => _businessId;
  String? get businessName => _businessName;
  bool get hasPosDevice => _hasPosDevice;
  List<CartItem> get items => _items;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  // Sepete eklemeden önce kontrol için (Getir mantığı: Sepet farklı bir işletmeye mi ait?)
  bool isDifferentBusiness(int newBusinessId) {
    return _businessId != null && _businessId != newBusinessId && _items.isNotEmpty;
  }

  void addItem({
    required int businessId,
    required String businessName,
    bool hasPosDevice = true,
    required CartItem item,
  }) {
    if (isDifferentBusiness(businessId)) {
      // Bu durumu UI tarafında ele alıp sepeti sıfırlama onayı isteyeceğiz.
      throw Exception("Farklı bir işletmeden ürün ekleyemezsiniz. Sepeti sıfırlamanız gerekiyor.");
    }

    _businessId = businessId;
    _businessName = businessName;
    _hasPosDevice = hasPosDevice;

    // Aynı ürün + aynı varyant zaten varsa sayısını artır
    final existingIndex = _items.indexWhere((i) => i.productId == item.productId && i.variantName == item.variantName);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    if (_items.isEmpty) {
      _businessId = null;
      _businessName = null;
      _hasPosDevice = true;
    }
    notifyListeners();
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(index);
    } else {
      _items[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _businessId = null;
    _businessName = null;
    _hasPosDevice = true;
    notifyListeners();
  }
}
