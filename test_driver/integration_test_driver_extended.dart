import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart'
    as integration;

Future<void> integrationDriver() {
  return integration.integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      final output = File('build/integration_response_data.json');
      await output.parent.create(recursive: true);
      final payload = const JsonEncoder.withIndent('  ').convert(data ?? {});
      await output.writeAsString(payload);
    },
    writeResponseOnFailure: true,
  );
}
