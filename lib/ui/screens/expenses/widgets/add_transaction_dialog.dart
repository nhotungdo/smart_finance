import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _transactionType = 'expense';
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn danh mục')),
        );
        return;
      }
      
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      ref.read(transactionsProvider.notifier).addTransaction(
        amount: amount,
        transactionType: _transactionType,
        transactionDate: _selectedDate,
        categoryId: _selectedCategoryId,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );
      
      Navigator.of(context).pop();
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
        constraints: const BoxConstraints(maxWidth: 500),
        child: BentoCard(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Thêm giao dịch mới',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Loại giao dịch
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'expense',
                      label: Text('Chi phí'),
                    ),
                    ButtonSegment<String>(
                      value: 'income',
                      label: Text('Thu nhập'),
                    ),
                  ],
                  selected: {_transactionType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _transactionType = newSelection.first;
                      _selectedCategoryId = null;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    selectedBackgroundColor: _transactionType == 'income' 
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : theme.colorScheme.error.withValues(alpha: 0.2),
                    selectedForegroundColor: _transactionType == 'income'
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Số tiền
                SmartTextField(
                  controller: _amountController,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  labelText: 'Số tiền',
                  prefixText: '₫ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số tiền';
                    if (double.tryParse(value) == null) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Danh mục
                categoriesState.when(
                  data: (categories) {
                    final filteredCategories = categories.where((c) => c.categoryType == _transactionType).toList();
                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('Lỗi tải danh mục: $e'),
                ),
                const SizedBox(height: 16),
                
                // Ngày
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày giao dịch',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                      ],
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
                const SizedBox(height: 32),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SmartButton.text(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 12),
                    SmartButton(
                      onPressed: _saveTransaction,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: const Text('Lưu giao dịch', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
