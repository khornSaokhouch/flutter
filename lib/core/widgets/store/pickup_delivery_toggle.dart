import 'package:flutter/material.dart';

class PickupDeliveryToggle extends StatelessWidget {
  final bool isPickupSelected;
  final Function(bool) onToggle;

  const PickupDeliveryToggle({super.key, required this.isPickupSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20.0)),
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          _buildToggleButton('Pickup', isPickupSelected),
          _buildToggleButton('Delivery', !isPickupSelected),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(text == 'Pickup'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 3)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.orange : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
