import 'api_service.dart';

class WalletBalance {
  final double balance;
  final double totalSpent;
  final String currency;

  WalletBalance({
    required this.balance,
    required this.totalSpent,
    this.currency = 'ZAR',
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'ZAR',
    );
  }
}

class WalletTransaction {
  final String id;
  final String type;
  final String description;
  final double amount;
  final String status;
  final DateTime date;
  final String? reference;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.status,
    required this.date,
    this.reference,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'].toString(),
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      reference: json['reference'],
    );
  }
}

class TopUpResult {
  final String topUpId;
  final double amount;
  final String currency;
  final Map<String, dynamic> payment;

  TopUpResult({
    required this.topUpId,
    required this.amount,
    required this.currency,
    required this.payment,
  });

  factory TopUpResult.fromJson(Map<String, dynamic> json) {
    return TopUpResult(
      topUpId: json['topUpId'].toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'ZAR',
      payment: json['payment'] as Map<String, dynamic>? ?? {},
    );
  }
}

class WalletService {
  /// Get wallet balance.
  static Future<WalletBalance> getBalance() async {
    final res = await ApiService.get('/shop/wallet/balance');
    final data = res['data'] as Map<String, dynamic>;
    return WalletBalance.fromJson(data);
  }

  /// Request a wallet top-up.
  static Future<TopUpResult> topUp({
    required double amount,
    String method = 'eft',
  }) async {
    final res = await ApiService.post('/shop/wallet/topup', {
      'amount': amount,
      'method': method,
    });
    final data = res['data'] as Map<String, dynamic>;
    return TopUpResult.fromJson(data);
  }

  /// Get transaction history.
  static Future<List<WalletTransaction>> getTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await ApiService.get(
        '/shop/wallet/transactions?page=$page&pageSize=$pageSize');
    final data = res['data'] as Map<String, dynamic>;
    final items = data['transactions'] as List<dynamic>;
    return items
        .map((t) => WalletTransaction.fromJson(t as Map<String, dynamic>))
        .toList();
  }
}
