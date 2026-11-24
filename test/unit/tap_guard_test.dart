import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/core/utils/tap_guard.dart';

void main() {
  final t0 = DateTime(2026, 1, 1);

  test('accepts the first input', () {
    expect(TapGuard().accept(t0), isTrue);
  });

  test('rejects an input that arrives within the minimum interval', () {
    final guard = TapGuard();
    expect(guard.accept(t0), isTrue);
    expect(guard.accept(t0), isFalse, reason: 'same instant: a double fire');
    expect(guard.accept(t0.add(const Duration(milliseconds: 40))), isFalse);
  });

  test('accepts a deliberate fast cadence', () {
    final guard = TapGuard();
    var at = t0;
    for (var i = 0; i < 20; i++) {
      expect(guard.accept(at), isTrue);
      at = at.add(const Duration(milliseconds: 110));
    }
  });

  test('a rejected input does not extend the lockout', () {
    final guard = TapGuard();
    guard.accept(t0);
    guard.accept(t0.add(const Duration(milliseconds: 50)));
    expect(guard.accept(t0.add(const Duration(milliseconds: 75))), isTrue);
  });

  test('a clock moving backwards never locks input', () {
    final guard = TapGuard();
    guard.accept(t0);
    expect(guard.accept(t0.subtract(const Duration(minutes: 1))), isTrue);
  });

  test('reset clears the lockout', () {
    final guard = TapGuard()..accept(t0);
    guard.reset();
    expect(guard.accept(t0), isTrue);
  });
}
