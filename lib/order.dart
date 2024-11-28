import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // For date formatting
import 'database_helper.dart';
import 'update_order_page.dart';

class OrderPlanForm extends StatefulWidget {
  const OrderPlanForm({super.key});

  @override
  _OrderPlanFormState createState() => _OrderPlanFormState();
}

class _OrderPlanFormState extends State<OrderPlanForm> with SingleTickerProviderStateMixin {
  final TextEditingController _dateController = TextEditingController();
  List<Map<String, dynamic>> _orderPlans = [];
  double _targetCost = 0.0;
  final List<Map<String, dynamic>> _selectedFoodItems = [];

  late TabController _tabController;  // For controlling the tab navigation

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);  // 2 tabs: Query and Add Order Plan
  }

  @override
  void dispose() {
    _tabController.dispose();  // Dispose of the TabController when the widget is disposed.
    super.dispose();
  }

  void _queryOrders() async {
    final dbHelper = DatabaseHelper();
    final result = await dbHelper.getOrderPlanByDate(_dateController.text);

    // Ensure 'food_items' is consistently a List
    final List<Map<String, dynamic>> mutableOrders = result.map((order) {
      final foodItems = order['food_items'];
      order['food_items'] = (foodItems is String)
          ? jsonDecode(foodItems)
          : (foodItems is List ? foodItems : []);
      return Map<String, dynamic>.from(order);
    }).toList();

    setState(() {
      _orderPlans = mutableOrders;
    });
  }



  // Method to save the order plan
  void _saveOrderPlan() async {
    final totalCost = _selectedFoodItems.fold(0.0, (sum, item) => sum + item['cost']);
    final foodItems = _selectedFoodItems.map((item) => {'name': item['name'], 'cost': item['cost']}).toList();

    await DatabaseHelper().insertOrder({
      'date': _dateController.text,
      'food_items': jsonEncode(foodItems),
      'total_cost': totalCost,
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order saved')));
    setState(() {
      _selectedFoodItems.clear();
    });
  }

  // Method to delete the order plan
  void _deleteOrder(int orderId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteOrder(orderId);  // Ensure you have a deleteOrder method in DatabaseHelper
    setState(() {
      _orderPlans.removeWhere((order) => order['id'] == orderId);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted')));
  }

  // Method to update the order plan
  void _updateOrder(int orderId) async {
    final order = _orderPlans.firstWhere((o) => o['id'] == orderId);
    final List<dynamic> currentFoodItems = order['food_items'] is String
        ? jsonDecode(order['food_items'] ?? '[]')
        : order['food_items'] ?? [];

    // Navigate to the update order page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateOrderPage(
          orderId: orderId,
          currentDate: order['date'] ?? '',
          currentFoodItems: currentFoodItems.cast<Map<String, dynamic>>(),
          targetCost: order['total_cost'],
        ),
      ),
    );
  }



  // Method to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),  // Current date
      firstDate: DateTime(2000),    // Earliest possible date
      lastDate: DateTime(2101),     // Latest possible date
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Plan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Query Orders'),
            Tab(text: 'Add Order Plan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Query Orders Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Date (YYYY-MM-DD)',
                  ),
                ),
                ElevatedButton(
                  onPressed: _queryOrders,
                  child: const Text('Query Orders'),
                ),
                  Expanded(
                  child: _orderPlans.isEmpty
                  ? const Center(child: Text('No orders found for this date.'))
                      : ListView.builder(
                  itemCount: _orderPlans.length,
                  itemBuilder: (context, index) {
                  final orderPlan = _orderPlans[index];
                  final totalCost = orderPlan['total_cost'];

                  // Dynamically parse 'food_items' field
                  final foodItems = orderPlan['food_items'];
                  final parsedFoodItems = (foodItems is String)
                  ? jsonDecode(foodItems) // Decode if it's a JSON string
                      : (foodItems is List ? foodItems : []); // Use as-is if it's already a list

                  return ListTile(
                  title: Text('Order Plan ID: ${orderPlan['id']}'),
                  subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text('Total Cost: \$${totalCost.toStringAsFixed(2)}'),
                  Text('Food Items:'),
                  for (var foodItem in parsedFoodItems)
                  Text('- ${foodItem['name']} (Cost: \$${foodItem['cost']})'),
                  ],
                  ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'update') {
                              _updateOrder(orderPlan['id']);
                            } else if (value == 'delete') {
                              _deleteOrder(orderPlan['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'update',
                              child: Text('Update Order'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Delete Order'),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Optionally, you could add an action here to show more details of the order
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Add Order Plan Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date input with date picker
                GestureDetector(
                  onTap: () => _selectDate(context),  // Trigger the date picker when the field is tapped
                  child: AbsorbPointer(  // Disable direct editing of the field
                    child: TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Select Date (YYYY-MM-DD)',
                        hintText: 'Tap to select date',
                      ),
                    ),
                  ),
                ),
                TextField(
                  onChanged: (value) {
                    _targetCost = double.tryParse(value) ?? 0.0;
                  },
                  decoration: const InputDecoration(labelText: 'Target Cost'),
                  keyboardType: TextInputType.number,
                ),
                Expanded(
                  child: FutureBuilder(
                    future: DatabaseHelper().getFoodItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasData) {
                        final foodItems = snapshot.data as List<Map<String, dynamic>>;
                        return ListView.builder(
                          itemCount: foodItems.length,
                          itemBuilder: (context, index) {
                            final item = foodItems[index];
                            final selectedCost = _selectedFoodItems.fold(0.0, (sum, item) => sum + item['cost']);
                            return CheckboxListTile(
                              title: Text(item['name']),
                              subtitle: Text('\$${item['cost']}'),
                              value: _selectedFoodItems.contains(item),
                              activeColor: Colors.white70,
                              onChanged: selectedCost + item['cost'] <= _targetCost
                                  ? (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedFoodItems.add(item);
                                  } else {
                                    _selectedFoodItems.remove(item);
                                  }
                                });
                              }
                                  : null,
                            );
                          },
                        );
                      } else {
                        return const Center(child: Text('No food items available.'));
                      }
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _saveOrderPlan,
                  child: const Text('Save Order Plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

