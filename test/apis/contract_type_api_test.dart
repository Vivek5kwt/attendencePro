import 'package:attendancepro/apis/contract_type_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ContractTypeApi.deleteContractType', () {
    test('completes when server returns success status', () async {
      final api = ContractTypeApi(
        baseUrl: 'https://example.com',
        httpClient: MockClient((request) async {
          expect(request.method, equals('DELETE'));
          expect(request.url.path, contains('/api/contract-types/123'));
          return http.Response('', 204);
        }),
      );

      await expectLater(
        api.deleteContractType(token: 'token', contractTypeId: '123'),
        completes,
      );
    });

    test('treats 404 and 410 responses as successful deletions', () async {
      for (final statusCode in [404, 410]) {
        var callCount = 0;
        final api = ContractTypeApi(
          baseUrl: 'https://example.com',
          httpClient: MockClient((request) async {
            callCount++;
            return http.Response('', statusCode);
          }),
        );

        await expectLater(
          api.deleteContractType(token: 'token', contractTypeId: 'missing'),
          completes,
        );
        expect(callCount, equals(1), reason: 'Delete request should be sent.');
      }
    });

    test('throws when server returns an error status', () async {
      final api = ContractTypeApi(
        baseUrl: 'https://example.com',
        httpClient: MockClient((request) async {
          return http.Response('{"message": "Server error"}', 500);
        }),
      );

      await expectLater(
        api.deleteContractType(token: 'token', contractTypeId: 'oops'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('Server error'),
          ),
        ),
      );
    });
  });
}
