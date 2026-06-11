import 'package:flutter_test/flutter_test.dart';
import 'package:spazasure_app/services/api_service.dart';

void main() {
  group('ApiException', () {
    test('stores message and status code', () {
      final error = ApiException('Not found', 404);
      expect(error.message, 'Not found');
      expect(error.statusCode, 404);
      expect(error.toString(), 'Not found');
    });
  });

  group('SessionExpiredException', () {
    test('is an ApiException with status 401', () {
      final error = SessionExpiredException('Token expired');
      expect(error.statusCode, 401);
      expect(error is ApiException, true);
    });
  });
}
