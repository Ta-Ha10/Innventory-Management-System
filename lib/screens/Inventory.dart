import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:rrms/component/colors.dart';
import 'dart:math' show max, min, Random;

import '../widget/side_bar.dart';
import '../widget/top_bar.dart';
import 'inventory_history.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with TickerProviderStateMixin {
  // control sidebar visibility (matches Dashboard pattern)
  bool isSidebarVisible = true;

  late TabController _tabController;
  late ValueNotifier<int> _selectedTabIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ValueNotifier<List<String>> categories = ValueNotifier<List<String>>([
    'All',
  ]);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedItemId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addCategoryController = TextEditingController();
  final TextEditingController _addQuantityController = TextEditingController();
  final TextEditingController _addUnitController = TextEditingController();
  final TextEditingController _addSupplierController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();

  final Map<String, Map<String, dynamic>> _localDocs = {};

  // Controls visibility of the Add panel (opened by FAB)
  bool _showAddPanel = false;
  // Controls whether the FAB's expanded options are visible
  bool _fabOpen = false;

  final Stream<QuerySnapshot<Map<String, dynamic>>> _rawStream =
      FirebaseFirestore.instance.collection('raw_components').snapshots();

  final Color primaryColor = const Color(0xff4a4a4a);
  final Color secondaryColor = const Color(0xff6fad99);

  // (previous tab tracking removed — not currently used)

  // Supplier cache for dropdown
  List<String> _supplierCache = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: max(1, categories.value.length),
      vsync: this,
    );
    _selectedTabIndex = ValueNotifier<int>(0);

    _tabController.addListener(() {
      final prev = _selectedTabIndex.value;
      if (_tabController.index != prev) {
        _selectedTabIndex.value = _tabController.index;
      }
    });

    _unitController.addListener(() => setState(() {}));
    _addUnitController.addListener(() => setState(() {}));
    categories.addListener(_onCategoriesChanged);

    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('suppliers')
          .get();
      final names = snapshot.docs.map((doc) => doc['name'] as String).toList();
      setState(() {
        _supplierCache = names..sort();
      });
    } catch (e) {
      if (kDebugMode) print('Error loading suppliers: $e');
    }
  }

  Future<void> _saveSupplier(String name, String itemName) async {
    if (_supplierCache.contains(name)) return;

    final fakeEmail = '${name.toLowerCase().replaceAll(' ', '_')}@example.com';
    final fakePhone =
        '+1-${Random().nextInt(900) + 100}-${Random().nextInt(9000) + 1000}';

    await FirebaseFirestore.instance.collection('suppliers').add({
      'name': name,
      'email': fakeEmail,
      'phone': fakePhone,
      'suppliedItems': FieldValue.arrayUnion([itemName]),
    });

    _supplierCache.add(name);
    _supplierCache.sort();
  }

  @override
  void dispose() {
    _unitController.removeListener(() => setState(() {}));
    _addUnitController.removeListener(() => setState(() {}));
    categories.removeListener(_onCategoriesChanged);
    try {
      _tabController.dispose();
    } catch (_) {}
    _searchController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _addNameController.dispose();
    _addCategoryController.dispose();
    _addQuantityController.dispose();
    _addUnitController.dispose();
    _addSupplierController.dispose();
    _addPriceController.dispose();
    super.dispose();
  }

  void _onCategoriesChanged() {
    final newLen = max(1, categories.value.length);
    final currentIndex = _selectedTabIndex.value;
    final safeIndex = (currentIndex >= 0) ? min(currentIndex, newLen - 1) : 0;

    try {
      _tabController.dispose();
    } catch (_) {}

    _tabController = TabController(
      length: newLen,
      vsync: this,
      initialIndex: safeIndex,
    );
    _tabController.addListener(() {
      final prev = _selectedTabIndex.value;
      if (_tabController.index != prev) {
        _selectedTabIndex.value = _tabController.index;
      }
    });

    _selectedTabIndex.value = _tabController.index;
    setState(() {});
  }

  void _onSidebarSelect(String category) {
    final norm = category
        .toLowerCase()
        .replaceAll(RegExp(r"\s+|_|-|/|&"), ' ')
        .trim();
    final idx = categories.value.indexWhere(
      (t) =>
          t.toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim() ==
          norm,
    );
    if (idx >= 0) {
      final safeIdx = idx.clamp(0, max(0, _tabController.length - 1)).toInt();
      _tabController.index = safeIdx;
    } else {
      final existing = [...categories.value];
      existing.removeWhere((e) => e.toLowerCase() == 'all');
      final lowerSet = existing.map((e) => e.toLowerCase()).toSet();
      if (!lowerSet.contains(category.toLowerCase())) existing.add(category);
      existing.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final newList = ['All', ...existing];

      categories.value = newList;
      final newIndex = newList.indexWhere(
        (t) => t.toLowerCase() == category.toLowerCase(),
      );

      final oldController = _tabController;
      try {
        oldController.dispose();
      } catch (_) {}

      final safeInitial = (newIndex >= 0)
          ? min(newIndex, newList.length - 1)
          : 0;
      _tabController = TabController(
        length: newList.length,
        vsync: this,
        initialIndex: safeInitial,
      );
      _tabController.addListener(() {
        final prev = _selectedTabIndex.value;
        if (_tabController.index != prev) {
          _selectedTabIndex.value = _tabController.index;
        }
      });

      _selectedTabIndex.value = _tabController.index;
      setState(() {});
    }
  }

  void _onSearchChanged(String v) {
    setState(() {
      _searchQuery = v.toLowerCase();
    });
  }

  int _parseQuantity(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();
    final s = raw.toString();
    final doubleVal = double.tryParse(s);
    if (doubleVal != null) return doubleVal.round();
    final intVal = int.tryParse(s);
    return intVal ?? 0;
  }

  Future<void> _saveItem() async {
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No item selected')));
      return;
    }

    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final supplier = _supplierController.text.trim();
    final unit = _unitController.text.trim();
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);

    if (name.isEmpty ||
        category.isEmpty ||
        supplier.isEmpty ||
        unit.isEmpty ||
        price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final quantityText = _quantityController.text.trim();
    int? quantity;
    if (quantityText.isNotEmpty) {
      final doubleVal = double.tryParse(quantityText);
      if (doubleVal != null) {
        quantity = doubleVal.round();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
        return;
      }
    }

    final data = {
      'name': name,
      'category': category,
      'quantity':
          quantity ??
          _parseQuantity(_localDocs[_selectedItemId!]?['quantity'] ?? 0),
      'unit': unit,
      'supplier': supplier,
      'price': price,
      'pricePerUnit': '$price/$unit',
    };

    _localDocs[_selectedItemId!] = {...data, 'id': _selectedItemId!};
    setState(() {});

    try {
      await FirebaseFirestore.instance
          .collection('raw_components')
          .doc(_selectedItemId!)
          .update(data);

      await _saveSupplier(supplier, name);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item saved')));
      _clearSelection();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _saveNewItem() async {
    final name = _addNameController.text.trim();
    final category = _addCategoryController.text.trim();
    final supplier = _addSupplierController.text.trim();
    final unit = _addUnitController.text.trim();
    final priceText = _addPriceController.text.trim();
    final price = double.tryParse(priceText);

    if (name.isEmpty ||
        category.isEmpty ||
        supplier.isEmpty ||
        unit.isEmpty ||
        price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final quantityText = _addQuantityController.text.trim();
    int quantity = 0;
    if (quantityText.isNotEmpty) {
      final doubleVal = double.tryParse(quantityText);
      if (doubleVal != null) {
        quantity = doubleVal.round();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid quantity')));
        return;
      }
    }

    final data = {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'supplier': supplier,
      'price': price,
      'pricePerUnit': '$price/$unit',
    };

    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _localDocs[tempId] = {...data, 'id': tempId};
    setState(() {});

    try {
      final ref = await FirebaseFirestore.instance
          .collection('raw_components')
          .add(data);
      final realId = ref.id;

      final stored = {...?_localDocs[tempId], 'id': realId};
      _localDocs.remove(tempId);
      _localDocs[realId] = stored;
      setState(() {});

      await _saveSupplier(supplier, name);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added')));
      _clearAddForm();
    } catch (e) {
      _localDocs.remove(tempId);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  Future<void> _showAddQuantityDialog(
    String? id,
    Map<String, dynamic> item,
  ) async {
    if (id == null) return;

    final TextEditingController qtyController = TextEditingController();
    final TextEditingController priceController = TextEditingController(text: item['price']?.toString() ?? '');
    String selectedSupplier = (item['supplier'] ?? '').toString();
    bool sameSupplierAndPrice = true;

    final result = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Quantity'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      hintText: 'Enter quantity to add (e.g., 5 or 2.5)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Same supplier and price'),
                    value: sameSupplierAndPrice,
                    onChanged: (v) => setStateDialog(() => sameSupplierAndPrice = v ?? true),
                  ),
                  if (!sameSupplierAndPrice) ...[
                    const SizedBox(height: 8),
                    // supplier dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSupplier.isNotEmpty && _supplierCache.contains(selectedSupplier) ? selectedSupplier : null,
                      items: _supplierCache.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setStateDialog(() => selectedSupplier = v ?? ''),
                      decoration: const InputDecoration(labelText: 'Supplier', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  final text = qtyController.text.trim();
                  final v = double.tryParse(text);
                  if (v == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid number')));
                    return;
                  }

                  if (!sameSupplierAndPrice) {
                    if (selectedSupplier.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a supplier')));
                      return;
                    }
                    final pText = priceController.text.trim();
                    if (pText.isEmpty || double.tryParse(pText) == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price')));
                      return;
                    }
                  }

                  // return true to indicate submit
                  Navigator.of(context).pop(true);
                },
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );

    if (result != true) return;

    // parse quantity
    final qtyText = qtyController.text.trim();
    final qtyDouble = double.tryParse(qtyText);
    if (qtyDouble == null) return;
    final added = qtyDouble.round();

    final current = _parseQuantity(item['quantity']);
    final newQty = current + added;

    // prepare history data
    final oldPrice = (item['price'] != null) ? double.tryParse(item['price'].toString()) : null;
    final oldSupplier = (item['supplier'] ?? '').toString();
    final newSupplier = sameSupplierAndPrice ? oldSupplier : selectedSupplier;
    final newPrice = sameSupplierAndPrice ? oldPrice : double.tryParse(priceController.text.trim());

    // optimistic local update
    _localDocs[id] = {...item, 'quantity': newQty, 'id': id, 'supplier': newSupplier, 'price': newPrice};
    setState(() {});

    if (id.startsWith('local_')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity updated (local)')));
      return;
    }

    try {
      final updates = <String, dynamic>{'quantity': newQty};
      if (!sameSupplierAndPrice) {
        if (newSupplier.isNotEmpty) updates['supplier'] = newSupplier;
        if (newPrice != null) updates['price'] = newPrice;
      }

      await FirebaseFirestore.instance.collection('raw_components').doc(id).update(updates);

      // write inventory history
      await FirebaseFirestore.instance.collection('inventory_history').add({
        'itemId': id,
        'itemName': item['name'] ?? '',
        'oldSupplier': oldSupplier,
        'newSupplier': newSupplier,
        'sameSupplier': sameSupplierAndPrice,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
        'addedQuantity': added,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity updated')));
    } catch (e) {
      // revert local change on failure
      _localDocs.remove(id);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update quantity: $e')));
    }
  }

  void _clearAddForm() {
    // Clear fields and hide the add panel
    _clearAddFormFields();
    setState(() {
      _showAddPanel = false;
    });
  }

  void _clearAddFormFields() {
    _addNameController.clear();
    _addCategoryController.clear();
    _addQuantityController.clear();
    _addUnitController.clear();
    _addSupplierController.clear();
    _addPriceController.clear();
  }

  void _clearSelection() {
    _selectedItemId = null;
    _nameController.clear();
    _categoryController.clear();
    _quantityController.clear();
    _unitController.clear();
    _supplierController.clear();
    _priceController.clear();
    _selectedTabIndex.value = _selectedTabIndex.value;
    setState(() {});
  }

  Widget _buildSupplierField(
    TextEditingController controller, {
    bool isAdd = false,
  }) {
    // Show a dropdown populated from _supplierCache (loaded from Firestore).
    final items = _supplierCache
        .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
        .toList();
    final value =
        controller.text.isNotEmpty && _supplierCache.contains(controller.text)
        ? controller.text
        : null;
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: (v) {
        controller.text = v ?? '';
      },
      decoration: InputDecoration(
        labelText: 'Supplier *',
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Supplier is required' : null,
    );
  }

  Widget editPanel() {
    return SizedBox(
      width: 420,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Item',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isEmpty ? null : _categoryController.text,
              items: categories.value.where((t) => t.toLowerCase() != 'all').map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => _categoryController.text = v ?? '',
              decoration: const InputDecoration(labelText: 'Category *'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 5 or 5.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit *'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSupplierField(_supplierController),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _unitController,
              builder: (context, unit, _) {
                return TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText:
                        'Price/${unit.text.isNotEmpty ? unit.text : "unit"} *',
                    hintText: 'e.g., 12.50',
                    suffixText: _unitController.text.isNotEmpty
                        ? '/${_unitController.text}'
                        : '/unit',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                  onPressed: _saveItem,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showHistoryDialog(_selectedItemId),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget addPanel() {
    return SizedBox(
      width: 420,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Item',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addNameController,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _addCategoryController.text.isEmpty
                  ? null
                  : _addCategoryController.text,
              items: categories.value
                  .where((t) => t.toLowerCase() != 'all')
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => _addCategoryController.text = v ?? '',
              decoration: const InputDecoration(labelText: 'Category *'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'e.g., 5 or 5.5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _addUnitController,
                    decoration: const InputDecoration(labelText: 'Unit *'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSupplierField(_addSupplierController, isAdd: true),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _addUnitController,
              builder: (context, unit, _) {
                return TextField(
                  controller: _addPriceController,
                  decoration: InputDecoration(
                    labelText:
                        'Price/${unit.text.isNotEmpty ? unit.text : "unit"} *',
                    hintText: 'e.g., 12.50',
                    suffixText: _addUnitController.text.isNotEmpty
                        ? '/${_addUnitController.text}'
                        : '/unit',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _saveNewItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearAddForm,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistoryDialog(String? itemId) async {
    // If itemId is provided, show only that item's history; otherwise show all recent history
  // Open the inventory history page which displays the same content inside a container
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => InventoryHistoryPage(itemId: itemId)));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Ensure sidebar is always visible. On very narrow screens use a compact width.
    final bool isCompact = screenWidth < 700; // compact mode for small screens
    final bool isTablet = screenWidth < 1000 && screenWidth >= 700;
    final double sidebarWidth = isCompact ? 120 : (isTablet ? 180 : 220);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9F9F9),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded mini actions (visible when _fabOpen == true)
          AnimatedOpacity(
            opacity: _fabOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // History with label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Text('History', style: TextStyle(color: Colors.black87)),
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'history_fab',
                      backgroundColor: secondaryColor,
                      onPressed: () {
                        setState(() {
                          _fabOpen = false;
                        });
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => InventoryHistoryPage(itemId: _selectedItemId)));
                      },
                      child: const Icon(Icons.history, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Add with label
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Text('Add', style: TextStyle(color: Colors.black87)),
                    ),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'add_fab',
                      backgroundColor: secondaryColor,
                      onPressed: () {
                        setState(() {
                          _fabOpen = false;
                          _clearSelection();
                          _clearAddFormFields();
                          _showAddPanel = true;
                        });
                      },
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          FloatingActionButton(
            backgroundColor: secondaryColor,
            onPressed: () {
              setState(() {
                _fabOpen = !_fabOpen;
              });
            },
            child: Icon(_fabOpen ? Icons.close : Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar with animated collapse (matches Dashboard style)
          if (isSidebarVisible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: sidebarWidth,
              child: SideBar(
                currentPage: 'Inventory',
                onCategorySelect: _onSidebarSelect,
              ),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 0,
              child: const SizedBox(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Gap(70),
                            AppTopBar(
                              isSidebarVisible: isSidebarVisible,
                              onToggle: () => setState(() => isSidebarVisible = !isSidebarVisible),
                              title: 'Inventory',
                              iconColor: AppColors.se,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or category...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ValueListenableBuilder<List<String>>(
                                valueListenable: categories,
                                builder: (context, categoryList, _) {
                                  return ValueListenableBuilder<int>(
                                    valueListenable: _selectedTabIndex,
                                    builder: (context, selectedIdx, _) {
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: List.generate(
                                            categoryList.length,
                                            (i) {
                                              final selected = selectedIdx == i;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    final safeI = i
                                                        .clamp(
                                                          0,
                                                          max(
                                                            0,
                                                            _tabController
                                                                    .length -
                                                                1,
                                                          ),
                                                        )
                                                        .toInt();
                                                    _tabController.index =
                                                        safeI;
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                          horizontal: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: selected
                                                          ? secondaryColor
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: selected
                                                            ? secondaryColor
                                                            : Colors
                                                                  .grey
                                                                  .shade300,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      categoryList[i],
                                                      style: TextStyle(
                                                        color: selected
                                                            ? Colors.white
                                                            : primaryColor,
                                                        fontWeight: selected
                                                            ? FontWeight.w600
                                                            : FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _selectedTabIndex,
                                builder: (context, selectedIndex, _) {
                                  return StreamBuilder<
                                    QuerySnapshot<Map<String, dynamic>>
                                  >(
                                    stream: _rawStream,
                                    builder: (context, snapshot) {
                                      final allDocs = snapshot.data?.docs ?? [];
                                      final firestoreDocs = {
                                        for (var d in allDocs)
                                          d.id: {...d.data(), 'id': d.id},
                                      };
                                      final merged = {
                                        ...firestoreDocs,
                                        ..._localDocs,
                                      };
                                      List<Map<String, dynamic>> filteredDocs =
                                          merged.values.toList();

                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            final uniqueCategories = {'All'};
                                            for (final doc in filteredDocs) {
                                              final category =
                                                  (doc['category'] ?? '')
                                                      .toString();
                                              if (category.isNotEmpty)
                                                uniqueCategories.add(category);
                                            }
                                            final tmp = uniqueCategories
                                                .toList();
                                            tmp.removeWhere(
                                              (e) => e.toLowerCase() == 'all',
                                            );
                                            tmp.sort();
                                            final newCategories = [
                                              'All',
                                              ...tmp,
                                            ];
                                            if (!listEquals(
                                              categories.value,
                                              newCategories,
                                            )) {
                                              categories.value = newCategories;
                                            }
                                          });

                                      if (selectedIndex > 0 &&
                                          selectedIndex <
                                              categories.value.length) {
                                        final normSelected = categories
                                            .value[selectedIndex]
                                            .toLowerCase()
                                            .replaceAll(
                                              RegExp(r"\s+|_|-|/|&"),
                                              ' ',
                                            )
                                            .trim();
                                        filteredDocs = filteredDocs.where((
                                          data,
                                        ) {
                                          final rawCat =
                                              (data['category'] ?? '')
                                                  .toString();
                                          final normRaw = rawCat
                                              .toLowerCase()
                                              .replaceAll(
                                                RegExp(r"\s+|_|-|/|&"),
                                                ' ',
                                              )
                                              .trim();
                                          return normRaw == normSelected;
                                        }).toList();
                                      }

                                      if (_searchQuery.isNotEmpty) {
                                        filteredDocs = filteredDocs.where((
                                          item,
                                        ) {
                                          final name = (item['name'] ?? '')
                                              .toString()
                                              .toLowerCase();
                                          final category =
                                              (item['category'] ?? '')
                                                  .toString()
                                                  .toLowerCase();
                                          return name.contains(_searchQuery) ||
                                              category.contains(_searchQuery);
                                        }).toList();
                                      }

                                      if (filteredDocs.isEmpty) {
                                        return const Center(
                                          child: Text('No items found.'),
                                        );
                                      }

                                      final dataRows = filteredDocs.map((item) {
                                        final id = item['id']?.toString();
                                        final displayed = {...item};
                                        final quantityInt = _parseQuantity(
                                          displayed['quantity'],
                                        );
                                        return DataRow(
                                          selected: _selectedItemId == id,
                                          cells: [
                                            DataCell(
                                              Text(displayed['category'] ?? ''),
                                            ),
                                            DataCell(
                                              Text(displayed['name'] ?? ''),
                                            ),
                                            DataCell(
                                              Text(
                                                displayed['quantity']
                                                        ?.toString() ??
                                                    '',
                                              ),
                                            ),
                                            DataCell(
                                              Text(displayed['unit'] ?? ''),
                                            ),
                                            DataCell(
                                              Text(displayed['supplier'] ?? ''),
                                            ),
                                            DataCell(
                                              Text(
                                                displayed['price'] != null
                                                    ? '\$${(displayed['price'] is num ? (displayed['price'] as num).toStringAsFixed(2) : double.tryParse(displayed['price'].toString())?.toStringAsFixed(2) ?? '0.00')}/${displayed['unit'] ?? 'unit'}'
                                                    : '\$0.00/${displayed['unit'] ?? 'unit'}',
                                              ),
                                            ),
                                            DataCell(
                                              CircleAvatar(
                                                radius: 8,
                                                backgroundColor:
                                                    quantityInt <= 5
                                                    ? Colors.red
                                                    : (quantityInt <= 10
                                                          ? Colors.yellow[700]!
                                                          : Colors.green),
                                              ),
                                            ),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.add_circle,
                                                  size: 18,
                                                  color: Color(0xff4a4a4a),
                                                ),
                                                tooltip: 'Add quantity',
                                                onPressed: () =>
                                                    _showAddQuantityDialog(
                                                      id,
                                                      displayed,
                                                    ),
                                              ),
                                            ),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 18,
                                                ),
                                                onPressed: () {
                                                  _selectedItemId = id;
                                                  _nameController.text =
                                                      displayed['name'] ?? '';
                                                  _categoryController.text =
                                                      displayed['category'] ??
                                                      '';
                                                  _quantityController.text =
                                                      displayed['quantity']
                                                          ?.toString() ??
                                                      '';
                                                  _unitController.text =
                                                      displayed['unit'] ?? '';
                                                  _supplierController.text =
                                                      displayed['supplier'] ??
                                                      '';
                                                  _priceController.text =
                                                      displayed['price'] is num
                                                      ? (displayed['price']
                                                                as num)
                                                            .toStringAsFixed(2)
                                                      : '0.00';
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ],
                                          onSelectChanged: (sel) {
                                            if (sel == true) {
                                              _selectedItemId = id;
                                              _nameController.text =
                                                  displayed['name'] ?? '';
                                              _categoryController.text =
                                                  displayed['category'] ?? '';
                                              _quantityController.text =
                                                  displayed['quantity']
                                                      ?.toString() ??
                                                  '';
                                              _unitController.text =
                                                  displayed['unit'] ?? '';
                                              _supplierController.text =
                                                  displayed['supplier'] ?? '';
                                              _priceController.text =
                                                  displayed['price'] is num
                                                  ? (displayed['price'] as num)
                                                        .toStringAsFixed(2)
                                                  : '0.00';
                                              setState(() {});
                                            }
                                          },
                                        );
                                      }).toList();

                                      return SingleChildScrollView(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: constraints.maxHeight,
                                            minWidth: constraints.maxWidth,
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              headingRowColor:
                                                  MaterialStateProperty.all(
                                                    Colors.grey[200],
                                                  ),
                                              border: TableBorder.all(
                                                color: Colors.grey.shade300,
                                              ),
                                              columns: const [
                                                DataColumn(
                                                  label: Text('Category'),
                                                ),
                                                DataColumn(label: Text('Name')),
                                                DataColumn(label: Text('Qty')),
                                                DataColumn(label: Text('Unit')),
                                                DataColumn(
                                                  label: Text('Supplier'),
                                                ),
                                                DataColumn(
                                                  label: Text('Price/Unit'),
                                                ),
                                                DataColumn(
                                                  label: Text('Status'),
                                                ),
                                                DataColumn(
                                                  label: Text('Add Qty'),
                                                ),
                                                DataColumn(label: Text('Edit')),
                                              ],
                                              rows: dataRows,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 420,
                    child: Column(
                      children: [
                        Gap(150),
                        // Edit panel is hidden until an item is selected (pen clicked)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _selectedItemId != null
                              ? editPanel()
                              : SizedBox(
                                  key: const ValueKey('empty_edit_panel'),
                                  height: 0,
                                ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _showAddPanel
                              ? addPanel()
                              : SizedBox(
                                  key: const ValueKey('empty_add_panel'),
                                  height: 0,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}