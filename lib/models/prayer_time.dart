class PrayerTime {
  final String name;
  final DateTime startTime;
  final DateTime endTime;

  PrayerTime({
    required this.name,
    required this.startTime,
    required this.endTime,
  });


  bool isActive(DateTime currentTime) {
    return currentTime.isAfter(startTime) && currentTime.isBefore(endTime);
  }

  @override
  String toString() {
    return '$name: $startTime - $endTime';
  }
}
