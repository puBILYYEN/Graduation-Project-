import '../entities/weight_record.dart';
import '../repositories/statistics_repository.dart';

class GetWeightHistoryUseCase {
  final StatisticsRepository repository;

  GetWeightHistoryUseCase(this.repository);

  Future<List<WeightRecord>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getWeightHistory(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
