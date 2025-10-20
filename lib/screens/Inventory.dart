// screens/Inventory.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final List<String> tabs = [
    'All',
    'Meat / Poultry / Seafood',
    'Vegetables & Fruits',
    'Dairy',
    'Gluten-Containing',
    'Egg-Based',
    'Fats / Oils',
    'Spices / Seasonings',
    'Beverages',
  ];

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
    _tabController = TabController(length: tabs.length, vsync: this);
    _selectedTabIndex = ValueNotifier<int>(_tabController.index);
    _tabController.addListener(() {
      _selectedTabIndex.value = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _onSearchChanged(String query) {
  _searchQuery = query.toLowerCase();
  _selectedTabIndex.value = _selectedTabIndex.value;
  }

  void _onSidebarSelect(String category) {
    final idx = tabs.indexWhere(
        (t) => t.toLowerCase() == category.toLowerCase());
    if (idx != -1) _tabController.animateTo(idx);
    else _tabController.animateTo(0);
  }

  int _parseQuantity(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    final i = int.tryParse(raw.toString());
    if (i != null) return i;
    final d = double.tryParse(raw.toString());
    if (d != null) return d.toInt();
    return 0;
  }

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final unit = _unitController.text.trim();
    final supplier = _supplierController.text.trim();
    final priceRaw = _priceController.text.trim();
    final price = double.tryParse(priceRaw) ?? priceRaw;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final collection = FirebaseFirestore.instance.collection('raw_components');
    try {
      if (_selectedItemId != null) {
        final id = _selectedItemId!;
        _localDocs[id] = {
          ...?_localDocs[id],
          'id': id,
          'name': name,
          'category': category,
          'quantity': quantity,
          'unit': unit,
          'supplier': supplier,
          'price': price,
        };
  _selectedTabIndex.value = _selectedTabIndex.value;

        await collection.doc(id).update({
          'name': name,
          'category': category,
          'quantity': quantity,
          'unit': unit,
          'supplier': supplier,
          'price': price,
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item updated')));
      } else {
        final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        _localDocs[tempId] = {
          'id': tempId,
          'name': name,
          'category': category,
          'quantity': quantity,
          'unit': unit,
          'supplier': supplier,
          'price': price,
        };
  _selectedItemId = tempId;
  _selectedTabIndex.value = _selectedTabIndex.value;

        final docRef = await collection.add({
          'name': name,
          'category': category,
          'quantity': quantity,
          'unit': unit,
          'supplier': supplier,
          'price': price,
        });

        if (mounted) {
          final realId = docRef.id;
          final data = {...?_localDocs[tempId], 'id': realId};
          _localDocs.remove(tempId);
          _localDocs[realId] = data;
          _selectedItemId = realId;
          _selectedTabIndex.value = _selectedTabIndex.value;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Item added')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  Future<void> _saveNewItem() async {
    final name = _addNameController.text.trim();
    final category = _addCategoryController.text.trim();
    final quantity = int.tryParse(_addQuantityController.text.trim()) ?? 0;
    final unit = _addUnitController.text.trim();
    final supplier = _addSupplierController.text.trim();
    final priceRaw = _addPriceController.text.trim();
    final price = double.tryParse(priceRaw) ?? priceRaw;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final collection = FirebaseFirestore.instance.collection('raw_components');
    try {
      final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      _localDocs[tempId] = {
        'id': tempId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'supplier': supplier,
        'price': price,
      };
      setState(() {});

      final docRef = await collection.add({
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'supplier': supplier,
        'price': price,
      });

      if (mounted) {
        final realId = docRef.id;
        final data = {...?_localDocs[tempId], 'id': realId};
        _localDocs.remove(tempId);
        _localDocs[realId] = data;
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item added')));
      _clearAddForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Add failed: $e')));
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
              const Text('Edit Item',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categoryController.text.isEmpty ? null : _categoryController.text,
                items: tabs.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => _categoryController.text = v ?? '',
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _unitController, decoration: const InputDecoration(labelText: 'Unit'))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _supplierController, decoration: const InputDecoration(labelText: 'Supplier')),
              const SizedBox(height: 8),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  onPressed: _saveItem,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearSelection,
                  child: const Text('Clear'),
                  style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                ),
              ]),
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
              const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: _addNameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _addCategoryController.text.isEmpty ? null : _addCategoryController.text,
                items: tabs.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => _addCategoryController.text = v ?? '',
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: _addQuantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _addUnitController, decoration: const InputDecoration(labelText: 'Unit'))),
              ]),
              const SizedBox(height: 8),
              TextField(controller: _addSupplierController, decoration: const InputDecoration(labelText: 'Supplier')),
              const SizedBox(height: 8),
              TextField(controller: _addPriceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(onPressed: _saveNewItem, icon: const Icon(Icons.add), label: const Text('Add')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _clearAddForm, child: const Text('Clear')),
              ]),
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
      drawer: isMobile ? Drawer(child: SideBar(onCategorySelect: _onSidebarSelect)) : null,
      backgroundColor: const Color(0xFFF9F9F9),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarVisible ? sidebarWidth : 0,
            child: _sidebarVisible ? SideBar(onCategorySelect: _onSidebarSelect) : const SizedBox.shrink(),
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
                        icon: Icon(_sidebarVisible ? Icons.menu_open : Icons.menu, color: primaryColor),
                        onPressed: () {
                          if (isMobile) _scaffoldKey.currentState?.openDrawer();
                          else setState(() => _sidebarVisible = !_sidebarVisible);
                        },
                      ),
                      Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: primaryColor)),
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Tabs
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                          child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(tabs.length, (i) {
                          final selected = _tabController.index == i;
                          return InkWell(
                            onTap: () {
                              _tabController.animateTo(i);
                              _selectedTabIndex.value = i;
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                              decoration: BoxDecoration(
                                color: selected ? secondaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: selected ? secondaryColor : Colors.grey.shade300),
                              ),
                              child: Text(tabs[i], style: TextStyle(color: selected ? Colors.white : primaryColor, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                            ),
                          );
                        }),
                      ),
                    ),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  // Table + edit panel
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

                            if (selectedIndex > 0 && selectedIndex < tabs.length) {
                              final normSelected = tabs[selectedIndex].toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim();
                              filteredDocs = filteredDocs.where((data) {
                                final rawCat = (data['category'] ?? '').toString();
                                final normRaw = rawCat.toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim();
                                return normRaw == normSelected;
                              }).toList();
                            }

                            if (_searchQuery.isNotEmpty) {
                              filteredDocs = filteredDocs.where((item) {
                                final name = (item['name'] ?? '').toString().toLowerCase();
                                final category = (item['category'] ?? '').toString().toLowerCase();
                                return name.contains(_searchQuery) || category.contains(_searchQuery);
                              }).toList();
                            }

                            if (filteredDocs.isEmpty) return const Center(child: Text('No items found.'));

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
                                  DataCell(Text(displayed['price']?.toString() ?? '')),
                                  DataCell(
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: quantityInt <= 5 ? Colors.red : (quantityInt <= 10 ? Colors.yellow[700] : Colors.green),
                                    ),
                                  ),
                                ],
                                onSelectChanged: (sel) {
                                  if (sel == true) {
                                    _selectedItemId = id;
                                    _nameController.text = displayed['name'] ?? '';
                                    _categoryController.text = displayed['category'] ?? '';
                                    _quantityController.text = displayed['quantity']?.toString() ?? '';
                                    _unitController.text = displayed['unit'] ?? '';
                                    _supplierController.text = displayed['supplier'] ?? '';
                                    _priceController.text = displayed['price']?.toString() ?? '';
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
                                                  DataColumn(label: Text('Price')),
                                                  DataColumn(label: Text('Status')),
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
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
