import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'food_order.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create food_items table
        await db.execute(''' 
        CREATE TABLE food_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          cost REAL
        )
      ''');

        // Create orders table
        await db.execute(''' 
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          food_items TEXT, -- Store JSON of selected food items
          total_cost REAL
        )
      ''');
      },
    );
  }


  Future<void> insertFoodItems(List<Map<String, dynamic>> items) async {
    final db = await database;

    for (var item in items) {
      // Check if the food item already exists in the database by its name
      final existingItem = await db.query(
        'food_items',
        where: 'name = ?',
        whereArgs: [item['name']],
      );

      // If no item with the same name exists, insert the item
      if (existingItem.isEmpty) {
        await db.insert('food_items', item, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }


  Future<List<Map<String, dynamic>>> getFoodItems() async {
    final db = await database;
    return await db.query('food_items');
  }

  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('orders', order);
  }

  Future<List<Map<String, dynamic>>> getOrdersByDate(String date) async {
    final db = await database;
    // Query the orders based on the provided date
    final List<Map<String, dynamic>> orders = await db.query(
        'orders',
        where: 'date = ?',
        whereArgs: [date]
    );

    // Decode the 'food_items' JSON column for each order
    for (var order in orders) {
      if (order['food_items'] != null) {
        order['food_items'] = jsonDecode(order['food_items']);  // Decode the JSON string
      }
    }

    return orders;
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    // Your query logic to fetch the order by its ID from the database
    // This is just an example, replace with your actual implementation
    final db = await database;
    var result = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // Method to delete an order by ID
  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // Method to update an order by ID
  Future<int> updateOrder(int id, Map<String, dynamic> order) async {
    final db = await database;
    return await db.update(
      'orders', // Table name
      order, // The updated order data
      where: 'id = ?', // Condition for which row to update
      whereArgs: [id], // The ID of the order to update
    );
  }


  Future<void> insertOrderPlan(Map<String, dynamic> orderPlan) async {
    final db = await database;
    await db.insert('order_plans', orderPlan);
  }

  Future<List<Map<String, dynamic>>> getOrderPlans(String date) async {
    final db = await database;
    return await db.query('order_plans', where: 'date = ?', whereArgs: [date]);
  }

  Future<List<Map<String, dynamic>>> getOrderPlanByDate(String date) async {
    final db = await database;

    // Fetch orders for the specified date
    final List<Map<String, dynamic>> orders = await db.query(
      'orders',
      where: 'date = ?',
      whereArgs: [date],
    );

    // Create mutable copies and decode food_items
    final List<Map<String, dynamic>> mutableOrders = orders.map((order) {
      final mutableOrder = Map<String, dynamic>.from(order);

      // Decode the 'food_items' JSON string if it exists
      if (mutableOrder['food_items'] is String) {
        try {
          mutableOrder['food_items'] = jsonDecode(mutableOrder['food_items']);
        } catch (e) {
          print("Error decoding food_items JSON: $e");
          mutableOrder['food_items'] = [];
        }
      }

      return mutableOrder;
    }).toList();

    return mutableOrders;
  }






  Future<int> deleteOrderById(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }


  // Update the food items table name
  Future<void> updateFoodItem(int id, Map<String, dynamic> updatedItem) async {
    final db = await database;
    await db.update(
      'food_items',  // Change from 'food' to 'food_items'
      updatedItem,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update the food items table name
  Future<void> deleteFoodItem(int id) async {
    final db = await database;
    await db.delete(
      'food_items',  // Change from 'food' to 'food_items'
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
