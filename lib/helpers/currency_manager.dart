import 'package:flutter/material.dart';

class CurrencyManager {
  // Yeh ValueNotifier poori app mein currency symbol ko hold karega.
  // Default value 'Rs.' hai.
  static ValueNotifier<String> currencySymbol = ValueNotifier('Rs.');

  // Currency ki list jo hum settings mein dikhayenge
  static final Map<String, String> currencies = {
    'Rs.': 'PKR - Pakistani Rupee',
    '\$': 'USD - US Dollar',
    '€': 'EUR - Euro',
    '₹': 'INR - Indian Rupee',
    '£': 'GBP - British Pound',
    'AED': 'AED - UAE Dirham',
    'SAR': 'SAR - Saudi Riyal',
  };
}