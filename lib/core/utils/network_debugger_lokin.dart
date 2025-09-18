import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class NetworkDebugger {
  static const String baseUrl = 'https://appabsensi.mobileprojp.com/api';

  /// Test connectivity to the API server
  static Future<Map<String, dynamic>> testConnection() async {
    final results = <String, dynamic>{};

    try {
      print('=== NETWORK DEBUG TEST ===');

      // Test 1: Basic connectivity
      results['basic_connectivity'] = await _testBasicConnectivity();

      // Test 2: API endpoints availability
      results['endpoints'] = await _testEndpoints();

      // Test 3: DNS resolution
      results['dns_resolution'] = await _testDnsResolution();

      print('Network test completed: $results');
      return results;
    } catch (e) {
      print('Network test error: $e');
      return {'error': e.toString()};
    }
  }

  static Future<bool> _testBasicConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://google.com'),
          )
          .timeout(const Duration(seconds: 10));

      print(
          'Basic connectivity test: ${response.statusCode == 200 ? 'PASS' : 'FAIL'}');
      return response.statusCode == 200;
    } catch (e) {
      print('Basic connectivity test: FAIL - $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> _testEndpoints() async {
    final endpoints = {
      'trainings': '$baseUrl/trainings',
      'batches': '$baseUrl/batches',
      'register': '$baseUrl/register',
    };

    final results = <String, dynamic>{};

    for (final entry in endpoints.entries) {
      try {
        print('Testing endpoint: ${entry.value}');

        final response = await http.get(
          Uri.parse(entry.value),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        results[entry.key] = {
          'status_code': response.statusCode,
          'accessible': response.statusCode < 500,
          'response_size': response.body.length,
        };

        print(
            '${entry.key}: ${response.statusCode} (${response.body.length} bytes)');
      } catch (e) {
        results[entry.key] = {
          'status_code': null,
          'accessible': false,
          'error': e.toString(),
        };
        print('${entry.key}: ERROR - $e');
      }
    }

    return results;
  }

  static Future<bool> _testDnsResolution() async {
    try {
      final addresses =
          await InternetAddress.lookup('appabsensi.mobileprojp.com');
      print('DNS resolution: PASS - ${addresses.length} addresses found');
      for (final addr in addresses) {
        print('  - ${addr.address}');
      }
      return addresses.isNotEmpty;
    } catch (e) {
      print('DNS resolution: FAIL - $e');
      return false;
    }
  }

  /// Test specific registration endpoint
  static Future<Map<String, dynamic>> testRegistrationEndpoint() async {
    try {
      print('=== TESTING REGISTRATION ENDPOINT ===');

      final testData = {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'password123',
        'training_id': 1,
        'batch_id': 1,
        'jenis_kelamin': 'L', // FIXED: Use correct field name
      };

      print('Testing with data: ${jsonEncode(testData)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(testData),
          )
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      return {
        'status_code': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'success': response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      print('Registration test error: $e');
      return {
        'error': e.toString(),
        'success': false,
      };
    }
  }

  /// Check internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get device network info
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    final info = <String, dynamic>{};

    try {
      // Check internet
      info['has_internet'] = await hasInternetConnection();

      // Check specific host
      try {
        final result =
            await InternetAddress.lookup('appabsensi.mobileprojp.com');
        info['api_host_reachable'] = result.isNotEmpty;
        info['api_host_addresses'] =
            result.map((addr) => addr.address).toList();
      } catch (e) {
        info['api_host_reachable'] = false;
        info['api_host_error'] = e.toString();
      }
    } catch (e) {
      info['error'] = e.toString();
    }

    return info;
  }
}

class ApiTester {
  static Future<void> runFullTest() async {
    print('\n${'=' * 50}');
    print('STARTING FULL API TEST');
    print('=' * 50);

    // Test 1: Network connectivity
    print('\n1. Testing network connectivity...');
    final networkInfo = await NetworkDebugger.getNetworkInfo();
    print('Network info: $networkInfo');

    // Test 2: General connectivity
    print('\n2. Testing general connectivity...');
    final connectionTest = await NetworkDebugger.testConnection();
    print('Connection test results: $connectionTest');

    // Test 3: Registration endpoint
    print('\n3. Testing registration endpoint...');
    final regTest = await NetworkDebugger.testRegistrationEndpoint();
    print('Registration test results: $regTest');

    print('\n${'=' * 50}');
    print('API TEST COMPLETED');
    print('=' * 50 + '\n');
  }
}
