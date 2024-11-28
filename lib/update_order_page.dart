import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // For date formatting
import 'database_helper.dart';
import 'order.dart';

class UpdateOrderPage extends StatefulWidget {
  final int orderId;
  final String currentDate;
  final List<Map<String, dynamic>> currentFoodItems;
  final double targetCost;

  UpdateOrderPage({
    required this.orderId,
    required this.currentDate,
    required this.currentFoodItems,
    required this.targetCost,
  });

  @override
  _UpdateOrderPageState createState() => _UpdateOrderPageState();
}

class _UpdateOrderPageState extends State<UpdateOrderPage> {
  late final TextEditingController newDateController;
  late final TextEditingController targetCostController;
  late List<Map<String, dynamic>> selectedFoodItems;
  late List<dynamic> currentFoodItems;
  double currentTotalCost = 0.0;

  @override
  void initState() {
    super.initState();
    newDateController = TextEditingController();
    targetCostController = TextEditingController();
    selectedFoodItems = [];

    // Use the currentFoodItems and currentDate passed from the constructor
    currentFoodItems = widget.currentFoodItems;
    newDateController.text = widget.currentDate;
    targetCostController.text = widget.targetCost.toString();
    _loadOrderDetails();
  }

  void _loadOrderDetails() async {
    final dbHelper = DatabaseHelper();

    // Fetch the order details by orderId
    final order = await dbHelper.getOrderById(widget.orderId);
    if (order != null) {
      currentFoodItems = jsonDecode(order['food_items'] ?? '[]');
      newDateController.text = order['date'] ?? '';
      targetCostController.text = order['target_cost'].toString();
    }
  }

  void _calculateTotalCost() {
    currentTotalCost = selectedFoodItems.fold(0.0, (sum, item) {
      return sum + (item['cost'] as double);
    });
    setState(() {});
  }

  void _updateOrder() async {
    final dbHelper = DatabaseHelper();

    final updatedFoodItems = selectedFoodItems.isNotEmpty
        ? selectedFoodItems
        : currentFoodItems; // Retain existing food items if none selected

    final double updatedTargetCost = double.tryParse(targetCostController.text) ?? widget.targetCost;

    await dbHelper.updateOrder(widget.orderId, {
      'date': newDateController.text,
      'food_items': jsonEncode(updatedFoodItems),
      'total_cost': updatedFoodItems.fold(0.0, (sum, item) => sum + (item['cost'] as double)),
      'target_cost': updatedTargetCost, // Update the target cost
    });

    Navigator.pop(context); // Go back to the previous page
    _loadOrderDetails(); // Reload the updated order details
  }

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Order ID: ${widget.orderId}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: newDateController,
                decoration: const InputDecoration(labelText: 'New Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 10),
              const Text('Select Food Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder(
                future: dbHelper.getFoodItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    final foodItems = snapshot.data as List<Map<String, dynamic>>;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),  // Prevent nested scrolling
                      itemCount: foodItems.length,
                      itemBuilder: (context, index) {
                        final item = foodItems[index];
                        final isSelected = selectedFoodItems.any((selected) => selected['name'] == item['name']) ||
                            currentFoodItems.any((current) => current['name'] == item['name']);
                        return CheckboxListTile(
                          title: Text(item['name']),
                          subtitle: Text('\$${item['cost']}'),
                          value: isSelected,
                          activeColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedFoodItems.add(item);
                              } else {
                                selectedFoodItems.removeWhere((selected) => selected['name'] == item['name']);
                              }
                              _calculateTotalCost(); // Recalculate the total cost
                            });
                          },
                        );
                      },
                    );
                  } else {
                    return const Text('No food items available.');
                  }
                },
              ),
              const SizedBox(height: 20),
              // Show a message if the cost exceeds the target
              if (currentTotalCost > (double.tryParse(targetCostController.text) ?? 0.0))
                Text(
                  'Total cost exceeds the target cost!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 10),
              // Editable field for target cost
              TextField(
                controller: targetCostController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Cost',
                  prefixText: '\$',
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: currentTotalCost > (double.tryParse(targetCostController.text) ?? 0.0)
                    ? null
                    : _updateOrder, // Disable if cost exceeds target
                child: const Text('Update'),
              ),
              Text(
                'Target Cost: \$${targetCostController.text}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Current Total Cost: \$${currentTotalCost.toStringAsFixed(2)}',
                style: TextStyle(color: currentTotalCost > (double.tryParse(targetCostController.text) ?? 0.0) ? Colors.red : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






