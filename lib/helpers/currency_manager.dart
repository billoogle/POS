import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyManager {
  // Singleton pattern
  static final CurrencyManager _instance = CurrencyManager._internal();
  factory CurrencyManager() => _instance;
  CurrencyManager._internal();

  // ValueNotifier for reactive updates across the app
  static final ValueNotifier<String> currencySymbol = ValueNotifier('Rs.');

  // SharedPreferences key
  static const String _currencyKey = 'selected_currency';

  // Available currencies with full names
  static final Map<String, String> currencies = {
    'Rs.': 'PKR - Pakistani Rupee',
    '\$': 'USD - US Dollar',
    '€': 'EUR - Euro',
    '₹': 'INR - Indian Rupee',
    '£': 'GBP - British Pound',
    'AED': 'AED - UAE Dirham',
    'SAR': 'SAR - Saudi Riyal',
  };

  // Initialize currency from SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_currencyKey);
    
    if (savedCurrency != null && currencies.containsKey(savedCurrency)) {
      currencySymbol.value = savedCurrency;
    } else {
      // Default to PKR
      currencySymbol.value = 'Rs.';
    }
    
    print('✅ Currency initialized: ${currencySymbol.value}');
  }

  // Save selected currency
  static Future<void> setCurrency(String currency) async {
    if (!currencies.containsKey(currency)) {
      print('❌ Invalid currency: $currency');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
    currencySymbol.value = currency;
    
    print('✅ Currency saved: $currency');
  }

  // Get current currency
  static String get currentCurrency => currencySymbol.value;

  // Get current currency full name
  static String get currentCurrencyName => 
      currencies[currencySymbol.value] ?? 'Unknown Currency';

  // Format amount with current currency
  static String format(double amount, {int decimals = 0}) {
    final symbol = currencySymbol.value;
    final formatted = amount.toStringAsFixed(decimals);
    
    // For symbols like $, €, £ - put before amount
    if (symbol == '\$' || symbol == '€' || symbol == '£') {
      return '$symbol$formatted';
    }
    
    // For Rs., ₹, AED, SAR - put after "Rs. " or before
    if (symbol == 'Rs.' || symbol == '₹') {
      return '$symbol $formatted';
    }
    
    // For AED, SAR - put after
    return '$symbol $formatted';
  }
}