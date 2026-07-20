import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/services/receipt_image_store.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key, this.transaction});

  final TransactionModel? transaction;

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _transactionType = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  Uint8List? _receiptBytes;
  String? _receiptName;
  bool _isSaving = false;
  String? _existingReceiptPath;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      _amountController.text = transaction.amount.toString();
      _descriptionController.text = transaction.description ?? '';
      _transactionType = transaction.transactionType;
      _selectedCategoryId = transaction.categoryId;
      _selectedDate = transaction.transactionDate;
      _existingReceiptPath = transaction.receiptImagePath;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    return showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<void> _pickReceiptImage() async {
    final supportsCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supportsCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _receiptBytes = bytes;
      _receiptName = image.name;
    });
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
        return;
      }

      final amount = int.parse(_amountController.text.trim());

      setState(() => _isSaving = true);
      try {
        final receiptImagePath = _receiptBytes == null
            ? null
            : await saveReceiptImage(
                _receiptBytes!,
                _receiptName ?? 'receipt.jpg',
              );
        final description = _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null;
        final notifier = ref.read(transactionsProvider.notifier);
        if (_isEditing) {
          await notifier.updateTransaction(
            widget.transaction!.copyWith(
              amount: amount,
              transactionType: _transactionType,
              transactionDate: _selectedDate,
              categoryId: _selectedCategoryId,
              description: description,
              receiptImagePath: receiptImagePath ?? _existingReceiptPath,
            ),
          );
        } else {
          await notifier.addTransaction(
            amount: amount,
            transactionType: _transactionType,
            transactionDate: _selectedDate,
            categoryId: _selectedCategoryId,
            description: description,
            receiptImagePath: receiptImagePath,
          );
        }
        if (mounted) Navigator.of(context).pop();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể lưu giao dịch: $error')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesState = ref.watch(categoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: BentoCard(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch mới',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Loại giao dịch
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment<TransactionType>(
                        value: TransactionType.expense,
                        label: Text('Chi phí'),
                      ),
                      ButtonSegment<TransactionType>(
                        value: TransactionType.income,
                        label: Text('Thu nhập'),
                      ),
                    ],
                    selected: {_transactionType},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setState(() {
                        _transactionType = newSelection.first;
                        _selectedCategoryId = null;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      selectedBackgroundColor:
                          _transactionType == TransactionType.income
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : theme.colorScheme.error.withValues(alpha: 0.2),
                      selectedForegroundColor:
                          _transactionType == TransactionType.income
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Số tiền
                  SmartTextField(
                    controller: _amountController,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    labelText: 'Số tiền',
                    prefixText: '₫ ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final rawValue = value?.trim() ?? '';
                      if (rawValue.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(rawValue)) {
                        return 'Số tiền chỉ được chứa chữ số';
                      }
                      final amount = int.tryParse(rawValue);
                      if (amount == null || amount <= 0) {
                        return 'Số tiền phải là số nguyên lớn hơn 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Danh mục
                  categoriesState.when(
                    data: (categories) {
                      final filteredCategories = categories
                          .where((c) => c.categoryType == _transactionType)
                          .toList();
                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        initialValue: _selectedCategoryId,
                        items: filteredCategories.map((cat) {
                          return DropdownMenuItem(
                            value: cat.categoryId,
                            child: Text(cat.categoryName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn danh mục' : null,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Lỗi tải danh mục: $e'),
                  ),
                  const SizedBox(height: 16),

                  // Ngày
                  FormField<DateTime>(
                    initialValue: _selectedDate,
                    validator: (value) {
                      if (value == null) return 'Vui lòng chọn ngày giao dịch';
                      final today = DateTime.now();
                      final endOfToday = DateTime(
                        today.year,
                        today.month,
                        today.day,
                        23,
                        59,
                        59,
                      );
                      if (value.isBefore(DateTime(2000)) ||
                          value.isAfter(endOfToday)) {
                        return 'Ngày giao dịch không hợp lệ';
                      }
                      return null;
                    },
                    builder: (field) => InkWell(
                      onTap: () async {
                        final picked = await _selectDate(context);
                        if (picked == null) return;
                        setState(() => _selectedDate = picked);
                        field.didChange(picked);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Ngày giao dịch',
                          errorText: field.errorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: theme.textTheme.bodyLarge,
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả
                  SmartTextField(
                    controller: _descriptionController,
                    labelText: 'Mô tả (không bắt buộc)',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _receiptBytes == null
                          ? 'Thêm ảnh chứng từ'
                          : 'Đổi ảnh chứng từ',
                    ),
                  ),
                  if (_receiptBytes != null) ...[
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _receiptBytes!,
                            width: double.infinity,
                            height: 132,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filledTonal(
                            tooltip: 'Xóa ảnh chứng từ',
                            onPressed: () => setState(() {
                              _receiptBytes = null;
                              _receiptName = null;
                            }),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SmartButton.text(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: const Text('Hủy'),
                      ),
                      const SizedBox(width: 12),
                      SmartButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Lưu thay đổi' : 'Lưu giao dịch',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
