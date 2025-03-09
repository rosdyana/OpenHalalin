import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

class PrayerTimeService {
  static const String _CACHE_KEY = 'cached_prayer_times';
  static const String _CACHE_LOCATION_KEY = 'cached_location';
  static const String _CACHE_COORDINATES_KEY = 'cached_coordinates';
  static const double _SIGNIFICANT_DISTANCE = 500; // 500 meters threshold
  final SharedPreferences _prefs;

  PrayerTimeService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<PrayerTimeService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrayerTimeService._(prefs: prefs);
  }

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

  bool _hasLocationChangedSignificantly(Position currentPosition) {
    final cachedCoordinatesJson = _prefs.getString(_CACHE_COORDINATES_KEY);
    if (cachedCoordinatesJson == null) return true;

    try {
      final cachedCoordinates = json.decode(cachedCoordinatesJson) as Map<String, dynamic>;
      final cachedLat = cachedCoordinates['latitude'] as double;
      final cachedLng = cachedCoordinates['longitude'] as double;

      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        cachedLat,
        cachedLng,
      );

      return distance > _SIGNIFICANT_DISTANCE;
    } catch (e) {
      return true;
    }
  }

  Future<Map<String, dynamic>> _getPrayerTimesData() async {
    final position = await _getCurrentLocation();
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final date = DateTime.now();
    final dateComponents = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Get location name
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    final placemark = placemarks.first;
    String locationName = '${placemark.locality ?? ''}, ${placemark.country ?? ''}'.trim();
    if (locationName == ',') locationName = 'Unknown Location';

    // Cache the coordinates
    await _prefs.setString(_CACHE_COORDINATES_KEY, json.encode({
      'latitude': position.latitude,
      'longitude': position.longitude,
    }));

    return {
      'fajr': prayerTimes.fajr.millisecondsSinceEpoch,
      'sunrise': prayerTimes.sunrise.millisecondsSinceEpoch,
      'dhuhr': prayerTimes.dhuhr.millisecondsSinceEpoch,
      'asr': prayerTimes.asr.millisecondsSinceEpoch,
      'maghrib': prayerTimes.maghrib.millisecondsSinceEpoch,
      'isha': prayerTimes.isha.millisecondsSinceEpoch,
      'date': date.toIso8601String(),
      'location': locationName,
    };
  }

  Future<(PrayerTimes, String)> getPrayerTimes() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get current position first to check if location has changed
    final currentPosition = await _getCurrentLocation();
    final coordinates = Coordinates(currentPosition.latitude, currentPosition.longitude);
    
    // Try to get cached data
    final cachedJson = _prefs.getString(_CACHE_KEY);
    final cachedLocation = _prefs.getString(_CACHE_LOCATION_KEY);
    
    if (cachedJson != null && cachedLocation != null) {
      final cached = json.decode(cachedJson) as Map<String, dynamic>;
      final cachedDate = DateTime.parse(cached['date'] as String);
      
      // If cache is from today and location hasn't changed significantly
      if (cachedDate.year == today.year && 
          cachedDate.month == today.month && 
          cachedDate.day == today.day &&
          !_hasLocationChangedSignificantly(currentPosition)) {
            
        final params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;
        
        final prayerTimes = PrayerTimes(
          coordinates,
          DateComponents(today.year, today.month, today.day),
          params,
        );
        
        return (prayerTimes, cachedLocation);
      }
    }
    
    // If no cache, cache is old, or location has changed significantly, fetch new data
    final data = await _getPrayerTimesData();
    
    // Cache the new data
    await _prefs.setString(_CACHE_KEY, json.encode(data));
    await _prefs.setString(_CACHE_LOCATION_KEY, data['location'] as String);
    
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents(today.year, today.month, today.day),
      params,
    );
    
    return (prayerTimes, data['location'] as String);
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