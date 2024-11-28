import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ensure this is the correct path to your DatabaseHelper file.
import 'order.dart'; // Import your OrderPlanForm

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  int _selectedIndex = 0; // Index to track the selected page

  // Pages for the navigation bar
  final List<Widget> _pages = [
    const FoodPage(), // Updated: Extracted the food grid to its own widget
    const OrderPlanForm(), // Reference the order.dart form here
  ];

  // Initialize data (insert food items)
  void _initializeData() async {
    final dbHelper = DatabaseHelper();

    // List of predefined food items to insert
    List<Map<String, dynamic>> foodItems = [
      {'name': 'Pizza', 'cost': 8.5},
      {'name': 'Burger', 'cost': 5.0},
      {'name': 'Pasta', 'cost': 7.0},
      {'name': 'Sushi', 'cost': 10.0},
      {'name': 'Salad', 'cost': 4.5},
      {'name': 'Sandwich', 'cost': 6.0},
      {'name': 'Tacos', 'cost': 6.5},
      {'name': 'Steak', 'cost': 15.0},
      {'name': 'Fries', 'cost': 3.0},
      {'name': 'Chicken Wings', 'cost': 9.0},
      {'name': 'Fish', 'cost': 11.0},
      {'name': 'Ice Cream', 'cost': 4.0},
      {'name': 'Cake', 'cost': 6.5},
      {'name': 'Coffee', 'cost': 3.0},
      {'name': 'Juice', 'cost': 2.5},
      {'name': 'Tea', 'cost': 2.0},
      {'name': 'Samosa', 'cost': 1.5},
      {'name': 'Noodles', 'cost': 7.5},
      {'name': 'Pancake', 'cost': 5.0},
      {'name': 'Rice Bowl', 'cost': 8.0},
    ];

    // Insert the predefined food items
    await dbHelper.insertFoodItems(foodItems);

    // Refresh the UI after loading data
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Ordering App'),
        backgroundColor: const Color.fromARGB(255, 50, 55, 60),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Order',
          ),
        ],
      ),
    );
  }
}

class FoodPage extends StatefulWidget {
  const FoodPage({super.key});

  @override
  _FoodPageState createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Open a form to add a new food item
              _showAddFoodDialog(context);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: DatabaseHelper().getFoodItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            final foodItems = snapshot.data as List<Map<String, dynamic>>;
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                final item = foodItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('\$${item['cost']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditFoodDialog(context, item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _deleteFoodItem(context, item['id']);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No food items available'));
          }
        },
      ),
    );
  }

  // Add a new food item through a dialog
  void _showAddFoodDialog(BuildContext context) {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Food Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final cost = double.tryParse(costController.text) ?? 0.0;

                if (name.isNotEmpty && cost > 0) {
                  await DatabaseHelper().insertFoodItems([
                    {'name': name, 'cost': cost},
                  ]);
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close the dialog
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Edit an existing food item
  void _showEditFoodDialog(BuildContext context, Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item['name']);
    final costController = TextEditingController(text: item['cost'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Food Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;
                final cost = double.tryParse(costController.text) ?? 0.0;

                if (name.isNotEmpty && cost > 0) {
                  await DatabaseHelper().updateFoodItem(item['id'], {
                    'name': name,
                    'cost': cost,
                  });
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close the dialog
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Delete a food item and refresh the list
  void _deleteFoodItem(BuildContext context, int id) async {
    await DatabaseHelper().deleteFoodItem(id);
    setState(() {}); // Trigger a rebuild to refresh the list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Food item deleted')),
    );
  }
}

