import 'package:flutter_test/flutter_test.dart';
import 'package:spazasure_app/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts valid +27 format', () {
      expect(Validators.phone('+27812345678'), null);
    });

    test('accepts valid 0xx format', () {
      expect(Validators.phone('0812345678'), null);
    });

    test('rejects too short number', () {
      expect(Validators.phone('081234'), isNotNull);
    });

    test('rejects empty', () {
      expect(Validators.phone(''), isNotNull);
    });

    test('rejects null', () {
      expect(Validators.phone(null), isNotNull);
    });
  });

  group('Validators.email', () {
    test('accepts valid email', () {
      expect(Validators.email('test@example.com'), null);
    });

    test('rejects invalid email', () {
      expect(Validators.email('notanemail'), isNotNull);
    });

    test('accepts empty (optional)', () {
      expect(Validators.email(''), null);
    });

    test('accepts null (optional)', () {
      expect(Validators.email(null), null);
    });
  });

  group('Validators.otp', () {
    test('accepts 6 digit OTP', () {
      expect(Validators.otp('123456'), null);
    });

    test('rejects 5 digits', () {
      expect(Validators.otp('12345'), isNotNull);
    });

    test('rejects letters', () {
      expect(Validators.otp('12345a'), isNotNull);
    });
  });

  group('Validators.idNumber', () {
    test('accepts 13 digit ID', () {
      expect(Validators.idNumber('9001015009087'), null);
    });

    test('rejects too short', () {
      expect(Validators.idNumber('123456'), isNotNull);
    });

    test('accepts null (optional)', () {
      expect(Validators.idNumber(null), null);
    });
  });

  group('Validators.sanitize', () {
    test('strips HTML tags', () {
      final result = Validators.sanitize('<script>alert("xss")</script>Hello');
      expect(result.contains('<'), false);
      expect(result.contains('>'), false);
      expect(result.contains('Hello'), true);
    });

    test('passes normal text unchanged', () {
      expect(Validators.sanitize('normal text'), 'normal text');
    });
  });

  group('Validators.amount', () {
    test('accepts positive number', () {
      expect(Validators.amount('100.50'), null);
    });

    test('rejects zero', () {
      expect(Validators.amount('0'), isNotNull);
    });

    test('rejects negative', () {
      expect(Validators.amount('-10'), isNotNull);
    });

    test('rejects non-numeric', () {
      expect(Validators.amount('abc'), isNotNull);
    });
  });
}
