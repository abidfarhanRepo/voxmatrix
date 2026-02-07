import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFB30000); // Vibrant Red
  static const Color primaryVariant = Color(0xFF4A0404); // Deepest Red
  static const Color secondary = Color(0xFF7A0404); // Mid Red
  static const Color secondaryVariant = Color(0xFF2D0A0A);

  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0x14FFFFFF); // 8% White (approx)
  static const Color surfaceVariant = Color(0x0DFFFFFF); // 5% White

  static const Color error = Color(0xFFF87171);
  static const Color onError = Color(0xFF000000);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);

  static const Color outline = Color(0x0DFFFFFF); // 5% White
  static const Color muted = Color(0x66FFFFFF); // 40% White

  static const Color gradientStart = Color(0xFF000000); 
  static const Color gradientMid = Color(0xFF0A0505);   
  static const Color gradientEnd = Color(0xFF1A0A0A);   

  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF38BDF8);

  // Deep Red Aesthetic (Snippet specific)
  static const Color deepRed = Color(0xFF4A0404);
  static const Color highlightRed = Color(0xFFB30000);
  static const Color obsidian = Color(0xFF000000);
  
  // Glassmorphism Colors (Snippet specific)
  static const Color glassBorder = Color(0x0DFFFFFF); // 5% White
  static const Color glassLow = Color(0x14FFFFFF);    // 8% White
  static const Color glassMedium = Color(0x26FFFFFF); // 15% White
  static const Color glassHigh = Color(0x99000000);   // 60% Black (approx for blurred bars)
  static const Color glassOverlay = Color(0x80000000); 
  
  // Text on Glass
  static const Color textPrimary = Color(0xFFFFFFFF); 
  static const Color textSecondary = Color(0x99FFFFFF); // 60% White

  // Chat colors (Snippet specific)
  static const Color messageSent = Color(0x40B30000); // 25% Red
  static const Color messageReceived = Color(0x14FFFFFF); // 8% White

  static const Color messageSentTime = Color(0xFFA1AAB7);
  static const Color messageReceivedTime = Color(0xFFA1AAB7);

  // Status colors
  static const Color online = Color(0xFF4ADE80);
  static const Color offline = Color(0xFF64748B);
  static const Color away = Color(0xFFFBBF24);
  static const Color busy = Color(0xFFF87171);
}
