import 'package:flutter/material.dart';
import '../models/models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (s, i) => s + i.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (s, i) => s + i.total);

  double deliveryFee(String option) =>
      option == 'express' ? 250.0 : option == 'standard' ? 150.0 : 0.0;

  double platformFee(double sub) => sub * 0.05;

  double total(String option) {
    final sub = subtotal;
    return sub + deliveryFee(option) + platformFee(sub);
  }

  void add(Product product, int quantity) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _items[idx].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity = quantity;
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
