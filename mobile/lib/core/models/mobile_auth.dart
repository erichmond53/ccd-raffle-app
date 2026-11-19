class MobileAuth {
  final String authorizationCode;
  final String locationId;
  final DateTime expiresAt;

  MobileAuth({required this.authorizationCode, required this.locationId, required this.expiresAt});

  factory MobileAuth.fromJson(Map<String, dynamic> json) {
    return MobileAuth(
      authorizationCode: json['authorization_code'] as String,
      locationId: json['location_id'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}
