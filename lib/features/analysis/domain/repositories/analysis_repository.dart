import '../entities/body_metrics.dart';

abstract class AnalysisRepository {
  Future<BodyMetrics> getBodyMetrics(String period);
  Future<void> updateBodyMetrics(BodyMetrics metrics);
}
