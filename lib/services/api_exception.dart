class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  static String describe(Object? error) => error is ApiException
      ? error.message
      : 'Algo deu errado. Tente novamente em instantes.';

  @override
  String toString() => message;
}
