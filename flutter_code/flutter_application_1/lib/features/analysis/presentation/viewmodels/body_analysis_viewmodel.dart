import 'package:flutter/material.dart';
import '../../domain/entities/body_metrics.dart';
import '../../domain/usecases/get_body_metrics_usecase.dart';
import '../../domain/usecases/update_body_metrics_usecase.dart';

class BodyAnalysisViewModel extends ChangeNotifier {
  final GetBodyMetricsUseCase _getBodyMetricsUseCase;
  final UpdateBodyMetricsUseCase _updateBodyMetricsUseCase;

  BodyAnalysisViewModel(this._getBodyMetricsUseCase, this._updateBodyMetricsUseCase);

  BodyMetrics? _bodyMetrics;
  BodyMetrics? get bodyMetrics => _bodyMetrics;

  String _selectedPeriod = '週';
  String get selectedPeriod => _selectedPeriod;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool isLoading) {
    _isLoading = isLoading;
    notifyListeners();
  }

  Future<void> fetchBodyMetrics() async {
    _setLoading(true);
    _bodyMetrics = await _getBodyMetricsUseCase(selectedPeriod);
    _setLoading(false);
  }

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
    fetchBodyMetrics();
  }

  Future<void> updateSleepData() async {
    if (_bodyMetrics == null) return;
    final newMetrics = BodyMetrics(
      sleepHours: 9,
      sleepChange: 25.0,
      height: _bodyMetrics!.height,
      heightChange: _bodyMetrics!.heightChange,
      weight: _bodyMetrics!.weight,
      weightChange: _bodyMetrics!.weightChange,
      heartRate: _bodyMetrics!.heartRate,
      heartRateChange: _bodyMetrics!.heartRateChange,
      bloodPressure: _bodyMetrics!.bloodPressure,
      bloodPressureChange: _bodyMetrics!.bloodPressureChange,
    );
    await _updateBodyMetricsUseCase(newMetrics);
    await fetchBodyMetrics();
  }

  Future<void> updateWeightData() async {
    if (_bodyMetrics == null) return;
    final newMetrics = BodyMetrics(
      sleepHours: _bodyMetrics!.sleepHours,
      sleepChange: _bodyMetrics!.sleepChange,
      height: _bodyMetrics!.height,
      heightChange: _bodyMetrics!.heightChange,
      weight: 62,
      weightChange: -4.8,
      heartRate: _bodyMetrics!.heartRate,
      heartRateChange: _bodyMetrics!.heartRateChange,
      bloodPressure: _bodyMetrics!.bloodPressure,
      bloodPressureChange: _bodyMetrics!.bloodPressureChange,
    );
    await _updateBodyMetricsUseCase(newMetrics);
    await fetchBodyMetrics();
  }

  Future<void> updateHeartRateData() async {
    if (_bodyMetrics == null) return;
    final newMetrics = BodyMetrics(
      sleepHours: _bodyMetrics!.sleepHours,
      sleepChange: _bodyMetrics!.sleepChange,
      height: _bodyMetrics!.height,
      heightChange: _bodyMetrics!.heightChange,
      weight: _bodyMetrics!.weight,
      weightChange: _bodyMetrics!.weightChange,
      heartRate: 75,
      heartRateChange: 7.1,
      bloodPressure: _bodyMetrics!.bloodPressure,
      bloodPressureChange: _bodyMetrics!.bloodPressureChange,
    );
    await _updateBodyMetricsUseCase(newMetrics);
    await fetchBodyMetrics();
  }

  Future<void> updateBodyMetricsFromPowerBI() async {
    final newMetrics = BodyMetrics(
      sleepHours: 8,
      sleepChange: 15.0,
      height: 175,
      heightChange: 0,
      weight: 63,
      weightChange: -3.1,
      heartRate: 68,
      heartRateChange: -2.9,
      bloodPressure: '118/78',
      bloodPressureChange: -1.5,
    );
    await _updateBodyMetricsUseCase(newMetrics);
    await fetchBodyMetrics();
  }

  Future<void> resetToDefault() async {
    final newMetrics = BodyMetrics(
      sleepHours: 8,
      sleepChange: 10,
      height: 175,
      heightChange: 0,
      weight: 65,
      weightChange: -1.2,
      heartRate: 70,
      heartRateChange: -2,
      bloodPressure: '120/80',
      bloodPressureChange: 1,
    );
    await _updateBodyMetricsUseCase(newMetrics);
    await fetchBodyMetrics();
  }
}
