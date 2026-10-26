import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fonts = FontLoader('Roboto');
  for (final weight in ['regular', 'bold', 'black']) {
    fonts.addFont(rootBundle.load('assets/fonts/roboto-$weight.ttf'));
  }
  await fonts.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  await testMain();
}
