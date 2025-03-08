import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PrayerTimeService {
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<PrayerTimes> getPrayerTimes() async {
    final position = await _getCurrentLocation();
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final date = DateTime.now();
    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return prayerTimes;
  }

  String formatPrayerTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat.jm().format(time);
  }

  String getNextPrayer(PrayerTimes prayerTimes) {
    final next = prayerTimes.nextPrayer();
    
    switch (next) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return 'Fajr';
    }
  }

  Duration getTimeUntilNextPrayer(PrayerTimes prayerTimes) {
    final now = DateTime.now();
    final nextPrayer = prayerTimes.timeForPrayer(prayerTimes.nextPrayer());
    if (nextPrayer == null) return Duration.zero;
    return nextPrayer.difference(now);
  }
} 