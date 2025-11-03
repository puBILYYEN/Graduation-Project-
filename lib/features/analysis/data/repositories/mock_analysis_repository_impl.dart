import '../../domain/entities/body_metrics.dart';
import '../../domain/repositories/analysis_repository.dart';

class MockAnalysisRepositoryImpl implements AnalysisRepository {
  BodyMetrics _mockData = BodyMetrics(
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

  @override
  Future<BodyMetrics> getBodyMetrics(String period) async {
    // In a real implementation, you would fetch data based on the period.
    // For now, we just return the mock data.
    return _mockData;
  }

  @override
  Future<void> updateBodyMetrics(BodyMetrics metrics) async {
    // In a real implementation, you would save the data.
    // For now, we just update the mock data in memory.
    _mockData = metrics;
  }
}
