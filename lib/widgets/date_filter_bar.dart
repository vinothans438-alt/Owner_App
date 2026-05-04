import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DateFilterBar extends StatefulWidget {
  final Function(String) onFilterChanged;
  const DateFilterBar({super.key, required this.onFilterChanged});

  @override
  State<DateFilterBar> createState() => _DateFilterBarState();
}

class _DateFilterBarState extends State<DateFilterBar> {
  String _selectedFilter = 'Monthly';

  void _updateFilter(String value) {
    setState(() {
      _selectedFilter = value;
    });
    widget.onFilterChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Daily'),
          _buildFilterChip('Monthly'),
          _buildFilterChip('Yearly'),
          _buildFilterChip('Custom'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) _updateFilter(label);
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
