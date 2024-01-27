class EmailNotVerifiedException implements Exception {
  String cause;

  EmailNotVerifiedException(this.cause);
}
