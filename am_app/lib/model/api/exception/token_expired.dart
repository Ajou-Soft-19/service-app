class TokenExpiredException implements Exception {
  String cause;

  TokenExpiredException(this.cause);
}
