import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  int fetchCount = 0;

  @override
  Future<List<InvoiceModel>> getInvoices(String companyId) async {
    fetchCount++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'invoice notifier can refresh repeatedly without late init errors',
    () async {
      final repository = _FakeInvoiceRepository();
      final container = ProviderContainer(
        overrides: [
          invoiceRepositoryProvider.overrideWithValue(repository),
          currentUserProfileProvider.overrideWith(
            (ref) async => UserModel(
              userId: 'user-1',
              companyId: 'company-1',
              fullName: 'Test User',
              email: 'test@example.com',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(invoicesProvider.future);
      container.read(invoicesProvider.notifier).refresh();
      await container.read(invoicesProvider.future);
      container.read(invoicesProvider.notifier).refresh();
      await container.read(invoicesProvider.future);

      expect(repository.fetchCount, 3);
      expect(container.read(invoicesProvider).hasError, isFalse);
    },
  );
}
