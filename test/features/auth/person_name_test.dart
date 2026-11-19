import 'package:flutter_test/flutter_test.dart';
import 'package:loveline/features/auth/domain/password_strength.dart';
import 'package:loveline/features/auth/domain/person_name.dart';
import 'package:loveline/features/auth/domain/signup_rules.dart';

void main() {
  group('PersonName.validate', () {
    test('accepte les noms usuels, accents, apostrophes et tirets compris', () {
      for (final name in ['Awa', 'Jean-Pierre', "N'Dri", 'N’Dri', 'Éloïse', 'Marie Claire']) {
        expect(PersonName.validate(name), isNull, reason: name);
      }
    });

    test('refuse le vide', () {
      expect(PersonName.validate(''), NameIssue.empty);
      expect(PersonName.validate('   '), NameIssue.empty);
    });

    test('refuse chiffres, symboles et séparateurs mal placés', () {
      for (final name in ['Awa2', '<b>', '-Awa', 'Awa--B', 'Awa_B']) {
        expect(PersonName.validate(name), NameIssue.invalidCharacters, reason: name);
      }
    });

    test('refuse plus de cinquante caractères', () {
      expect(PersonName.validate('A' * 51), NameIssue.tooLong);
      expect(PersonName.validate('A' * 50), isNull);
    });
  });

  test('normalize retire les espaces en trop', () {
    expect(PersonName.normalize('  Marie   Claire '), 'Marie Claire');
  });

  group('SignupRules', () {
    test('normalise et valide les adresses e-mail', () {
      expect(SignupRules.normalizeEmail('  Awa@Exemple.TG '), 'awa@exemple.tg');
      expect(SignupRules.isValidEmail('awa@exemple.tg'), isTrue);
      for (final bad in ['', 'awa', 'awa@', '@exemple.tg', 'a wa@exemple.tg', 'awa@exemple']) {
        expect(SignupRules.isValidEmail(bad), isFalse, reason: bad);
      }
    });
  });

  group('PasswordStrength', () {
    test('un mot de passe trop court est signalé', () {
      expect(PasswordStrength.evaluate('abc'), PasswordStrength.tooShort);
    });

    test('la solidité augmente avec la longueur et la variété', () {
      expect(PasswordStrength.evaluate('abcdefgh'), PasswordStrength.weak);
      expect(PasswordStrength.evaluate('abcdefghijkl'), PasswordStrength.fair);
      expect(PasswordStrength.evaluate('Abcdefgh1234!xyz'), PasswordStrength.strong);
    });
  });
}
