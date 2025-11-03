import '../entities/body_metrics.dart';
import '../repositories/analysis_repository.dart';

class UpdateBodyMetricsUseCase {
  final AnalysisRepository repository;

  UpdateBodyMetricsUseCase(this.repository);

  Future<void> call(BodyMetrics metrics) {
    return repository.updateBodyMetrics(metrics);
  }
}
