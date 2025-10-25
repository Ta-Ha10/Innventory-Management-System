import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rrms/component/colors.dart';

/// InventoryHistoryPage
/// Shows inventory_history entries inside a container. If [itemId] is provided
/// it filters to that item, otherwise shows recent history for all items.
class InventoryHistoryPage extends StatelessWidget {
  final String? itemId;

  const InventoryHistoryPage({Key? key, this.itemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot<Map<String, dynamic>>> stream = itemId != null
        ? FirebaseFirestore.instance
            .collection('inventory_history')
            .where('itemId', isEqualTo: itemId)
            .orderBy('timestamp', descending: true)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('inventory_history')
            .orderBy('timestamp', descending: true)
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text(itemId != null ? 'History for item' : 'Inventory History'),
        backgroundColor: AppColors.se,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.hasError) {
                final errStr = snap.error?.toString() ?? 'Unknown error';
                final needsIndex = errStr.toLowerCase().contains('requires an index') || errStr.toLowerCase().contains('create_composite');
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Error loading history', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (needsIndex) ...[
                        const Text('Firestore reports this query requires a composite index. Create an index for the collection "inventory_history" with the following fields:'),
                        const SizedBox(height: 6),
                        const Text('- Field: itemId   Direction: Ascending'),
                        const Text('- Field: timestamp Direction: Descending'),
                        const SizedBox(height: 8),
                        const Text('You can create this index in the Firebase Console → Firestore Database → Indexes → Create composite index, or follow the link contained in the original error message below.'),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 6),
                      const Text('Error details (select/copy):', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SelectableText(errStr),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: errStr));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error details copied to clipboard')));
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy error'),
                          ),
                          const SizedBox(width: 8),
                          if (needsIndex)
                            OutlinedButton(
                              onPressed: () {
                                // Helpful short instructions in a dialog for convenience
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Create composite index'),
                                    content: const Text('Open Firebase Console → Firestore → Indexes and create a composite index for collection "inventory_history" with fields: itemId (Ascending), timestamp (Descending). After the index builds the query will succeed.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('How to create'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('No history entries'));

              // Partition entries into all history (recent) and changed items (price or supplier changed)
              final allEntries = docs.map((d) => d.data()).toList();
              final changedEntries = allEntries.where((d) {
                final oldSup = (d['oldSupplier'] ?? '').toString();
                final newSup = (d['newSupplier'] ?? '').toString();
                final oldP = d['oldPrice']?.toString() ?? '';
                final newP = d['newPrice']?.toString() ?? '';
                final priceChanged = oldP.isNotEmpty && newP.isNotEmpty && oldP != newP;
                final supplierChanged = oldSup.isNotEmpty && newSup.isNotEmpty && oldSup != newSup;
                return priceChanged || supplierChanged;
              }).toList();

              return LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  // Two-column layout: left = full history list, right = table of changed items
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: allEntries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final d = allEntries[i];
                            final ts = d['timestamp'];
                            final when = ts is Timestamp ? ts.toDate().toLocal().toString() : (ts?.toString() ?? '');
                            final oldSup = d['oldSupplier'] ?? '';
                            final newSup = d['newSupplier'] ?? '';
                            final same = d['sameSupplier'] == true;
                            final oldP = d['oldPrice']?.toString() ?? '';
                            final newP = d['newPrice']?.toString() ?? '';
                            final addedQ = d['addedQuantity']?.toString() ?? '';

                            return ListTile(
                              title: Text('${d['itemName'] ?? ''} — +$addedQ'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('When: $when'),
                                  Text('Supplier: ${same ? '$oldSup (unchanged)' : '$oldSup → $newSup'}'),
                                  Text('Price: ${same ? (oldP.isNotEmpty ? '$oldP (unchanged)' : oldP) : '$oldP → $newP'}'),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right-side container should take only the width it needs instead of expanding
                      Align(
                        alignment: Alignment.topRight,
                        child: IntrinsicWidth(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Price / Supplier Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 520,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Item')),
                                          DataColumn(label: Text('Old Price')),
                                          DataColumn(label: Text('New Price')),
                                          DataColumn(label: Text('Old Supplier')),
                                          DataColumn(label: Text('New Supplier')),
                                        ],
                                        rows: changedEntries.map((d) {
                                          final itemName = d['itemName'] ?? '';
                                          final oldPstr = d['oldPrice']?.toString() ?? '';
                                          final newPstr = d['newPrice']?.toString() ?? '';
                                          final oldSup = d['oldSupplier'] ?? '';
                                          final newSup = d['newSupplier'] ?? '';
                                          double? oldPd = double.tryParse(oldPstr.replaceAll(',', ''));
                                          double? newPd = double.tryParse(newPstr.replaceAll(',', ''));
                                          Widget priceCell = Text(newPstr);
                                          if (oldPd != null && newPd != null) {
                                            if (newPd > oldPd) {
                                              priceCell = Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(newPstr),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                                                ],
                                              );
                                            } else if (newPd < oldPd) {
                                              priceCell = Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(newPstr),
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                                                ],
                                              );
                                            }
                                          }

                                          return DataRow(cells: [
                                            DataCell(Text(itemName)),
                                            DataCell(Text(oldPstr)),
                                            DataCell(priceCell),
                                            DataCell(Text(oldSup)),
                                            DataCell(Text(newSup)),
                                          ]);
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow: stack the two sections vertically
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: allEntries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final d = allEntries[i];
                            final ts = d['timestamp'];
                            final when = ts is Timestamp ? ts.toDate().toLocal().toString() : (ts?.toString() ?? '');
                            final oldSup = d['oldSupplier'] ?? '';
                            final newSup = d['newSupplier'] ?? '';
                            final same = d['sameSupplier'] == true;
                            final oldP = d['oldPrice']?.toString() ?? '';
                            final newP = d['newPrice']?.toString() ?? '';
                            final addedQ = d['addedQuantity']?.toString() ?? '';

                            return ListTile(
                              title: Text('${d['itemName'] ?? ''} — +$addedQ'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('When: $when'),
                                  Text('Supplier: ${same ? '$oldSup (unchanged)' : '$oldSup → $newSup'}'),
                                  Text('Price: ${same ? (oldP.isNotEmpty ? '$oldP (unchanged)' : oldP) : '$oldP → $newP'}'),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 260,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price / Supplier Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Item')),
                                    DataColumn(label: Text('Old Price')),
                                    DataColumn(label: Text('New Price')),
                                    DataColumn(label: Text('Old Supplier')),
                                    DataColumn(label: Text('New Supplier')),
                                  ],
                                  rows: changedEntries.map((d) {
                                    final itemName = d['itemName'] ?? '';
                                    final oldPstr = d['oldPrice']?.toString() ?? '';
                                    final newPstr = d['newPrice']?.toString() ?? '';
                                    final oldSup = d['oldSupplier'] ?? '';
                                    final newSup = d['newSupplier'] ?? '';
                                    double? oldPd = double.tryParse(oldPstr.replaceAll(',', ''));
                                    double? newPd = double.tryParse(newPstr.replaceAll(',', ''));
                                    Widget priceCell = Text(newPstr);
                                    if (oldPd != null && newPd != null) {
                                      if (newPd > oldPd) {
                                        priceCell = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(newPstr),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                                          ],
                                        );
                                      } else if (newPd < oldPd) {
                                        priceCell = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(newPstr),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
                                          ],
                                        );
                                      }
                                    }

                                    return DataRow(cells: [
                                      DataCell(Text(itemName)),
                                      DataCell(Text(oldPstr)),
                                      DataCell(priceCell),
                                      DataCell(Text(oldSup)),
                                      DataCell(Text(newSup)),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              });
            },
          ),
        ),
      ),
    );
  }
}
