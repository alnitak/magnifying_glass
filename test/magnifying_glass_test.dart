import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magnifying_glass/magnifying_glass.dart';

void main() {
  const MethodChannel channel = MethodChannel('magnifying_glass');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await MagnifyingGlass.platformVersion, '42');
  });
}
