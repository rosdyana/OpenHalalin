import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:halalapp/services/prayer_time_service.dart';

class PrayerTimeScreen extends StatefulWidget {
  const PrayerTimeScreen({super.key});

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();
  PrayerTimes? _prayerTimes;
  Timer? _timer;
  String _timeUntilNext = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final prayerTimes = await _prayerTimeService.getPrayerTimes();
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _prayerTimes = prayerTimes;
        _currentPosition = position;
        _updateTimeUntilNext();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTimeUntilNext();
      }
    });
  }

  void _updateTimeUntilNext() {
    if (_prayerTimes == null) return;
    final duration = _prayerTimeService.getTimeUntilNextPrayer(_prayerTimes!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    setState(() {
      _timeUntilNext = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_prayerTimes == null || _currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final nextPrayer = _prayerTimeService.getNextPrayer(_prayerTimes!);

    return RefreshIndicator(
      onRefresh: _loadPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Next Prayer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextPrayer,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time until next prayer:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    _timeUntilNext,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrayerTimeRow('Fajr', _prayerTimes!.fajr),
                  _buildPrayerTimeRow('Sunrise', _prayerTimes!.sunrise),
                  _buildPrayerTimeRow('Dhuhr', _prayerTimes!.dhuhr),
                  _buildPrayerTimeRow('Asr', _prayerTimes!.asr),
                  _buildPrayerTimeRow('Maghrib', _prayerTimes!.maghrib),
                  _buildPrayerTimeRow('Isha', _prayerTimes!.isha),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Long: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeRow(String name, DateTime? time) {
    final formattedTime = _prayerTimeService.formatPrayerTime(time);
    final isNext = _prayerTimeService.getNextPrayer(_prayerTimes!) == name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? Theme.of(context).primaryColor : null,
            ),
          ),
          Text(
            formattedTime,
            style: TextStyle(
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: isNext ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
} 