class CurlGenerator {
  static String generate({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? body,
    String? proxy,
    Map<String, String>? headerReplacements,
  }) {
    final StringBuffer curlCmd = StringBuffer('curl -X $method "$url"');

    headers.forEach((key, value) {
      if (headerReplacements != null && headerReplacements.containsKey(key)) {
         curlCmd.write(' \\\n  -H "$key: ${headerReplacements[key]}"');
      } else {
         curlCmd.write(' \\\n  -H "$key: $value"');
      }
    });

    if (proxy != null && proxy.isNotEmpty) {
      curlCmd.write(' \\\n  --proxy "$proxy"');
    }

    if (body != null) {
      // Escape single quotes for shell safety if wrapping in single quotes
      final String escapedBody = body.replaceAll("'", "'\\''");
      curlCmd.write(" \\\n  -d '$escapedBody'");
    }

    return curlCmd.toString();
  }
}
