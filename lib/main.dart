
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';


import 'package:rrms/screens/Request.dart';
import 'firebase_options.dart';
import 'screens/Inventory.dart';
import 'screens/dashboard.dart';
import 'screens/supplier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/inventory',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/dashboard':
            page = DashboardPage();
            break;
          case '/inventory':
            page = InventoryPage();
            break;
          case '/supplier':
            page = SupplierPage();
            break;
          case '/RequestItemPage':
            page = RequestPage();
            break;
          default:
            page = DashboardPage();
            break;
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RawComponentsUploader(),
    );
  }
}

class RawComponentsUploader extends StatefulWidget {
  const RawComponentsUploader({super.key});

  @override
  State<RawComponentsUploader> createState() => _RawComponentsUploaderState();
}

class _RawComponentsUploaderState extends State<RawComponentsUploader> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // ✅ NEW: Full inventory list (matches your Dart list)
  final List<Map<String, dynamic>> inventory = [
    // Meat / Poultry / Seafood
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Beef (ground)', 'quantity': 30.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier A', 'price': '\$12.50/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Beef (steak)', 'quantity': 10.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier A', 'price': '\$14.00/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Chicken Breast', 'quantity': 40.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier B', 'price': '\$8.20/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Turkey Slices', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier C', 'price': '\$14.00/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Salami', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier D', 'price': '\$22.00/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Shrimp', 'quantity': 10.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier E', 'price': '\$18.00/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Salmon', 'quantity': 8.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier F', 'price': '\$24.00/kg'},
    {'category': 'Meat / Poultry / Seafood', 'rawComponent': 'Bacon', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier G', 'price': '\$16.50/kg'},

    // Vegetables & Fruits
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Tomatoes', 'quantity': 23.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$2.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Onions', 'quantity': 9.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$1.20/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Garlic', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier H', 'price': '\$4.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Mushrooms', 'quantity': 9.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier I', 'price': '\$6.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Bell Peppers', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$3.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Zucchini', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$2.80/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Eggplant', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$3.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Potatoes', 'quantity': 23.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$0.90/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Lettuce', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$7.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Arugula (Rocca)', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$8.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Cherry Tomatoes', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$6.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Olives', 'quantity': 2.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier J', 'price': '\$10.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Watercress', 'quantity': 1.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$12.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Pineapple', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier K', 'price': '\$5.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Basil', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$15.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Parsley / Dill', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$10.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Lemon', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier L', 'price': '\$4.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Lime', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier L', 'price': '\$5.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Avocado', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier M', 'price': '\$6.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Mango', 'quantity': 4.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier N', 'price': '\$5.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Strawberry', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$12.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Blueberry', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier O', 'price': '\$18.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Raspberry', 'quantity': 1.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier O', 'price': '\$22.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Peach', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$4.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Kiwi', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier P', 'price': '\$6.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Orange', 'quantity': 10.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier Q', 'price': '\$2.50/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Watermelon', 'quantity': 8.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$2.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Pomegranate Seeds', 'quantity': 1.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier R', 'price': '\$30.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Sun-Dried Tomatoes', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier S', 'price': '\$20.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Carrots', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$1.00/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Cucumber', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$2.20/kg'},
    {'category': 'Vegetables & Fruits', 'rawComponent': 'Spinach', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Local Farm', 'price': '\$7.00/kg'},

    // Dairy
    {'category': 'Dairy', 'rawComponent': 'Cow’s Milk', 'quantity': 45.0, 'unit': 'L', 'fillingWay': 'Bag (Bag-in-box)', 'supplier': 'Dairy Co.', 'price': '\$1.20/L'},
    {'category': 'Dairy', 'rawComponent': 'Plant-Based Milk', 'quantity': 10.0, 'unit': 'L', 'fillingWay': 'Carton', 'supplier': 'Supplier T', 'price': '\$2.50/L'},
    {'category': 'Dairy', 'rawComponent': 'Cream (heavy)', 'quantity': 7.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Dairy Co.', 'price': '\$4.00/L'},
    {'category': 'Dairy', 'rawComponent': 'Butter', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Dairy Co.', 'price': '\$8.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Mozzarella', 'quantity': 8.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Cheese Co.', 'price': '\$10.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Cheddar', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Cheese Co.', 'price': '\$12.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Feta', 'quantity': 2.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Cheese Co.', 'price': '\$14.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Parmesan', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Cheese Co.', 'price': '\$25.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Yogurt', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Dairy Co.', 'price': '\$3.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Mascarpone', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Cheese Co.', 'price': '\$18.00/kg'},
    {'category': 'Dairy', 'rawComponent': 'Whipped Cream', 'quantity': 3.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Dairy Co.', 'price': '\$6.00/L'},

    // Gluten-Containing
    {'category': 'Gluten-Containing', 'rawComponent': 'Wheat Flour', 'quantity': 28.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Mill Co.', 'price': '\$1.00/kg'},
    {'category': 'Gluten-Containing', 'rawComponent': 'Semolina Flour', 'quantity': 12.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Mill Co.', 'price': '\$1.80/kg'},
    {'category': 'Gluten-Containing', 'rawComponent': 'Soy Sauce', 'quantity': 3.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier V', 'price': '\$5.00/L'},
    {'category': 'Gluten-Containing', 'rawComponent': 'Breadcrumbs', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier W', 'price': '\$6.00/kg'},
    {'category': 'Gluten-Containing', 'rawComponent': 'Beer (for cooking)', 'quantity': 12.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Brewery X', 'price': '\$3.00/L'},
    {'category': 'Gluten-Containing', 'rawComponent': 'Oats (non-GF)', 'quantity': 3.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Mill Co.', 'price': '\$2.50/kg'},

    // Egg-Based
    {'category': 'Egg-Based', 'rawComponent': 'Eggs', 'quantity': 4.5, 'unit': 'kg', 'fillingWay': 'Carton', 'supplier': 'Farm LL', 'price': '\$6.00/kg'},
    {'category': 'Egg-Based', 'rawComponent': 'Egg Whites', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Carton', 'supplier': 'Supplier MM', 'price': '\$8.00/kg'},

    // Fats / Oils
    {'category': 'Fats / Oils', 'rawComponent': 'Olive Oil', 'quantity': 8.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier OO', 'price': '\$10.00/L'},
    {'category': 'Fats / Oils', 'rawComponent': 'Vegetable Oil', 'quantity': 20.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier PP', 'price': '\$2.50/L'},
    {'category': 'Fats / Oils', 'rawComponent': 'Butter', 'quantity': 3.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Dairy Co.', 'price': '\$8.00/kg'},
    {'category': 'Fats / Oils', 'rawComponent': 'Coconut Oil', 'quantity': 5.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier RR', 'price': '\$12.00/L'},

    // Spices / Seasonings
    {'category': 'Spices / Seasonings', 'rawComponent': 'Salt', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier SS', 'price': '\$1.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Black Pepper', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier TT', 'price': '\$20.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Paprika', 'quantity': 1.5, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier UU', 'price': '\$15.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Oregano', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier VV', 'price': '\$25.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Basil (dried)', 'quantity': 1.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier VV', 'price': '\$28.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Chili Flakes', 'quantity': 1.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier WW', 'price': '\$18.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Garlic Powder', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier XX', 'price': '\$12.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Onion Powder', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier XX', 'price': '\$10.00/kg'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Mustard', 'quantity': 3.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier YY', 'price': '\$5.00/L'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Balsamic Vinegar', 'quantity': 4.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier ZZ', 'price': '\$8.00/L'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Lemon Juice (bottled)', 'quantity': 5.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier AAA', 'price': '\$6.00/L'},
    {'category': 'Spices / Seasonings', 'rawComponent': 'Worcestershire Sauce', 'quantity': 2.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier BBB', 'price': '\$7.00/L'},

    // Beverages
    {'category': 'Beverages', 'rawComponent': 'Coffee Beans', 'quantity': 10.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Roaster CCC', 'price': '\$20.00/kg'},
    {'category': 'Beverages', 'rawComponent': 'Matcha Powder', 'quantity': 1.0, 'unit': 'kg', 'fillingWay': 'Tin', 'supplier': 'Supplier DDD', 'price': '\$80.00/kg'},
    {'category': 'Beverages', 'rawComponent': 'Tea Leaves', 'quantity': 2.0, 'unit': 'kg', 'fillingWay': 'Bag', 'supplier': 'Supplier EEE', 'price': '\$30.00/kg'},
    {'category': 'Beverages', 'rawComponent': 'Carbonated Water', 'quantity': 50.0, 'unit': 'L', 'fillingWay': 'Keg', 'supplier': 'Supplier FFF', 'price': '\$0.50/L'},
    {'category': 'Beverages', 'rawComponent': 'Fruit Juices (fresh)', 'quantity': 30.0, 'unit': 'L', 'fillingWay': 'Jug', 'supplier': 'Local Farm', 'price': '\$4.00/L'},
    {'category': 'Beverages', 'rawComponent': 'Flavored Syrups', 'quantity': 10.0, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier GGG', 'price': '\$12.00/L'},
    {'category': 'Beverages', 'rawComponent': 'Ice Cubes', 'quantity': 100.0, 'unit': 'kg', 'fillingWay': '—', 'supplier': 'In-house', 'price': '\$0.10/kg'},
    {'category': 'Beverages', 'rawComponent': 'Condensed Milk', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Can', 'supplier': 'Dairy Co.', 'price': '\$5.00/kg'},
    {'category': 'Beverages', 'rawComponent': 'Evaporated Milk', 'quantity': 5.0, 'unit': 'kg', 'fillingWay': 'Can', 'supplier': 'Dairy Co.', 'price': '\$4.00/kg'},
    {'category': 'Beverages', 'rawComponent': 'Almond Milk', 'quantity': 10.0, 'unit': 'L', 'fillingWay': 'Carton', 'supplier': 'Supplier T', 'price': '\$2.50/L'},
    {'category': 'Beverages', 'rawComponent': 'Oat Milk', 'quantity': 10.0, 'unit': 'L', 'fillingWay': 'Carton', 'supplier': 'Supplier T', 'price': '\$2.80/L'},
    {'category': 'Beverages', 'rawComponent': 'Red Food Coloring', 'quantity': 0.5, 'unit': 'L', 'fillingWay': 'Bottle', 'supplier': 'Supplier HHH', 'price': '\$20.00/L'},
  ];

  bool _isUploading = false;

  /// 🔥 Delete ALL existing documents, then upload new list
  Future<void> uploadData() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      // 🔴 STEP 1: Delete all existing documents
      final existingDocs = await firestore.collection('raw_components').get();
      final deleteBatch = firestore.batch();
      for (var doc in existingDocs.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();

      // ✅ STEP 2: Upload new data
      final uploadBatch = firestore.batch();
      for (final item in inventory) {
        final docRef = firestore.collection('raw_components').doc();
        uploadBatch.set(docRef, {
          'name': item['rawComponent'],
          'category': item['category'],
          'quantity': item['quantity'],
          'unit': item['unit'],
          'fillingWay': item['fillingWay'],
          'supplier': item['supplier'],
          'price': item['price'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await uploadBatch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Inventory updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Raw Components Inventory',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        actions: [
          TextButton.icon(
            onPressed: _isUploading ? null : uploadData,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: Text(
              _isUploading ? 'Updating...' : 'Update Inventory',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('raw_components')
            .orderBy('category')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Error loading data'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No data yet. Tap "Update Inventory" to upload.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Group by category
          Map<String, List<Map<String, dynamic>>> categorizedData = {};
          for (var doc in docs) {
            final data = doc.data();
            final category = data['category'] ?? 'Unknown';
            categorizedData.putIfAbsent(category, () => []).add(data);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: categorizedData.entries.map((entry) {
              final category = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Filling')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Status')), // 🔹 New column
                      ],
                      rows: items.map((item) {
                        final quantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
                        final isLowStock = quantity <= 5.0; // 🔹 Threshold = 5

                        return DataRow(cells: [
                          DataCell(Text(item['name'] ?? '')),
                          DataCell(Text(item['quantity'].toString())),
                          DataCell(Text(item['unit'] ?? '')),
                          DataCell(Text(item['supplier'] ?? '')),
                          DataCell(Text(item['fillingWay'] ?? '')),
                          DataCell(Text(item['price'] ?? '')),
                          // 🔹 New: Low stock indicator
                          DataCell(
                            isLowStock
                                ? const Chip(
                                    label: Text('Low Stock', style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.red,
                                  )
                                : const Text('OK'),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
*/
/*
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SupplierUploaderPage(),
  ));
}

class SupplierUploaderPage extends StatefulWidget {
  const SupplierUploaderPage({super.key});

  @override
  State<SupplierUploaderPage> createState() => _SupplierUploaderPageState();
}

class _SupplierUploaderPageState extends State<SupplierUploaderPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  final Random random = Random();

  // ✅ Your full supplier list
  final List<String> suppliers = [
    'Supplier A', 'Supplier B', 'Supplier C', 'Supplier D', 'Supplier E',
    'Supplier F', 'Supplier G', 'Local Farm', 'Supplier H', 'Supplier I',
    'Supplier J', 'Supplier K', 'Supplier L', 'Supplier M', 'Supplier N',
    'Supplier O', 'Supplier P', 'Supplier Q', 'Supplier R', 'Supplier S',
    'Dairy Co.', 'Supplier T', 'Cheese Co.', 'Mill Co.', 'Supplier V',
    'Supplier W', 'Brewery X', 'Farm LL', 'Supplier MM', 'Supplier OO',
    'Supplier PP', 'Supplier RR', 'Supplier SS', 'Supplier TT', 'Supplier UU',
    'Supplier VV', 'Supplier WW', 'Supplier XX', 'Supplier YY', 'Supplier ZZ',
    'Supplier AAA', 'Supplier BBB', 'Roaster CCC', 'Supplier DDD',
    'Supplier EEE', 'Supplier FFF', 'Supplier GGG', 'In-house', 'Supplier HHH'
  ];

  // Egyptian data samples
  final List<String> egyptianCities = [
    'Cairo', 'Giza', 'Alexandria', 'Mansoura', 'Tanta',
    'Zagazig', 'Ismailia', 'Suez', 'Aswan', 'Fayoum'
  ];

  final List<String> egyptianStreets = [
    'El Tahrir St.', 'Nile Corniche', 'October Bridge', 'Abdel Aziz St.',
    'Mohandessin Main St.', 'Nasr City Blvd.', 'Dokki St.', 'Gamal Abdel Nasser St.'
  ];

  // Generate random Egyptian contact info
  String _generatePhone() {
    final prefixes = ['010', '011', '012', '015'];
    final prefix = prefixes[random.nextInt(prefixes.length)];
    final number = random.nextInt(90000000) + 10000000;
    return '+20 $prefix $number';
  }

  String _generateEmail(String supplierName) {
    final formatted = supplierName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$formatted@egyptmail.com';
  }

  String _generateAddress() {
    final street = egyptianStreets[random.nextInt(egyptianStreets.length)];
    final city = egyptianCities[random.nextInt(egyptianCities.length)];
    final building = random.nextInt(50) + 1;
    return '$building $street, $city, Egypt';
  }

  Future<void> uploadSuppliers() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      final batch = firestore.batch();

      // Optional: clear previous data
      final oldDocs = await firestore.collection('suppliers').get();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      // Upload all suppliers
      for (var supplier in suppliers) {
        final docRef = firestore.collection('suppliers').doc();
        batch.set(docRef, {
          'name': supplier,
          'contact': {
            'phone': _generatePhone(),
            'email': _generateEmail(supplier),
            'address': _generateAddress(),
          },
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All suppliers uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Suppliers (Egypt Edition)'),
        backgroundColor: Colors.green.shade800,
        actions: [
          TextButton.icon(
            onPressed: _isUploading ? null : uploadSuppliers,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: Text(
              _isUploading ? 'Uploading...' : 'Upload All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('suppliers').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Error loading suppliers'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No suppliers found.\nTap "Upload All" to generate Egyptian supplier data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
              columns: const [
                DataColumn(label: Text('Supplier Name')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Address')),
              ],
              rows: docs.map((doc) {
                final data = doc.data();
                final contact = data['contact'] ?? {};
                return DataRow(cells: [
                  DataCell(Text(data['name'] ?? '')),
                  DataCell(Text(contact['phone'] ?? '')),
                  DataCell(Text(contact['email'] ?? '')),
                  DataCell(Text(contact['address'] ?? '')),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
*/
/*
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:math';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SupplierUploaderPage(),
  ));
}

class SupplierUploaderPage extends StatefulWidget {
  const SupplierUploaderPage({super.key});

  @override
  State<SupplierUploaderPage> createState() => _SupplierUploaderPageState();
}

class _SupplierUploaderPageState extends State<SupplierUploaderPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  final Random random = Random();

  // ✅ Supplier list
  final List<String> suppliers = [
    'Supplier A', 'Supplier B', 'Supplier C', 'Supplier D', 'Supplier E',
    'Supplier F', 'Supplier G', 'Local Farm', 'Supplier H', 'Supplier I',
    'Supplier J', 'Supplier K', 'Supplier L', 'Supplier M', 'Supplier N',
    'Supplier O', 'Supplier P', 'Supplier Q', 'Supplier R', 'Supplier S',
    'Dairy Co.', 'Supplier T', 'Cheese Co.', 'Mill Co.', 'Supplier V',
    'Supplier W', 'Brewery X', 'Farm LL', 'Supplier MM', 'Supplier OO',
    'Supplier PP', 'Supplier RR', 'Supplier SS', 'Supplier TT', 'Supplier UU',
    'Supplier VV', 'Supplier WW', 'Supplier XX', 'Supplier YY', 'Supplier ZZ',
    'Supplier AAA', 'Supplier BBB', 'Roaster CCC', 'Supplier DDD',
    'Supplier EEE', 'Supplier FFF', 'Supplier GGG', 'In-house', 'Supplier HHH'
  ];

  // ✅ Egyptian cities and streets
  final List<String> egyptianCities = [
    'Cairo', 'Giza', 'Alexandria', 'Mansoura', 'Tanta',
    'Zagazig', 'Ismailia', 'Suez', 'Aswan', 'Fayoum'
  ];

  final List<String> egyptianStreets = [
    'El Tahrir St.', 'Nile Corniche', 'October Bridge', 'Abdel Aziz St.',
    'Mohandessin Main St.', 'Nasr City Blvd.', 'Dokki St.', 'Gamal Abdel Nasser St.'
  ];

  // ✅ List of possible items supplied
  final List<String> itemPool = [
    'Milk', 'Cheese', 'Yogurt', 'Butter', 'Beef', 'Chicken', 'Fish',
    'Lamb', 'Flour', 'Sugar', 'Salt', 'Rice', 'Beans', 'Tomatoes',
    'Onions', 'Garlic', 'Potatoes', 'Oil', 'Vinegar', 'Bread',
    'Spices', 'Tea', 'Coffee', 'Juice', 'Soft Drinks', 'Beer',
    'Pasta', 'Canned Goods', 'Olive Oil', 'Cheddar Cheese',
    'Mozzarella', 'Cream', 'Eggs', 'Vegetables', 'Fruits', 'Ice Cream',
    'Sauces', 'Honey', 'Herbs', 'Nuts', 'Cocoa', 'Water', 'Cereal',
    'Coffee Beans', 'Wheat', 'Corn', 'Yeast', 'Baking Powder'
  ];

  // Generate random Egyptian contact info
  String _generatePhone() {
    final prefixes = ['010', '011', '012', '015'];
    final prefix = prefixes[random.nextInt(prefixes.length)];
    final number = random.nextInt(90000000) + 10000000;
    return '+20 $prefix $number';
  }

  String _generateEmail(String supplierName) {
    final formatted = supplierName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '$formatted@egyptmail.com';
  }

  String _generateAddress() {
    final street = egyptianStreets[random.nextInt(egyptianStreets.length)];
    final city = egyptianCities[random.nextInt(egyptianCities.length)];
    final building = random.nextInt(50) + 1;
    return '$building $street, $city, Egypt';
  }

  List<String> _generateSuppliedItems() {
    int count = random.nextInt(4) + 2; // between 2 and 6 items
    final shuffled = List<String>.from(itemPool)..shuffle(random);
    return shuffled.take(count).toList();
  }

  Future<void> uploadSuppliers() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);
    try {
      final batch = firestore.batch();

      // Optional: clear previous data
      final oldDocs = await firestore.collection('suppliers').get();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }

      // Upload all suppliers
      for (var supplier in suppliers) {
        final docRef = firestore.collection('suppliers').doc();
        batch.set(docRef, {
          'name': supplier,
          'contact': {
            'phone': _generatePhone(),
            'email': _generateEmail(supplier),
            'address': _generateAddress(),
          },
          'suppliedItems': _generateSuppliedItems(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ All suppliers with items uploaded successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Upload failed: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text('Suppliers (Egypt + Supplied Items)'),
        backgroundColor: Colors.green.shade800,
        actions: [
          TextButton.icon(
            onPressed: _isUploading ? null : uploadSuppliers,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: Text(
              _isUploading ? 'Uploading...' : 'Upload All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore.collection('suppliers').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('❌ Error loading suppliers'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No suppliers found.\nTap "Upload All" to generate Egyptian supplier data with items.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
              columns: const [
                DataColumn(label: Text('Supplier Name')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Supplied Items')),
              ],
              rows: docs.map((doc) {
                final data = doc.data();
                final contact = data['contact'] ?? {};
                final items = List<String>.from(data['suppliedItems'] ?? []);
                return DataRow(cells: [
                  DataCell(Text(data['name'] ?? '')),
                  DataCell(Text(contact['phone'] ?? '')),
                  DataCell(Text(contact['email'] ?? '')),
                  DataCell(Text(contact['address'] ?? '')),
                  DataCell(Text(items.join(', '))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
*/
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Import your Firebase configuration
import 'firebase_options.dart'; // <-- make sure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await KitchenRequestUploader.uploadAllData();
  print('✅ Kitchen request document uploaded successfully.');
}

class KitchenRequestUploader {
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static Future<void> uploadAllData() async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String();

    final List<Map<String, dynamic>> allItems = [
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Watermelon'},
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Pomegranate Seeds'},
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Sun-Dried Tomatoes'},
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Carrots'},
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Cucumber'},
      {'category': 'Vegetables & Fruits', 'rawComponent': 'Spinach'},
      {'category': 'Dairy', 'rawComponent': 'Cow’s Milk'},
      {'category': 'Dairy', 'rawComponent': 'Plant-Based Milk'},
      {'category': 'Dairy', 'rawComponent': 'Cream (heavy)'},
      {'category': 'Dairy', 'rawComponent': 'Butter'},
      {'category': 'Dairy', 'rawComponent': 'Mozzarella'},
      {'category': 'Dairy', 'rawComponent': 'Cheddar'},
      {'category': 'Dairy', 'rawComponent': 'Feta'},
      {'category': 'Gluten-Containing', 'rawComponent': 'Soy Sauce'},
      {'category': 'Gluten-Containing', 'rawComponent': 'Breadcrumbs'},
      {'category': 'Gluten-Containing', 'rawComponent': 'Beer (for cooking)'},
      {'category': 'Gluten-Containing', 'rawComponent': 'Oats (non-GF)'},
      {'category': 'Egg-Based', 'rawComponent': 'Eggs'},
      {'category': 'Egg-Based', 'rawComponent': 'Egg Whites'},
      {'category': 'Fats / Oils', 'rawComponent': 'Olive Oil'},
      {'category': 'Fats / Oils', 'rawComponent': 'Vegetable Oil'},
      {'category': 'Fats / Oils', 'rawComponent': 'Butter'},
      {'category': 'Fats / Oils', 'rawComponent': 'Coconut Oil'},
      {'category': 'Spices / Seasonings', 'rawComponent': 'Salt'},
      {'category': 'Spices / Seasonings', 'rawComponent': 'Black Pepper'},
      {'category': 'Spices / Seasonings', 'rawComponent': 'Paprika'},
    ];

    final int mid = allItems.length ~/ 2;

    // Pending items
    final pendingItems = allItems.sublist(0, mid).map((item) {
      return {
        'name': item['rawComponent'],
        'category': item['category'],
        'date': todayStr,
        'status': 'pending',
      };
    }).toList();

    // Sent items (requestDate < sentDate)
    final sentItems = allItems.sublist(mid).map((item) {
      final randomDays = (1 + DateTime.now().millisecondsSinceEpoch % 2);
      final requestDate = now.subtract(Duration(days: randomDays + 1));
      final sentDate = requestDate.add(Duration(days: randomDays));

      return {
        'name': item['rawComponent'],
        'category': item['category'],
        'requestDate': requestDate.toIso8601String(),
        'sentDate': sentDate.toIso8601String(),
        'sentQty': 3.0,
        'status': 'sent',
      };
    }).toList();

    try {
      await firestore.collection('kitchen_requests').add({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'pending': pendingItems,
        'sent': sentItems,
      });
      print('✅ Data uploaded successfully with realistic date differences.');
    } catch (e) {
      print('❌ Error uploading data: $e');
    }
  }
}
*/