import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/supplies.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddStockDialog() {
    String? selectedItem;
    final qtyCtrl = TextEditingController();
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_box_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Add Stock',
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Item dropdown
                DropdownButtonFormField<String>(
                  value: selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Supply Item *',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  items: kSuppliesList
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedItem = v),
                ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),

                // Expiration date
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => expirationDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date *',
                      prefixIcon: Icon(Icons.calendar_month_rounded),
                    ),
                    child: Text(
                      expirationDate != null
                          ? DateFormat('MMM dd, yyyy').format(expirationDate!)
                          : 'Select date',
                      style: TextStyle(
                        color: expirationDate != null
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedItem == null ||
                            qtyCtrl.text.isEmpty ||
                            expirationDate == null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                          return;
                        }
                        final qty = int.tryParse(qtyCtrl.text) ?? 0;
                        if (qty <= 0) return;

                        context.read<InventoryProvider>().addStock(
                          itemName: selectedItem!,
                          quantity: qty,
                          expirationDate: expirationDate!,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add Stock'),
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

  void _showRemoveDialog(String itemName, int currentQty) {
    final qtyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remove Stock',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'How many units of $itemName to remove?',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              Text(
                'Current stock: $currentQty',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Quantity to remove',
                  prefixIcon: Icon(Icons.remove_circle_outline),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                    ),
                    onPressed: () {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) return;
                      context.read<InventoryProvider>().removeStock(
                        itemName,
                        qty,
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        // Build the display list from kSuppliesList with quantities
        final items = kSuppliesList.where((name) {
          if (_searchQuery.isEmpty) return true;
          return name.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Inventory',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showAddStockDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add Stock'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Track and manage clinic supplies',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Search bar
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search supplies...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(height: 20),

              // Inventory table
              Expanded(
                child: Card(
                  child: items.isEmpty
                      ? const Center(child: Text('No supplies found'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final itemName = items[index];
                            final totalQty = inventory.summary[itemName] ?? 0;
                            final batches = inventory.batchesForItem(itemName);

                            return _InventoryRow(
                              itemName: itemName,
                              totalQty: totalQty,
                              batches: batches,
                              onRemove: () =>
                                  _showRemoveDialog(itemName, totalQty),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final String itemName;
  final int totalQty;
  final List batches;
  final VoidCallback onRemove;

  const _InventoryRow({
    required this.itemName,
    required this.totalQty,
    required this.batches,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      childrenPadding: const EdgeInsets.only(left: 60, right: 20, bottom: 12),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: totalQty > 0
              ? AppTheme.accent.withValues(alpha: 0.1)
              : AppTheme.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.medical_services_outlined,
          size: 18,
          color: totalQty > 0 ? AppTheme.accent : AppTheme.danger,
        ),
      ),
      title: Text(itemName, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        '$totalQty units in stock',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: totalQty > 0 ? AppTheme.textMuted : AppTheme.danger,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: totalQty > 0
                  ? AppTheme.accent.withValues(alpha: 0.1)
                  : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalQty',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: totalQty > 0 ? AppTheme.accent : AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (totalQty > 0)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              tooltip: 'Remove stock',
              color: AppTheme.danger,
            ),
        ],
      ),
      children: batches.isEmpty
          ? [
              Text(
                'No stock batches',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]
          : batches.map<Widget>((batch) {
              final isExpired = batch.expirationDate.isBefore(DateTime.now());
              final isExpiringSoon =
                  !isExpired &&
                  batch.expirationDate.isBefore(
                    DateTime.now().add(const Duration(days: 30)),
                  );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isExpired
                          ? Icons.warning_rounded
                          : Icons.calendar_today_rounded,
                      size: 14,
                      color: isExpired
                          ? AppTheme.danger
                          : isExpiringSoon
                          ? AppTheme.warning
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exp: ${dateFormat.format(batch.expirationDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isExpired
                            ? AppTheme.danger
                            : isExpiringSoon
                            ? AppTheme.warning
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? AppTheme.danger.withValues(alpha: 0.1)
                            : AppTheme.cardLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${batch.quantity} units',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? AppTheme.danger
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (isExpired) ...[
                      const SizedBox(width: 8),
                      Text(
                        'EXPIRED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
    );
  }
}
