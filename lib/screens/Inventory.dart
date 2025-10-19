// screens/Inventory.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widget/side_bar.dart';
import '../component/colors.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _onSidebarSelect(String category) {
    final idx = tabs.indexWhere((t) => t.toLowerCase() == category.toLowerCase());
    if (idx != -1) {
      _tabController.animateTo(idx);
    } else {
      // If sidebar sends a category not in tabs, select 'All'
      _tabController.animateTo(0);
    }
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
          // Left sidebar (animated hide/show)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _sidebarVisible ? sidebarWidth : 0,
            child: _sidebarVisible
                ? SideBar(onCategorySelect: _onSidebarSelect)
                : const SizedBox.shrink(),
          ),

          // Main area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar (sidebar toggle placed like Dashboard)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          _sidebarVisible ? Icons.menu_open : Icons.menu,
                          color: AppColors.se,
                        ),
                        onPressed: () {
                          if (isMobile) {
                            _scaffoldKey.currentState?.openDrawer();
                          } else {
                            setState(() {
                              _sidebarVisible = !_sidebarVisible;
                            });
                          }
                        },
                      ),

                      Text(
                        'Inventory',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: AppColors.se,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  // Floating Tab bar
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.black54,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),

                  // Data table area
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('raw_components')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('❌ Error loading data'));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allDocs = snapshot.data?.docs ?? [];
                        List<Map<String, dynamic>> filteredDocs = [];

                        final selectedIndex = _tabController.index;
                        if (selectedIndex == 0 || selectedIndex >= tabs.length) {
                          filteredDocs = allDocs.map((doc) => doc.data()).toList();
                        } else {
                          // Normalize category strings for more forgiving matching
                          String selectedCategory = tabs[selectedIndex];
                          String normalize(String s) =>
                              s.toString().toLowerCase().replaceAll(RegExp(r"\s+|_|-|/|&"), ' ').trim();

                          final normSelected = normalize(selectedCategory);

                          filteredDocs = allDocs.map((doc) => doc.data()).where((data) {
                            final rawCat = data['category'] ?? '';
                            final normRaw = normalize(rawCat);
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

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text('No items found.', style: TextStyle(fontSize: 16)),
                          );
                        }

                        // Build table rows
                        final rows = filteredDocs.map((item) {
                          final name = (item['name'] ?? '').toString();
                          final category = (item['category'] ?? '').toString();
                          final quantity = (item['quantity'] ?? '').toString();
                          final unit = (item['unit'] ?? '').toString();
                          final supplier = (item['supplier'] ?? '').toString();
                          final price = (item['price'] ?? '').toString();
                          return DataRow(cells: [
                            DataCell(Text(category)),
                            DataCell(Text(name)),
                            DataCell(Text(quantity)),
                            DataCell(Text(unit)),
                            DataCell(Text(supplier)),
                            DataCell(Text(price)),
                          ]);
                        }).toList();

                        return SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
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
                              ],
                              rows: rows,
                            ),
                          ),
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