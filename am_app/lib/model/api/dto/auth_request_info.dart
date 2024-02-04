class AuthRequestInfo {
  final int authRequestId;
  final String email;
  final String role;
  bool isPending;
  bool isApproved;
  final String createdDate;
  String modifiedDate;

  AuthRequestInfo({
    required this.authRequestId,
    required this.email,
    required this.role,
    required this.isPending,
    required this.isApproved,
    required this.createdDate,
    required this.modifiedDate,
  });

  factory AuthRequestInfo.fromJson(Map<String, dynamic> json) {
    return AuthRequestInfo(
      authRequestId: json['authRequestId'],
      email: json['email'],
      role: json['role'],
      isPending: json['isPending'],
      isApproved: json['isApproved'],
      createdDate: json['createdDate'],
      modifiedDate: json['modifiedDate'],
    );
  }
}
