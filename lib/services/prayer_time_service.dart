// lib/services/prayer_time_service.dart

import 'package:adhan/adhan.dart';
import 'location_service.dart';
import '../models/prayer_time.dart'; // Import the PrayerTime model

class PrayerTimeService {
  Future<List<PrayerTime>> getPrayerTimes(LocationData location) async {
    final Coordinates coordinates = Coordinates(location.latitude, location.longitude);
    print("Calculating prayer times for coordinates: ${coordinates.latitude}, ${coordinates.longitude}");

    // Use the MWL calculation method
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    // Fetch prayer times
    final PrayerTimes prayerTimes = PrayerTimes.today(coordinates, params);
    final SunnahTimes sunnahTimes = SunnahTimes(prayerTimes);

    // Log the calculated prayer times and Sunnah times for debugging
    print("Fajr: ${prayerTimes.fajr}, Dhuhr: ${prayerTimes.dhuhr}, Asr: ${prayerTimes.asr}, Maghrib: ${prayerTimes.maghrib}, Isha: ${prayerTimes.isha}");
    print("Middle of the night (Isha end time): ${sunnahTimes.middleOfTheNight}");

    return [
      PrayerTime(
        name: 'Fajr',
        startTime: prayerTimes.fajr,
        endTime: prayerTimes.sunrise,
      ),
      PrayerTime(
        name: 'Dhuhr',
        startTime: prayerTimes.dhuhr,
        endTime: prayerTimes.asr,
      ),
      PrayerTime(
        name: 'Asr',
        startTime: prayerTimes.asr,
        endTime: prayerTimes.maghrib,
      ),
      PrayerTime(
        name: 'Maghrib',
        startTime: prayerTimes.maghrib,
        endTime: prayerTimes.isha,
      ),
      PrayerTime(
        name: 'Isha',
        startTime: prayerTimes.isha,
        // Use middle of the night for Isha's end time
        endTime: sunnahTimes.middleOfTheNight,
      ),
    ];
  }
}
