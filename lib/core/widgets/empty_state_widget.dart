import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.grey[600]), textAlign: TextAlign.center),
          if (subtitle != null) ...[const SizedBox(height: 12), Text(subtitle!, style: TextStyle(fontSize: 16, color: Colors.grey[500]), textAlign: TextAlign.center)],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}
