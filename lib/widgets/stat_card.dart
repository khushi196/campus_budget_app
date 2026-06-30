import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.18), AppColors.surface],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const Spacer(),
                  Icon(Icons.trending_up_rounded, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text(caption, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
