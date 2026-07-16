import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/repositories/category_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (companyId == null) return [];
    await repo.seedDefaultCategories(companyId);
    return repo.getCategories(companyId: companyId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(currentUserProfileProvider.future);
      final companyId = profile?.companyId;
      if (companyId == null) return [];
      return ref
          .read(categoryRepositoryProvider)
          .getCategories(companyId: companyId);
    });
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
      CategoriesNotifier.new,
    );
