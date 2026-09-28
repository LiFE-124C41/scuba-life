import 'package:flutter/material.dart';
import '../../domain/entities/marine_weather.dart';
import '../../infrastructure/repositories/mock_marine_weather_repository.dart';
import '../../usecase/get_marine_weather.dart';
import '../../../../core/usecase/usecase.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _getWeather = GetPopularSpotWeathers(MockMarineWeatherRepository());
  List<MarineWeather> _weathers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _getWeather(const NoParams());
    if (mounted) {
      setState(() {
        _weathers = list;
        _isLoading = false;
      });
    }
  }

  Color _getConditionColor(DivingConditionLevel level) {
    switch (level) {
      case DivingConditionLevel.good:
        return Colors.green;
      case DivingConditionLevel.caution:
        return Colors.orange;
      case DivingConditionLevel.closed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('海況・海洋気象予報'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _weathers.length,
              itemBuilder: (context, index) {
                final item = _weathers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.spotName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getConditionColor(item.conditionLevel).withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getConditionColor(item.conditionLevel),
                                ),
                              ),
                              child: Text(
                                item.conditionLevel.label,
                                style: TextStyle(
                                  color: _getConditionColor(item.conditionLevel),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoCol('天気', item.weatherDescription),
                            _buildInfoCol('水温', '${item.waterTemperatureCelsius}℃'),
                            _buildInfoCol('波高', '${item.waveHeightMeter}m'),
                            _buildInfoCol('風', '${item.windDirection} ${item.windSpeedMeterPerSec}m/s'),
                            _buildInfoCol('透明度', '${item.estimatedVisibilityMeter.toInt()}m'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
