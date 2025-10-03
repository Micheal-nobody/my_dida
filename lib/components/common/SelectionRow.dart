import 'package:flutter/material.dart';

class SelectionRow extends StatelessWidget {
  const SelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            '$value >',
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.grey[500],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
