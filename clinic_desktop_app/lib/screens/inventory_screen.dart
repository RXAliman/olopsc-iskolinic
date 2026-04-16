import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  final _horizontalScrollCtrl = ScrollController();
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

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
    _horizontalScrollCtrl.dispose();
    super.dispose();
  }

  void _showAddStockDialog(InventoryItem item) {
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 360,
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
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Supply: ${item.itemName}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Stock: ${item.quantity}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                "Fields with asterisks (*) are required to be filled up.",
                style: TextStyle(
                  color: AppTheme.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: 'Quantity to Add ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
              ),
              const SizedBox(height: 24),
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
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      if (qty <= 0) return;
                      context.read<InventoryProvider>().addStock(
                        item.id,
                        qty,
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
    );
  }

  void _showAddNewItemDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final lowStockCtrl = TextEditingController();
    String selectedClinic = 'Pre-school Clinic';
    String selectedType = 'piece';
    final formKey = GlobalKey<FormState>();

    final clinics = [
      'Pre-school Clinic',
      'Grade School Clinic',
      'Junior High School Clinic',
      'Senior High School Clinic',
      'College Clinic',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
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
                            Icons.post_add_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'New Supply Item',
                          style: Theme.of(ctx).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Fields with asterisks (*) are required to be filled up.",
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        label: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Supply Name ',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.danger),
                              ),
                            ],
                          ),
                        ),
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            decoration: InputDecoration(
                              label: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Initial Quantity ',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: lowStockCtrl,
                            decoration: InputDecoration(
                              label: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w400,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Low Stock At ',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: AppTheme.danger),
                                    ),
                                  ],
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.warning_amber_rounded,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClinic,
                      decoration: const InputDecoration(
                        labelText: 'Clinic Location *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: clinics.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedClinic = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Item Type *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'piece',
                          child: Text('Piece (Individual)'),
                        ),
                        DropdownMenuItem(
                          value: 'bottle',
                          child: Text('Bottle / Roll'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 32),
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
                            if (formKey.currentState!.validate()) {
                              context
                                  .read<InventoryProvider>()
                                  .addNewSupplyItem(
                                    itemName: nameCtrl.text.trim(),
                                    initialQuantity: int.parse(qtyCtrl.text),
                                    lowStockAmount: int.parse(
                                      lowStockCtrl.text,
                                    ),
                                    clinic: selectedClinic,
                                    itemType: selectedType,
                                  );
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Create Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditItemDialog(InventoryItem item) {
    final nameCtrl = TextEditingController(text: item.itemName);
    final lowStockCtrl = TextEditingController(
      text: item.lowStockAmount.toString(),
    );
    String selectedClinic = item.clinic.isNotEmpty
        ? item.clinic
        : 'Pre-school Clinic';
    String selectedType = item.itemType.isNotEmpty ? item.itemType : 'piece';
    final formKey = GlobalKey<FormState>();

    final clinics = [
      'Pre-school Clinic',
      'Grade School Clinic',
      'Junior High School Clinic',
      'Senior High School Clinic',
      'College Clinic',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
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
                            Icons.settings_suggest_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Edit Supply Item',
                          style: Theme.of(ctx).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Fields with asterisks (*) are required to be filled up.",
                      style: TextStyle(
                        color: AppTheme.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        label: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Supply Name ',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.danger),
                              ),
                            ],
                          ),
                        ),
                        prefixIcon: const Icon(Icons.medical_services_outlined),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: lowStockCtrl,
                      decoration: InputDecoration(
                        label: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Low Stock At ',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.danger),
                              ),
                            ],
                          ),
                        ),
                        prefixIcon: const Icon(Icons.warning_amber_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClinic,
                      decoration: const InputDecoration(
                        labelText: 'Clinic Location *',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: clinics.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedClinic = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Item Type *',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'piece',
                          child: Text('Piece (Individual)'),
                        ),
                        DropdownMenuItem(
                          value: 'bottle',
                          child: Text('Bottle / Roll'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedType = v);
                      },
                    ),
                    const SizedBox(height: 32),
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
                            if (formKey.currentState!.validate()) {
                              final updated = item.copyWith(
                                itemName: nameCtrl.text.trim(),
                                lowStockAmount: int.parse(lowStockCtrl.text),
                                clinic: selectedClinic,
                                itemType: selectedType,
                              );
                              context
                                  .read<InventoryProvider>()
                                  .updateInventoryItem(updated);
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Update Item'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(InventoryItem item) {
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
                'How many units of ${item.itemName} to remove?',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              Text(
                'Current stock: ${item.quantity}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                "Fields with asterisks (*) are required to be filled up.",
                style: TextStyle(
                  color: AppTheme.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyCtrl,
                decoration: InputDecoration(
                  label: Text.rich(
                    TextSpan(
                      style: GoogleFonts.inter(fontWeight: FontWeight.w400),
                      children: [
                        TextSpan(
                          text: 'Quantity to remove ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppTheme.danger),
                        ),
                      ],
                    ),
                  ),
                  prefixIcon: const Icon(Icons.remove_circle_outline),
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
                      context.read<InventoryProvider>().deductStock(
                        item.itemName,
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

  void _showDeleteConfirmationDialog(InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supply'),
        content: Text(
          'Are you sure you want to permanently delete "${item.itemName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<InventoryProvider>().deleteItem(item.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inventory, _) {
        var filteredItems = inventory.items.where((item) {
          if (_searchQuery.isEmpty) return true;
          return item.itemName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }).toList();

        // Sorting
        filteredItems.sort((a, b) {
          int cmp;
          switch (_sortColumnIndex) {
            case 0:
              cmp = a.itemName.compareTo(b.itemName);
              break;
            case 1:
              cmp = a.quantity.compareTo(b.quantity);
              break;
            case 2:
              cmp = a.clinic.compareTo(b.clinic);
              break;
            case 3:
              cmp = a.itemType.compareTo(b.itemType);
              break;
            case 4:
              cmp = a.lowStockAmount.compareTo(b.lowStockAmount);
              break;
            default:
              cmp = 0;
          }
          return _sortAscending ? cmp : -cmp;
        });

        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Track and manage clinic supplies',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Search & Add Row
              Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Search supplies...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _showAddNewItemDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add New Item'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppTheme.accent),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Expiration Warning Note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: Please manually verify the supply\'s physical expiration date before use.',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inventory table
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: filteredItems.isEmpty
                      ? const Center(child: Text('No supplies found'))
                      : Scrollbar(
                          controller: _horizontalScrollCtrl,
                          thumbVisibility: true,
                          notificationPredicate: (notification) =>
                              notification.depth == 1,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollCtrl,
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                sortColumnIndex: _sortColumnIndex,
                                sortAscending: _sortAscending,
                                headingRowColor: WidgetStateProperty.all(
                                  AppTheme.cardLight,
                                ),
                                columns: [
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Supply Item Name',
                                      child: Text(
                                        'Supply Item',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onSort: (idx, asc) => _onSort(idx, asc),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Current Stock Level',
                                      child: Text(
                                        'In Stock',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    numeric: true,
                                    onSort: (idx, asc) => _onSort(idx, asc),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Location of the clinic',
                                      child: Text(
                                        'Clinic',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onSort: (idx, asc) => _onSort(idx, asc),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Type of supply item',
                                      child: Text(
                                        'Type',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onSort: (idx, asc) => _onSort(idx, asc),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Low Stock Threshold',
                                      child: Text(
                                        'Low Stock At',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    numeric: true,
                                    onSort: (idx, asc) => _onSort(idx, asc),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Inventory Status',
                                      child: Text(
                                        'Status',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: const Tooltip(
                                      message: 'Available Actions',
                                      child: Text(
                                        'Actions',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: filteredItems.map((item) {
                                  final isLow = item.isLowStock;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(item.quantity.toString())),
                                      DataCell(Text(item.clinic)),
                                      DataCell(Text(item.itemType)),
                                      DataCell(
                                        Text(item.lowStockAmount.toString()),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLow
                                                ? AppTheme.danger.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.green.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isLow ? 'LOW STOCK' : 'HEALTHY',
                                            style: TextStyle(
                                              color: isLow
                                                  ? AppTheme.danger
                                                  : Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons
                                                    .add_circle_outline_rounded,
                                                color: AppTheme.accent,
                                                size: 20,
                                              ),
                                              tooltip: 'Add Stock',
                                              onPressed: () =>
                                                  _showAddStockDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons
                                                    .remove_circle_outline_rounded,
                                                color: AppTheme.danger,
                                                size: 20,
                                              ),
                                              tooltip: 'Remove Stock',
                                              onPressed: () =>
                                                  _showRemoveDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_note_rounded,
                                                color: AppTheme.textMuted,
                                                size: 20,
                                              ),
                                              tooltip: 'Edit Item',
                                              onPressed: () =>
                                                  _showEditItemDialog(item),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: AppTheme.danger,
                                                size: 20,
                                              ),
                                              tooltip: 'Delete Item',
                                              onPressed: () =>
                                                  _showDeleteConfirmationDialog(
                                                    item,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }
}

// _InventoryRow class removed in favor of DataTable rows
