class UserResponse {
  final String prayerName;
  final String response;
  final DateTime timestamp;

  UserResponse({
    required this.prayerName,
    required this.response,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'prayerName': prayerName,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static UserResponse fromMap(Map<String, dynamic> map) {
    return UserResponse(
      prayerName: map['prayerName'],
      response: map['response'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'Response: $response for $prayerName at $timestamp';
  }
}
