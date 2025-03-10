import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:halalapp/services/prayer_time_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrayerTimeScreen extends StatefulWidget {
  const PrayerTimeScreen({super.key});

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  PrayerTimeService? _prayerTimeService;
  PrayerTimes? _prayerTimes;
  Timer? _timer;
  String _timeUntilNext = '';
  String _locationName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _prayerTimeService = await PrayerTimeService.create();
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
      setState(() => _isLoading = true);
      final (prayerTimes, locationName) =
          await _prayerTimeService!.getPrayerTimes();
      setState(() {
        _prayerTimes = prayerTimes;
        _locationName = locationName;
        _isLoading = false;
        _updateTimeUntilNext();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.error}: ${e.toString()}')),
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
    final duration = _prayerTimeService!.getTimeUntilNextPrayer(_prayerTimes!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    setState(() {
      _timeUntilNext =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(child: Text(l10n.loading));
    }

    if (_prayerTimes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.error),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPrayerTimes,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    final nextPrayer = _prayerTimeService!.getNextPrayer(_prayerTimes!);

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
                    l10n.prayerTimes,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPrayerNameLocalized(nextPrayer, l10n),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.timeUntilNextPrayer,
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
                  _buildPrayerTimeRow(l10n.fajr, _prayerTimes!.fajr),
                  _buildPrayerTimeRow('Sunrise', _prayerTimes!.sunrise),
                  _buildPrayerTimeRow(l10n.dhuhr, _prayerTimes!.dhuhr),
                  _buildPrayerTimeRow(l10n.asr, _prayerTimes!.asr),
                  _buildPrayerTimeRow(l10n.maghrib, _prayerTimes!.maghrib),
                  _buildPrayerTimeRow(l10n.isha, _prayerTimes!.isha),
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
                    l10n.location,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _locationName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPrayerNameLocalized(String prayerName, AppLocalizations l10n) {
    switch (prayerName) {
      case 'Fajr':
        return l10n.fajr;
      case 'Dhuhr':
        return l10n.dhuhr;
      case 'Asr':
        return l10n.asr;
      case 'Maghrib':
        return l10n.maghrib;
      case 'Isha':
        return l10n.isha;
      default:
        return prayerName;
    }
  }

  Widget _buildPrayerTimeRow(String name, DateTime? time) {
    final formattedTime = _prayerTimeService!.formatPrayerTime(time);
    final isNext = _prayerTimeService!.getNextPrayer(_prayerTimes!) == name;

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
