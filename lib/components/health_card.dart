import 'package:flutter/material.dart';

class HealthCard extends StatelessWidget {
  final String title;
  final String content;

  const HealthCard({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(
          color: Colors.red,
          width: 1.0,
        ),
      ),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8.0,
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  color: Colors.red,
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.red),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}