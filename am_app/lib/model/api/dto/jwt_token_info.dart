class JwtTokenInfo {
  final String? accessToken,
      refreshToken,
      accessTokenExpireTime,
      refreshTokenExpireTime,
      ownerEmail,
      tokenId;

  JwtTokenInfo.fromJson(Map<String, dynamic> json)
      : accessToken = json['data']['accessToken'],
        refreshToken = json['data']['refreshToken'],
        accessTokenExpireTime = json['data']['accessTokenExpireTime'],
        refreshTokenExpireTime = json['data']['refreshTokenExpireTime'],
        ownerEmail = json['data']['ownerEmail'],
        tokenId = json['data']['tokenId'];

  @override
  String toString() {
    return 'JwtTokenInfo=> accessToken: $accessToken, refreshToken: $refreshToken, accessTokenExpireTime: $accessTokenExpireTime, refreshTokenExpireTime: $refreshTokenExpireTime, ownerEmail:$ownerEmail, tokenId:$tokenId';
  }
}
