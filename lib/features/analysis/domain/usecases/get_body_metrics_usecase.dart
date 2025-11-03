import '../entities/body_metrics.dart';
import '../repositories/analysis_repository.dart';

class GetBodyMetricsUseCase {
  final AnalysisRepository repository;

  GetBodyMetricsUseCase(this.repository);

  Future<BodyMetrics> call(String period) {
    return repository.getBodyMetrics(period);
  }
}
