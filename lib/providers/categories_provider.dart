import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    // Seed default if empty
    await repo.seedDefaultCategories('default_company'); 
    return repo.getCategories();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(categoryRepositoryProvider).getCategories();
    });
  }
}

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(CategoriesNotifier.new);
