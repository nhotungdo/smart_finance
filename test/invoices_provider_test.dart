import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/data/repositories/invoice_repository.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';

class _FakeInvoiceRepository implements InvoiceRepository {
  int fetchCount = 0;
  final requests = <(String companyId, String? createdBy)>[];

  @override
  Future<List<InvoiceModel>> getInvoices(
    String companyId, {
    String? createdBy,
  }) async {
    fetchCount++;
    requests.add((companyId, createdBy));
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ActiveProfileNotifier extends Notifier<UserModel> {
  @override
  UserModel build() => UserModel(
    userId: 'accountant-a',
    companyId: 'company-a',
    roleId: 'role_accountant',
    fullName: 'Accountant A',
    email: 'accountant-a@example.com',
  );

  void changeTo(UserModel profile) => state = profile;
}

final _activeProfileProvider =
    NotifierProvider<_ActiveProfileNotifier, UserModel>(
      _ActiveProfileNotifier.new,
    );

void main() {
  test('invoice summary is derived from the current invoice list', () {
    final now = DateTime(2026, 7, 17);
    final summary = InvoiceSummary.fromInvoices([
      InvoiceModel(
        id: 'invoice-1',
        companyId: 'company-1',
        uploadedBy: 'user-1',
        totalAmount: 3850000,
        scanStatus: InvoiceScanStatus.scanned,
        createdAt: now,
        updatedAt: now,
      ),
      InvoiceModel(
        id: 'invoice-2',
        companyId: 'company-1',
        uploadedBy: 'user-1',
        totalAmount: 1320000,
        scanStatus: InvoiceScanStatus.notScanned,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    expect(summary.totalValue, 5170000);
    expect(summary.pendingValue, 1320000);
    expect(summary.invoiceCount, 2);
    expect(summary.pendingCount, 1);
  });

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

  test('invoice notifier reloads when the signed-in profile changes', () async {
    final repository = _FakeInvoiceRepository();
    final container = ProviderContainer(
      overrides: [
        invoiceRepositoryProvider.overrideWithValue(repository),
        currentUserProfileProvider.overrideWith(
          (ref) async => ref.watch(_activeProfileProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(invoicesProvider.future);
    expect(repository.requests.last, ('company-a', 'accountant-a'));

    container
        .read(_activeProfileProvider.notifier)
        .changeTo(
          UserModel(
            userId: 'accountant-b',
            companyId: 'company-b',
            roleId: 'role_accountant',
            fullName: 'Accountant B',
            email: 'accountant-b@example.com',
          ),
        );

    await container.read(invoicesProvider.future);
    expect(repository.requests.last, ('company-b', 'accountant-b'));
    expect(repository.fetchCount, 2);
  });
}
