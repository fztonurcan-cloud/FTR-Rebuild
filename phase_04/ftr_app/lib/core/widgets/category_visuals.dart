import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CategoryVisual {
  const CategoryVisual(this.icon, this.tint);
  final IconData icon;
  final Color tint;
}

CategoryVisual categoryVisualFor(String name) {
  final value = name.toLowerCase();
  if (value.contains('temel') || value.contains('anatomi') || value.contains('fizyoloji')) {
    return const CategoryVisual(Icons.science_outlined, Color(0xFF2D7FF9));
  }
  if (value.contains('ortoped') || value.contains('spor')) {
    return const CategoryVisual(Icons.directions_run_outlined, Color(0xFFFF725E));
  }
  if (value.contains('nöro') || value.contains('norolojik')) {
    return const CategoryVisual(Icons.psychology_alt_outlined, Color(0xFF52A9A3));
  }
  if (value.contains('kardiyo') || value.contains('pulmoner')) {
    return const CategoryVisual(Icons.favorite_outline, Color(0xFFE46969));
  }
  if (value.contains('egzersiz')) {
    return const CategoryVisual(Icons.fitness_center_outlined, Color(0xFF2B95D6));
  }
  if (value.contains('değerlend') || value.contains('muayene')) {
    return const CategoryVisual(Icons.assignment_outlined, Color(0xFF3E79C5));
  }
  if (value.contains('modalite') || value.contains('fizik tedavi')) {
    return const CategoryVisual(Icons.monitor_heart_outlined, Color(0xFF259C9A));
  }
  if (value.contains('manuel')) {
    return const CategoryVisual(Icons.back_hand_outlined, Color(0xFFF18A54));
  }
  if (value.contains('ortez') || value.contains('protez')) {
    return const CategoryVisual(Icons.accessibility_new_outlined, Color(0xFF25A59A));
  }
  if (value.contains('pediatr')) {
    return const CategoryVisual(Icons.child_care_outlined, Color(0xFF56A7B1));
  }
  if (value.contains('kinezyoloji') || value.contains('biyomekanik')) {
    return const CategoryVisual(Icons.swap_horiz_rounded, Color(0xFF6A78D1));
  }
  if (value.contains('klinik') || value.contains('acil')) {
    return const CategoryVisual(Icons.medical_services_outlined, Color(0xFFDB665F));
  }
  return const CategoryVisual(Icons.menu_book_outlined, AppColors.primary600);
}
