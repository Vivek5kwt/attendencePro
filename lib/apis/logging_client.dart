import 'package:http/http.dart' as http;

/// An [http.Client] wrapper that logs every request and response.
///
/// The logs are printed to the terminal so you can observe the
/// requested URL, response status code, and status message.
class LoggingClient extends http.BaseClient {
  LoggingClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestDescription = '[HTTP] ${request.method} ${request.url}';
    // Print before sending the request.
    // ignore: avoid_print
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

      // Print after receiving the response.
      // ignore: avoid_print
      print(responseDescription.toString());
      return response;
    } catch (error) {
      // ignore: avoid_print
      print('[HTTP] ${request.method} ${request.url} → error: $error');
      rethrow;
    }
  }
}
