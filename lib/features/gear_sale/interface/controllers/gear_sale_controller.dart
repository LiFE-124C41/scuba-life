import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gear_sale_item.dart';
import '../../domain/repositories/gear_sale_repository.dart';
import '../../infrastructure/repositories/mock_gear_sale_repository.dart';
import '../../usecase/get_gear_sale_items.dart';
import '../../../../core/usecase/usecase.dart';

final gearSaleRepositoryProvider = Provider<GearSaleRepository>((ref) {
  return MockGearSaleRepository();
});

final getGearSaleItemsUseCaseProvider = Provider<GetGearSaleItems>((ref) {
  final repo = ref.watch(gearSaleRepositoryProvider);
  return GetGearSaleItems(repo);
});

final gearSaleItemsProvider = FutureProvider<List<GearSaleItem>>((ref) async {
  final useCase = ref.watch(getGearSaleItemsUseCaseProvider);
  return await useCase(const NoParams());
});
