import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  LoggingClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestDescription = '[HTTP] ${request.method} ${request.url}';

    print(requestDescription);

    try {
      final response = await _inner.send(request);
      final statusCode = response.statusCode;
      final reason = response.reasonPhrase;
      final responseDescription = StringBuffer()
        ..write('[HTTP] ${request.method} ${request.url} → $statusCode');
      if (reason != null && reason.isNotEmpty) {
        responseDescription.write(' ($reason)');
      }

      print(responseDescription.toString());
      return response;
    } catch (error) {
      print('[HTTP] ${request.method} ${request.url} → error: $error');
      rethrow;
    }
  }
}
