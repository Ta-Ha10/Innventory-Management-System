// screens/Inventory.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'dart:math' show max, min;

import '../widget/side_bar.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ValueNotifier<int> _selectedTabIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dynamic categories list (always includes 'All')
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

  // Add-item controllers (separate from edit controllers)
  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addCategoryController = TextEditingController();
  final TextEditingController _addQuantityController = TextEditingController();
  final TextEditingController _addUnitController = TextEditingController();
  final TextEditingController _addSupplierController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();

  final Map<String, Map<String, dynamic>> _localDocs = {};

  final Stream<QuerySnapshot<Map<String, dynamic>>> _rawStream =
      FirebaseFirestore.instance.collection('raw_components').snapshots();

  final Color primaryColor = const Color(0xff4a4a4a);
  final Color secondaryColor = const Color(0xff6fad99);

  // For slide animation direction
  int _previousTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // initialize TabController to match categories length
    _tabController = TabController(
      length: max(1, categories.value.length),
      vsync: this,
    );
    _selectedTabIndex = ValueNotifier<int>(0);

    // keep selected index stable when controller changes
    _tabController.addListener(() {
      final prev = _selectedTabIndex.value;
      if (_tabController.index != prev) {
        _previousTabIndex = prev;
        _selectedTabIndex.value = _tabController.index;
      }
    });

    // listen to unit fields for suffix updates
    _unitController.addListener(() => setState(() {}));
    _addUnitController.addListener(() => setState(() {}));
    categories.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    _unitController.removeListener(() => setState(() {}));
    _addUnitController.removeListener(() => setState(() {}));
    categories.removeListener(_onCategoriesChanged);
    try {
      _tabController.dispose();
    } catch (_) {}
    // dispose all controllers
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
    // Ensure TabController length matches categories length and keep selected index valid
    final newLen = max(1, categories.value.length);
    final oldController = _tabController;

    final currentIndex = _selectedTabIndex.value;
    final safeIndex = (currentIndex >= 0) ? min(currentIndex, newLen - 1) : 0;

    try {
      oldController.dispose();
    } catch (_) {}

    _tabController =
        TabController(length: newLen, vsync: this, initialIndex: safeIndex);
    _tabController.addListener(() {
      final prev = _selectedTabIndex.value;
      if (_tabController.index != prev) {
        _previousTabIndex = prev;
        _selectedTabIndex.value = _tabController.index;
      }
    });

    _selectedTabIndex.value = _tabController.index;
    setState(() {});
  }

  void _onSidebarSelect(String category) {
    // Find tab index matching category (normalize comparison)
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
      final safeIdx =
          idx.clamp(0, max(0, _tabController.length - 1)).toInt();
      // set previous to compute direction
      _previousTabIndex = _selectedTabIndex.value;
      // jump immediately (no animation)
      _tabController.index = safeIdx;
      // _selectedTabIndex will be updated by the TabController listener
    } else {
      // Merge the new category into the existing categories list without dropping others.
      final existing = [...categories.value];
      // Ensure 'All' is treated specially and stays at index 0
      existing.removeWhere((e) => e.toLowerCase() == 'all');
      // Add the new category if it's not already present (case-insensitive)
      final lowerSet = existing.map((e) => e.toLowerCase()).toSet();
      if (!lowerSet.contains(category.toLowerCase())) existing.add(category);
      existing.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final newList = ['All', ...existing];

      categories.value = newList;
      final newIndex = newList.indexWhere((t) => t.toLowerCase() == category.toLowerCase());

      // Safely dispose and recreate tab controller with the new length and select the new index.
      final oldController = _tabController;
      try {
        oldController.dispose();
      } catch (_) {}

      final safeInitial = (newIndex >= 0) ? min(newIndex, newList.length - 1) : 0;
      _tabController = TabController(
        length: newList.length,
        vsync: this,
        initialIndex: safeInitial,
      );
      _tabController.addListener(() {
        final prev = _selectedTabIndex.value;
        if (_tabController.index != prev) {
          _previousTabIndex = prev;
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
    if (raw is double) return raw.round(); // Round to nearest integer
    final s = raw.toString();
    // Try parsing as double first, then round to integer
    final doubleVal = double.tryParse(s);
    if (doubleVal != null) return doubleVal.round();
    // Try parsing as integer if double parsing failed
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

    try {
      final id = _selectedItemId!;
      // Clean and parse price
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);
      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number for price')),
        );
        return;
      }
      final unit = _unitController.text.trim();

      // Parse and validate quantity
      final quantityText = _quantityController.text.trim();
      int? quantity;
      if (quantityText.isNotEmpty) {
        // Try parsing as double first
        final doubleVal = double.tryParse(quantityText);
        if (doubleVal != null) {
          quantity = doubleVal.round();
        } else {
          // If not a valid number, show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid number for quantity')),
          );
          return;
        }
      }

      final data = {
        'name': _nameController.text.trim(),
        'category': _categoryController.text.trim(),
        'quantity': quantity ?? _parseQuantity(_localDocs[id]?['quantity'] ?? 0), // Keep existing quantity if not changed
        'unit': unit,
        'supplier': _supplierController.text.trim(),
        'price': price, // Store as double
        'pricePerUnit': '$price/$unit', // Store formatted string
      };

      // optimistic local update
      _localDocs[id] = {...data, 'id': id};
      setState(() {});

      await FirebaseFirestore.instance
          .collection('raw_components')
          .doc(id)
          .update(data);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item saved')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _saveNewItem() async {
    // Validate required fields (all required)
    if (_addNameController.text.trim().isEmpty ||
        _addCategoryController.text.trim().isEmpty ||
        _addQuantityController.text.trim().isEmpty ||
        _addUnitController.text.trim().isEmpty ||
        _addSupplierController.text.trim().isEmpty ||
        _addPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Clean and parse price
    final priceText = _addPriceController.text.trim();
    final price = double.tryParse(priceText);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number for price')),
      );
      return;
    }
    final unit = _addUnitController.text.trim();

    // Parse and validate quantity
    final quantityText = _addQuantityController.text.trim();
    int quantity = 0; // Default to 0 for new items
    if (quantityText.isNotEmpty) {
      // Try parsing as double first
      final doubleVal = double.tryParse(quantityText);
      if (doubleVal != null) {
        quantity = doubleVal.round();
      } else {
        // If not a valid number, show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid number for quantity')),
        );
        return;
      }
    }

    final data = {
      'name': _addNameController.text.trim(),
      'category': _addCategoryController.text.trim(),
      'quantity': quantity,
      'unit': unit,
      'supplier': _addSupplierController.text.trim(),
      'price': price, // Store as double
      'pricePerUnit': '$price/$unit', // Store formatted string
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added')));
      _clearAddForm();
    } catch (e) {
      // remove temp local doc on failure
      _localDocs.remove(tempId);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }

  void _clearAddForm() {
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
  }

  Widget editPanel() {
    return SizedBox(
      width: 420,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // pure white
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
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
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoryController.text.isEmpty
                  ? null
                  : _categoryController.text,
              items: categories.value
                  .where((t) => t.toLowerCase() != 'all')
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => _categoryController.text = v ?? '',
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: 'Enter amount (e.g., 5 or 5.5)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(labelText: 'Supplier'),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _unitController,
              builder: (context, unit, _) {
                return TextField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText:
                        'Price/${unit.text.isNotEmpty ? unit.text : "unit"}',
                    hintText: 'Enter price (e.g., 12.50)',
                    suffixText: _unitController.text.isNotEmpty
                        ? '/${_unitController.text}'
                        : '/unit',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget addPanel() {
    InputDecoration reqDeco(String label) => InputDecoration(
          labelText: '$label *',
          border: const OutlineInputBorder(),
        );

    return SizedBox(
      width: 420,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, // pure white
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
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
              decoration: reqDeco('Name'),
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
              decoration: reqDeco('Category'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addQuantityController,
                    decoration: reqDeco('Quantity'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _addUnitController,
                    decoration: reqDeco('Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addSupplierController,
              decoration: reqDeco('Supplier'),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder(
              valueListenable: _addUnitController,
              builder: (context, unit, _) {
                return TextField(
                  controller: _addPriceController,
                  decoration: InputDecoration(
                    labelText:
                        'Price/${unit.text.isNotEmpty ? unit.text : "unit"} *',
                    hintText: 'Enter price (e.g., 12.50)',
                    suffixText: _addUnitController.text.isNotEmpty
                        ? '/${_addUnitController.text}'
                        : '/unit',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
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

  @override
  Widget build(BuildContext context) {
    // Sidebar is kept visible/fixed per your request
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth < 1000 && screenWidth >= 700;
    final double sidebarWidth = isMobile ? 0 : (isTablet ? 180 : 220);

    return Scaffold(
      key: _scaffoldKey,
      // Drawer kept for mobile devices, but sidebar will be visible on larger screens

      backgroundColor: const Color(0xFFF9F9F9),
      body: Row(
        children: [
          // Sidebar - fixed visible on wide screens
          SizedBox(
            width: sidebarWidth,
            child: SideBar(
              currentPage: 'Inventory',
              onCategorySelect: _onSidebarSelect,
            ),
          ),

          // Main area: left = search + nav + table (scroll together), right = fixed panels
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: group (Search + Category pills + Table) — this column scrolls together
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Column layout: search + pills fixed, table expands to fill available height
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row title only on wide screens (mobile will rely on app bar/drawer)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Inventory',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Search
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

                            // Categories list (horizontal pills)
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
                                          children: List.generate(categoryList.length, (i) {
                                            final selected = selectedIdx == i;
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: InkWell(
                                                onTap: () {
                                                  final safeI = i.clamp(0, max(0, _tabController.length - 1)).toInt();
                                                  _previousTabIndex = _selectedTabIndex.value;
                                                  _tabController.index = safeI;
                                                },
                                                borderRadius: BorderRadius.circular(20),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: selected ? secondaryColor : Colors.white,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: selected ? secondaryColor : Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    categoryList[i],
                                                    style: TextStyle(
                                                      color: selected ? Colors.white : primaryColor,
                                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            // Table: Expanded to take remaining height
                            Expanded(
                              child: ValueListenableBuilder<int>(
                                valueListenable: _selectedTabIndex,
                                builder: (context, selectedIndex, _) {
                                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _rawStream,
                                    builder: (context, snapshot) {
                                      final allDocs = snapshot.data?.docs ?? [];
                                      final firestoreDocs = {for (var d in allDocs) d.id: {...d.data(), 'id': d.id}};
                                      final merged = {...firestoreDocs, ..._localDocs};
                                      List<Map<String, dynamic>> filteredDocs = merged.values.toList();

                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        final uniqueCategories = {'All'};
                                        for (final doc in filteredDocs) {
                                          final category = (doc['category'] ?? '').toString();
                                          if (category.isNotEmpty) uniqueCategories.add(category);
                                        }
                                        final tmp = uniqueCategories.toList();
                                        tmp.removeWhere((e) => e.toLowerCase() == 'all');
                                        tmp.sort();
                                        final newCategories = ['All', ...tmp];
                                        if (!listEquals(categories.value, newCategories)) {
                                          categories.value = newCategories;
                                        }
                                      });

                                      if (selectedIndex > 0 && selectedIndex < categories.value.length) {
                                        final normSelected = categories.value[selectedIndex].toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim();
                                        filteredDocs = filteredDocs.where((data) {
                                          final rawCat = (data['category'] ?? '').toString();
                                          final normRaw = rawCat.toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim();
                                          return normRaw == normSelected;
                                        }).toList();
                                      }

                                      // (no-op) placeholder removed; ensure we reference _searchQuery below

                                      if (_searchQuery.isNotEmpty) {
                                        filteredDocs = filteredDocs.where((item) {
                                          final name = (item['name'] ?? '').toString().toLowerCase();
                                          final category = (item['category'] ?? '').toString().toLowerCase();
                                          return name.contains(_searchQuery) || category.contains(_searchQuery);
                                        }).toList();
                                      }

                                      if (filteredDocs.isEmpty) {
                                        return const Center(child: Text('No items found.'));
                                      }

                                      final dataRows = filteredDocs.map((item) {
                                        final id = item['id']?.toString();
                                        final displayed = {...item};
                                        final quantityInt = _parseQuantity(displayed['quantity']);
                                        return DataRow(
                                          selected: _selectedItemId == id,
                                          cells: [
                                            DataCell(Text(displayed['category'] ?? '')),
                                            DataCell(Text(displayed['name'] ?? '')),
                                            DataCell(Text(displayed['quantity']?.toString() ?? '')),
                                            DataCell(Text(displayed['unit'] ?? '')),
                                            DataCell(Text(displayed['supplier'] ?? '')),
                                            DataCell(Text(displayed['price'] != null ? '\$${(displayed['price'] is num ? (displayed['price'] as num).toStringAsFixed(2) : double.tryParse(displayed['price'].toString())?.toStringAsFixed(2) ?? '0.00')}/${displayed['unit'] ?? 'unit'}' : '\$0.00/${displayed['unit'] ?? 'unit'}')),
                                            DataCell(CircleAvatar(radius: 8, backgroundColor: quantityInt <= 5 ? Colors.red : (quantityInt <= 10 ? Colors.yellow[700] : Colors.green))),
                                          ],
                                          onSelectChanged: (sel) {
                                            if (sel == true) {
                                              _selectedItemId = id;
                                              _nameController.text = displayed['name'] ?? '';
                                              _categoryController.text = displayed['category'] ?? '';
                                              _quantityController.text = displayed['quantity']?.toString() ?? '';
                                              _unitController.text = displayed['unit'] ?? '';
                                              _supplierController.text = displayed['supplier'] ?? '';
                                              _priceController.text = displayed['price'] is num ? (displayed['price'] as num).toStringAsFixed(2) : '0.00';
                                              setState(() {});
                                            }
                                          },
                                        );
                                      }).toList();

                                      // Vertical scroll containing horizontal scroll for wide tables
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(minWidth: 700),
                                            child: DataTable(
                                              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                                              border: TableBorder.all(color: Colors.grey.shade300),
                                              columns: const [
                                                DataColumn(label: Text('Category')),
                                                DataColumn(label: Text('Name')),
                                                DataColumn(label: Text('Qty')),
                                                DataColumn(label: Text('Unit')),
                                                DataColumn(label: Text('Supplier')),
                                                DataColumn(label: Text('Price/Unit')),
                                                DataColumn(label: Text('Status')),
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

                  // RIGHT: fixed column with Edit and Add panels (do NOT scroll with left)
                  SizedBox(
                    width: 420,
                    child: Column(
                      children: [
                        // Keep panels fixed: we still allow their inner content to scroll if needed
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(), // make outer right column fixed relative to left scroll
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Gap(150),
                                editPanel(),
                                const SizedBox(height: 12),
                                addPanel(),
                              ],
                            ),
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
