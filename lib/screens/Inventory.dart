// screens/Inventory.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show max, min;

import '../widget/side_bar.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ValueNotifier<int> _selectedTabIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarVisible = true;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: max(1, categories.value.length),
      vsync: this,
    );
    _selectedTabIndex = ValueNotifier<int>(0);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTabIndex.value) {
        _selectedTabIndex.value = _tabController.index;
      }
    });

    // Make text controllers listenable for price/unit updates
    _unitController.addListener(() => setState(() {}));
    _addUnitController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _unitController.removeListener(() => setState(() {}));
    _addUnitController.removeListener(() => setState(() {}));
    super.dispose();
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
      _tabController.animateTo(idx);
      _selectedTabIndex.value = idx;
    } else {
      // add new category and select it
      final newList = [...categories.value, category]..sort();
      categories.value = newList;
      final newIndex = newList.indexOf(category);

      // Safely dispose and recreate tab controller
      final oldController = _tabController;
      _tabController = TabController(
        length: newList.length,
        vsync: this,
        initialIndex: min(newIndex, newList.length - 1),
      );
      oldController.dispose();

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

      child: Card(
        color: const Color.fromARGB(255, 241, 239, 239),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
      ),
    );
  }

  Widget addPanel() {
    return SizedBox(
      width: 420,
      child: Card(
        color: const Color.fromARGB(255, 241, 239, 239),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _addCategoryController.text.isEmpty
                    ? null
                    : _addCategoryController.text,
                items: categories.value
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => _addCategoryController.text = v ?? '',
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addQuantityController,
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
                      controller: _addUnitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addSupplierController,
                decoration: const InputDecoration(labelText: 'Supplier'),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: _addUnitController,
                builder: (context, unit, _) {
                  return TextField(
                    controller: _addPriceController,
                    decoration: InputDecoration(
                      labelText:
                          'Price/${unit.text.isNotEmpty ? unit.text : "unit"}',
                      hintText: 'Enter price (e.g., 12.50)',
                      suffixText: _addUnitController.text.isNotEmpty
                          ? '/${_addUnitController.text}'
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
                    onPressed: _saveNewItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;
    final bool isTablet = screenWidth < 1000 && screenWidth >= 700;
    final double sidebarWidth = isMobile ? 0 : (isTablet ? 180 : 220);

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Drawer(
              child: SideBar(
                currentPage: 'Inventory',
                onCategorySelect: _onSidebarSelect,
              ),
            )
          : null,
      backgroundColor: const Color(0xFFF9F9F9),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarVisible ? sidebarWidth : 0,
            child: _sidebarVisible
                ? SideBar(
                    currentPage: 'Inventory',
                    onCategorySelect: _onSidebarSelect,
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _sidebarVisible ? Icons.menu_open : Icons.menu,
                          color: primaryColor,
                        ),
                        onPressed: () {
                          if (isMobile)
                            _scaffoldKey.currentState?.openDrawer();
                          else
                            setState(() => _sidebarVisible = !_sidebarVisible);
                        },
                      ),
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
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(categoryList.length, (i) {
                              final selected = _tabController.index == i;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    _tabController.animateTo(i);
                                    _selectedTabIndex.value = i;
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? secondaryColor
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? secondaryColor
                                            : Colors.grey.shade300,
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
                            }),
                          ),
                        );
                      },
                    ),
                  ),

                  // Table + edit panel
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
                            final merged = {...firestoreDocs, ..._localDocs};
                            List<Map<String, dynamic>> filteredDocs = merged
                                .values
                                .toList();

                            // Update categories without triggering a build
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final uniqueCategories = {'All'};
                              for (final doc in filteredDocs) {
                                final category = (doc['category'] ?? '')
                                    .toString();
                                if (category.isNotEmpty)
                                  uniqueCategories.add(category);
                              }
                              final newCategories = uniqueCategories.toList()
                                ..sort();
                              if (!listEquals(
                                categories.value,
                                newCategories,
                              )) {
                                categories.value = newCategories;
                              }
                            });
                            if (selectedIndex > 0 &&
                                selectedIndex < categories.value.length) {
                              final normSelected = categories
                                  .value[selectedIndex]
                                  .toLowerCase()
                                  .replaceAll(RegExp(r"\s+|_|-|/|&"), ' ')
                                  .trim();
                              filteredDocs = filteredDocs.where((data) {
                                final rawCat = (data['category'] ?? '')
                                    .toString();
                                final normRaw = rawCat
                                    .toLowerCase()
                                    .replaceAll(RegExp(r"\s+|_|-|/|&"), ' ')
                                    .trim();
                                return normRaw == normSelected;
                              }).toList();
                            }

                            if (_searchQuery.isNotEmpty) {
                              filteredDocs = filteredDocs.where((item) {
                                final name = (item['name'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final category = (item['category'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                return name.contains(_searchQuery) ||
                                    category.contains(_searchQuery);
                              }).toList();
                            }

                            if (filteredDocs.isEmpty)
                              return const Center(
                                child: Text('No items found.'),
                              );

                            final dataRows = filteredDocs.map((item) {
                              final id = item['id']?.toString();
                              final displayed = {...item};
                              final quantityInt = _parseQuantity(
                                displayed['quantity'],
                              );
                              return DataRow(
                                selected: _selectedItemId == id,
                                cells: [
                                  DataCell(Text(displayed['category'] ?? '')),
                                  DataCell(Text(displayed['name'] ?? '')),
                                  DataCell(
                                    Text(
                                      displayed['quantity']?.toString() ?? '',
                                    ),
                                  ),
                                  DataCell(Text(displayed['unit'] ?? '')),
                                  DataCell(Text(displayed['supplier'] ?? '')),
                                  DataCell(
                                    Text(
                                      displayed['price'] != null 
                                        ? '\$${(displayed['price'] is num 
                                            ? (displayed['price'] as num).toStringAsFixed(2) 
                                            : double.tryParse(displayed['price'].toString())?.toStringAsFixed(2) ?? '0.00')}/${displayed['unit'] ?? 'unit'}'
                                        : '\$0.00/${displayed['unit'] ?? 'unit'}',
                                    ),
                                  ),
                                  DataCell(
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: quantityInt <= 5
                                          ? Colors.red
                                          : (quantityInt <= 10
                                                ? Colors.yellow[700]
                                                : Colors.green),
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
                                        displayed['quantity']?.toString() ?? '';
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

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final tableHeight = constraints.maxHeight;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: SizedBox(
                                        height: tableHeight,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minWidth: 700,
                                              ),
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
                                                  DataColumn(
                                                    label: Text('Name'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Qty'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Unit'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Supplier'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Price/Unit'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Status'),
                                                  ),
                                                ],
                                                rows: dataRows,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Scrollable right column fixed width containing Edit and Add panels
                                    SizedBox(
                                      width: 420,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            editPanel(),
                                            const SizedBox(height: 12),
                                            addPanel(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
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
