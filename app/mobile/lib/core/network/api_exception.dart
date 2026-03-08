class ApiException implements Exception {
  ApiException(this.message, {this.code, this.requestId});

  final String message;
  final String? code;
  final String? requestId;

  @override
  String toString() {
    final parts = <String>[message];
    if (code != null && code!.isNotEmpty) {
      parts.add('code=$code');
    }
    if (requestId != null && requestId!.isNotEmpty) {
      parts.add('requestId=$requestId');
    }
    return 'ApiException(${parts.join(', ')})';
  }
}
