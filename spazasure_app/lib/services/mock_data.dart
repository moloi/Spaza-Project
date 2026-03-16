import '../models/models.dart';

class MockData {
  static const List<Category> categories = [
    Category(id: '1', name: 'Groceries', iconName: 'shopping_basket', productCount: 45),
    Category(id: '2', name: 'Beverages', iconName: 'local_drink', productCount: 32),
    Category(id: '3', name: 'Snacks', iconName: 'cookie', productCount: 28),
    Category(id: '4', name: 'Personal Care', iconName: 'spa', productCount: 18),
    Category(id: '5', name: 'Household', iconName: 'home', productCount: 22),
    Category(id: '6', name: 'Baby Products', iconName: 'child_care', productCount: 15),
    Category(id: '7', name: 'Frozen Foods', iconName: 'ac_unit', productCount: 12),
    Category(id: '8', name: 'Bakery', iconName: 'bakery_dining', productCount: 10),
  ];

  static const List<Supplier> suppliers = [
    Supplier(id: 's1', companyName: 'Tiger Brands', logoUrl: '', rating: 4.5, reviewCount: 128, productCount: 45, tier: 'gold', isVerified: true),
    Supplier(id: 's2', companyName: 'Pioneer Foods', logoUrl: '', rating: 4.3, reviewCount: 95, productCount: 38, tier: 'silver', isVerified: true),
    Supplier(id: 's3', companyName: 'RCL Foods', logoUrl: '', rating: 4.1, reviewCount: 67, productCount: 30, tier: 'bronze', isVerified: true),
    Supplier(id: 's4', companyName: 'Clover SA', logoUrl: '', rating: 4.6, reviewCount: 142, productCount: 25, tier: 'gold', isVerified: true),
  ];

  static final List<Product> products = [
    const Product(id: 'p1', name: 'White Star Maize Meal 10kg', description: 'Premium quality super maize meal. A staple in every South African household.', sku: 'WS-MM-10', price: 89.99, imageUrl: '', categoryId: '1', categoryName: 'Groceries', supplierId: 's1', supplierName: 'Tiger Brands', stockQuantity: 500, minOrderQty: 10, rating: 4.7, reviewCount: 89, isAvailable: true),
    const Product(id: 'p2', name: 'Tastic Rice 2kg', description: 'Long grain parboiled rice. Perfect for everyday meals.', sku: 'TR-2K', price: 42.99, imageUrl: '', categoryId: '1', categoryName: 'Groceries', supplierId: 's1', supplierName: 'Tiger Brands', stockQuantity: 300, minOrderQty: 12, rating: 4.5, reviewCount: 65, isAvailable: true),
    const Product(id: 'p3', name: 'Sunfoil Cooking Oil 2L', description: 'Pure sunflower cooking oil. Cholesterol free.', sku: 'SF-CO-2L', price: 54.99, imageUrl: '', categoryId: '1', categoryName: 'Groceries', supplierId: 's2', supplierName: 'Pioneer Foods', stockQuantity: 200, minOrderQty: 6, rating: 4.3, reviewCount: 42, isAvailable: true),
    const Product(id: 'p4', name: 'Coca-Cola 2L (6-Pack)', description: 'Original taste Coca-Cola. 6 x 2L bottles.', sku: 'CC-2L-6', price: 89.99, imageUrl: '', categoryId: '2', categoryName: 'Beverages', supplierId: 's3', supplierName: 'RCL Foods', stockQuantity: 150, minOrderQty: 4, rating: 4.8, reviewCount: 120, isAvailable: true),
    const Product(id: 'p5', name: 'Simba Chips Assorted 36s', description: 'Mixed flavour chips. 36 individual packets.', sku: 'SC-36', price: 149.99, imageUrl: '', categoryId: '3', categoryName: 'Snacks', supplierId: 's2', supplierName: 'Pioneer Foods', stockQuantity: 100, minOrderQty: 2, rating: 4.6, reviewCount: 78, isAvailable: true),
    const Product(id: 'p6', name: 'Clover Fresh Milk 2L (6-Pack)', description: 'Full cream fresh milk. 6 x 2L cartons.', sku: 'CM-2L-6', price: 119.99, imageUrl: '', categoryId: '2', categoryName: 'Beverages', supplierId: 's4', supplierName: 'Clover SA', stockQuantity: 80, minOrderQty: 2, rating: 4.4, reviewCount: 55, isAvailable: true),
    const Product(id: 'p7', name: 'Sunlight Dishwashing Liquid 750ml (12-Pack)', description: 'Powerful grease-cutting formula.', sku: 'SDL-750-12', price: 179.99, imageUrl: '', categoryId: '5', categoryName: 'Household', supplierId: 's1', supplierName: 'Tiger Brands', stockQuantity: 120, minOrderQty: 2, rating: 4.2, reviewCount: 33, isAvailable: true),
    const Product(id: 'p8', name: 'Lucky Star Pilchards 400g (24-Pack)', description: 'Pilchards in tomato sauce. Bulk pack.', sku: 'LS-400-24', price: 299.99, imageUrl: '', categoryId: '1', categoryName: 'Groceries', supplierId: 's3', supplierName: 'RCL Foods', stockQuantity: 60, minOrderQty: 1, rating: 4.5, reviewCount: 91, isAvailable: true),
    const Product(id: 'p9', name: 'Pampers Baby Dry Size 3 (52-Pack)', description: 'Up to 12 hours of dryness.', sku: 'PBD-3-52', price: 219.99, imageUrl: '', categoryId: '6', categoryName: 'Baby Products', supplierId: 's1', supplierName: 'Tiger Brands', stockQuantity: 40, minOrderQty: 2, rating: 4.7, reviewCount: 44, isAvailable: true),
    const Product(id: 'p10', name: 'Albany Superior Bread (20 Loaves)', description: 'White sliced bread. Bulk order.', sku: 'AB-WB-20', price: 259.99, discountPrice: 229.99, imageUrl: '', categoryId: '8', categoryName: 'Bakery', supplierId: 's2', supplierName: 'Pioneer Foods', stockQuantity: 30, minOrderQty: 1, rating: 4.3, reviewCount: 37, isAvailable: true),
  ];

  static final List<Order> orders = [
    Order(
      id: 'o1', orderNumber: 'SPZ-2025-0001', shopId: 'shop1', supplierId: 's1', supplierName: 'Tiger Brands',
      items: const [
        OrderItem(productId: 'p1', productName: 'White Star Maize Meal 10kg', productImage: '', quantity: 20, price: 89.99),
        OrderItem(productId: 'p2', productName: 'Tastic Rice 2kg', productImage: '', quantity: 12, price: 42.99),
      ],
      subtotal: 2315.68, deliveryFee: 150.00, platformFee: 69.47, total: 2535.15,
      status: 'dispatched', deliveryOption: 'standard', paymentMethod: 'eft', paymentStatus: 'held',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      estimatedDelivery: DateTime.now().add(const Duration(hours: 4)),
    ),
    Order(
      id: 'o2', orderNumber: 'SPZ-2025-0002', shopId: 'shop1', supplierId: 's4', supplierName: 'Clover SA',
      items: const [
        OrderItem(productId: 'p6', productName: 'Clover Fresh Milk 2L (6-Pack)', productImage: '', quantity: 5, price: 119.99),
      ],
      subtotal: 599.95, deliveryFee: 100.00, platformFee: 18.00, total: 717.95,
      status: 'delivered', deliveryOption: 'express', paymentMethod: 'eft', paymentStatus: 'released',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Order(
      id: 'o3', orderNumber: 'SPZ-2025-0003', shopId: 'shop1', supplierId: 's2', supplierName: 'Pioneer Foods',
      items: const [
        OrderItem(productId: 'p5', productName: 'Simba Chips Assorted 36s', productImage: '', quantity: 4, price: 149.99),
        OrderItem(productId: 'p10', productName: 'Albany Superior Bread (20 Loaves)', productImage: '', quantity: 2, price: 229.99),
      ],
      subtotal: 1059.94, deliveryFee: 120.00, platformFee: 31.80, total: 1211.74,
      status: 'pending', deliveryOption: 'standard', paymentMethod: 'eft', paymentStatus: 'pending',
      createdAt: DateTime.now(),
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(id: 'n1', title: 'Order Dispatched', body: 'Your order SPZ-2025-0001 is on its way!', type: 'delivery', createdAt: DateTime.now().subtract(const Duration(hours: 2))),
    AppNotification(id: 'n2', title: 'Payment Confirmed', body: 'Payment of R2,535.15 received for order SPZ-2025-0001', type: 'order', createdAt: DateTime.now().subtract(const Duration(hours: 5))),
    AppNotification(id: 'n3', title: 'Document Expiring', body: 'Your business permit expires in 14 days. Please renew.', type: 'compliance', createdAt: DateTime.now().subtract(const Duration(days: 1))),
    AppNotification(id: 'n4', title: 'Order Delivered', body: 'Order SPZ-2025-0002 has been delivered. Please confirm.', type: 'delivery', createdAt: DateTime.now().subtract(const Duration(days: 3))),
  ];

  static final List<ComplianceDoc> complianceDocs = [
    ComplianceDoc(id: 'd1', shopId: 'shop1', docType: 'business_permit', docUrl: '', status: 'approved', expiryDate: DateTime.now().add(const Duration(days: 14))),
    ComplianceDoc(id: 'd2', shopId: 'shop1', docType: 'health_cert', docUrl: '', status: 'approved', expiryDate: DateTime.now().add(const Duration(days: 180))),
    ComplianceDoc(id: 'd3', shopId: 'shop1', docType: 'lease', docUrl: '', status: 'pending'),
    ComplianceDoc(id: 'd4', shopId: 'shop1', docType: 'id_document', docUrl: '', status: 'approved'),
  ];
}

