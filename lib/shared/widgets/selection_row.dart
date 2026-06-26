import 'package:flutter/material.dart';

class SelectionRow extends StatelessWidget {
  const SelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
    this.valueColor,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? valueColor;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.orange : (Colors.grey[600]),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.orange : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            '$value >',
            style: TextStyle(
              fontSize: 16,
              color: isSelected
                  ? Colors.orange
                  : (valueColor ?? Colors.grey[500]),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}
