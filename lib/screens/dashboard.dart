import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

import '../component/colors.dart';
import '../widget/side_bar.dart';
import '../widget/top_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isSidebarVisible = true;
  final int lowStockThreshold = 5;
  // controller for low-stock list scroll
  final ScrollController _lowStockScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Sidebar =====
          if (isSidebarVisible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              child: SideBar(currentPage: 'Dashboard'),
            ),

          // ===== Main Content Area =====
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(70),

                    // ===== Top Bar =====
                    AppTopBar(
                      isSidebarVisible: isSidebarVisible,
                      onToggle: () => setState(() => isSidebarVisible = !isSidebarVisible),
                      title: 'Dashboard',
                      iconColor: AppColors.se,
                    ),
                    const SizedBox(height: 20),

                    // ===== Panels (driven from Firestore) =====
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('raw_components').snapshots(),
                      builder: (context, snap) {
                        final docs = snap.hasData ? snap.data!.docs : <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                        // compute list of items with quantity and price
                        final items = docs.map((d) {
                          final data = d.data();
                          double price = 0.0;
                          final p = data['price'];
                          if (p is num) price = p.toDouble();
                          else if (p is String) price = double.tryParse(p) ?? 0.0;

                          double quantity = 0.0;
                          final q = data['quantity'];
                          if (q is num) quantity = q.toDouble();
                          else if (q is String) quantity = double.tryParse(q) ?? 0.0;

                          return {
                            'id': d.id,
                            'name': data['name'] ?? '',
                            'quantity': quantity,
                            'price': price,
                            'unit': data['unit'] ?? '',
                          };
                        }).toList();

                        // Show items with quantity between 0 and lowStockThreshold (inclusive)
                        final lowStock = items.where((it) {
                          final q = (it['quantity'] as double);
                          return q >= 0.0 && q <= lowStockThreshold;
                        }).toList();
                        // Sort ascending by quantity, then by name to make display deterministic
                        lowStock.sort((a, b) {
                          final qa = (a['quantity'] as double);
                          final qb = (b['quantity'] as double);
                          final cmp = qa.compareTo(qb);
                          if (cmp != 0) return cmp;
                          return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
                        });

                        final totalStockValue = items.fold<double>(0.0, (acc, it) => acc + ((it['quantity'] as double) * (it['price'] as double)));

                        final topItems = [...items]..sort((a, b) => (b['quantity'] as double).compareTo(a['quantity'] as double));

                        // compute a graph height: at least 220, otherwise 40% of viewport
                        final graphHeight = math.max(220.0, MediaQuery.of(context).size.height * 0.40);

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isSmallScreen = constraints.maxWidth < 800;

                            if (isSmallScreen) {
                              return Column(
                                children: [
                                  _buildLeftPanel(lowStock),
                                  const SizedBox(height: 20),
                                  _buildRightPanels(totalStockValue, topItems),
                                  const SizedBox(height: 20),
                                  _buildGraph(topItems, graphHeight),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: _buildLeftPanel(lowStock)),
                                    const SizedBox(width: 20),
                                    Expanded(flex: 1, child: _buildRightPanels(totalStockValue, topItems)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildGraph(topItems, graphHeight),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lowStockScrollController.dispose();
    super.dispose();
  }

  // ===== Left Panel =====
  Widget _buildLeftPanel(List<Map<String, dynamic>> lowStock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.grey, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Low Stock Items (0-5)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          if (lowStock.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: const Text('All items are sufficiently stocked'),
            )
          else
            // Make the low-stock list scrollable so more items can be shown
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: Scrollbar(
                controller: _lowStockScrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _lowStockScrollController,
                  shrinkWrap: true,
                  itemCount: lowStock.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final it = lowStock[idx];
                    final name = it['name'] ?? '';
                    final qty = (it['quantity'] as double).toStringAsFixed(0);
                    final unit = it['unit'] ?? '';
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text(name), Text('$qty $unit')],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== Right Panels =====
  Widget _buildRightPanels(double totalStockValue, List<Map<String, dynamic>> topItems) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Stock Value :",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('EGP ${totalStockValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Kitchen Request :",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text("Chicken"),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Simple bar graph for top items =====
  Widget _buildGraph(List<Map<String, dynamic>> items, double height) {
    // show more items (up to 36) in a horizontally scrollable narrow-bar graph
    final display = items.take(36).toList();
    // If many bars, emphasize the lowest ones first (ascending), otherwise show descending
    if (display.length >= 6) {
      display.sort((a, b) => (a['quantity'] as double).compareTo(b['quantity'] as double));
    } else {
      display.sort((a, b) => (b['quantity'] as double).compareTo(a['quantity'] as double));
    }
    if (display.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: const Text('No stock data'),
      );
    }

    final maxQty = display.map((e) => e['quantity'] as double).fold<double>(0.0, (a, b) => math.max(a, b));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stock levels', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = math.max(display.length * 72.0, constraints.maxWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minWidth),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: display.map((it) {
                        final name = (it['name'] ?? '').toString();
                        final qty = (it['quantity'] as double);
                        final barHeight = maxQty > 0 ? (qty / maxQty) * (height - 60.0) : 6.0;
                        return SizedBox(
                          width: 64,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: barHeight,
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(color: Colors.green[300], borderRadius: BorderRadius.circular(6)),
                              ),
                              const SizedBox(height: 6),
                              // Fixed-height name area so the quantity label below is aligned for every bar
                              SizedBox(
                                height: 34, // accommodates up to 2 lines comfortably
                                child: Center(
                                  child: Text(name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(qty.toStringAsFixed(0), style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
