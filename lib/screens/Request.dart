import 'package:flutter/material.dart';
import 'package:rrms/widget/side_bar.dart';

class RequestItemPage extends StatefulWidget {
  const RequestItemPage({super.key});

  @override
  State<RequestItemPage> createState() => _RequestItemPageState();
}

class _RequestItemPageState extends State<RequestItemPage> {
  final List<Map<String, dynamic>> _requests = [
    {
      "product": "Tomato",
      "category": "Vegetable",
      "name2": "Tomato",
      "done": false,
    },
    {
      "product": "Chicken Breast",
      "category": "Meat",
      "name2": "Chicken",
      "done": false,
    },
    {"product": "Rice", "category": "Grain", "name2": "Rice", "done": false},
  ];

  void _markDone(int index) {
    setState(() {
      _requests[index]['done'] = true;
    });
  }

  void _deleteRow(int index) {
    setState(() {
      _requests.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffefafa),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SideBar(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "REQUEST ITEM",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            const Color(0xfff6f6f6),
                          ),
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columns: const [
                            DataColumn(
                              label: Text(
                                "Product Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Category",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Product Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Action",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                          rows: List<DataRow>.generate(_requests.length, (
                            index,
                          ) {
                            final item = _requests[index];
                            final bool done = item['done'];

                            return DataRow(
                              color: done
                                  ? MaterialStateProperty.all(
                                      Colors.green.withOpacity(0.1),
                                    )
                                  : MaterialStateProperty.all(Colors.white),
                              cells: [
                                DataCell(
                                  Text(
                                    item['product'],
                                    style: TextStyle(
                                      color: done
                                          ? Colors.green.shade800
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item['category'],
                                    style: TextStyle(
                                      color: done
                                          ? Colors.green.shade800
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    item['name2'],
                                    style: TextStyle(
                                      color: done
                                          ? Colors.green.shade800
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: done
                                            ? null
                                            : () => _deleteRow(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade300,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        child: const Text("Delete"),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: done
                                            ? null
                                            : () => _markDone(index),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xff6fad99,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        child: const Text("Done"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
