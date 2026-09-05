import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/login_request.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/register_request.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  group('Phone and Email Auth Model & Logic Tests', () {
    test('AuthenticatedUser parses email-based user properly', () {
      final user = AuthenticatedUser.fromJson({
        'id': 101,
        'email': 'visal@example.com',
        'role': 'USER',
        'fullName': 'Visal Dev',
      });

      expect(user.id, 101);
      expect(user.email, 'visal@example.com');
      expect(user.displayName, 'Visal Dev');
    });

    test('AuthenticatedUser parses phone-based user properly', () {
      final user = AuthenticatedUser.fromJson({
        'id': 102,
        'phone': '85512345678',
        'role': 'USER',
      });

      expect(user.id, 102);
      expect(user.email, '85512345678');
      expect(user.displayName, '85512345678');
      expect(user.initials, '8');
    });

    test('AuthenticatedUser parses phoneNumber field fallback', () {
      final user = AuthenticatedUser.fromJson({
        'id': 103,
        'phoneNumber': '012345678',
        'role': 'USER',
      });

      expect(user.id, 103);
      expect(user.email, '012345678');
      expect(user.displayName, '012345678');
    });

    test('LoginRequest formats email and phone identifier properly', () {
      final emailReq = LoginRequest(
        email: '  test@example.com  ',
        password: 'password123',
      );
      expect(emailReq.toJson()['email'], 'test@example.com');

      final phoneReq = LoginRequest(
        email: '  012345678  ',
        password: 'password123',
      );
      expect(phoneReq.toJson()['email'], '012345678');
    });

    test('RegisterRequest formats email and phone identifier properly', () {
      final emailReq = RegisterRequest(
        fullName: '  Test User  ',
        email: '  test@example.com  ',
        password: 'password123',
      );
      expect(emailReq.toJson()['fullName'], 'Test User');
      expect(emailReq.toJson()['email'], 'test@example.com');

      final phoneReq = RegisterRequest(
        fullName: '  Test User  ',
        email: '  012345678  ',
        password: 'password123',
      );
      expect(phoneReq.toJson()['fullName'], 'Test User');
      expect(phoneReq.toJson()['email'], '012345678');
    });

    test('Phone and Email format validation regex behaves correctly', () {
      final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
      bool isValid(String input) {
        final normalized = input.trim();
        final isEmail = GetUtils.isEmail(normalized);
        final isPhone = phoneRegex.hasMatch(
          normalized.replaceAll(RegExp(r'[\s-]'), ''),
        );
        return isEmail || isPhone;
      }

      // Valid emails
      expect(isValid('user@example.com'), isTrue);
      expect(isValid('john.doe+test@gmail.com'), isTrue);

      // Valid phones
      expect(isValid('012345678'), isTrue);
      expect(isValid('0987654321'), isTrue);
      expect(isValid('+85512345678'), isTrue);
      expect(isValid('012-345-678'), isTrue);
      expect(isValid('855 12 345 678'), isTrue);

      // Invalid inputs
      expect(isValid('notanemail'), isFalse);
      expect(isValid('1234'), isFalse); // too short for a phone number
      expect(isValid('abc12345678'), isFalse);
      expect(isValid(''), isFalse);
    });

    test('Translations include Email or Phone Number in both EN and KM', () {
      final translations = AppTranslations().keys;
      final en = translations['en_US']!;
      final km = translations['km_KH']!;

      expect(en['Email or Phone Number'], 'Email or Phone Number');
      expect(km['Email or Phone Number'], 'អ៊ីមែល ឬលេខទូរស័ព្ទ');

      expect(
        en['Please enter a valid email or phone number.'],
        'Please enter a valid email or phone number.',
      );
      expect(
        km['Please enter a valid email or phone number.'],
        'សូមបញ្ចូលអ៊ីមែល ឬលេខទូរស័ព្ទដែលត្រឹមត្រូវ',
      );

      expect(en['We sent an SMS code to'], 'We sent an SMS code to');
      expect(km['We sent an SMS code to'], 'យើងបានផ្ញើកូដ SMS ទៅកាន់');
    });
  });
}
