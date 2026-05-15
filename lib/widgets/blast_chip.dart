import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

class BlastChip extends StatelessWidget {
  const BlastChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
  });

  final Widget label;
  final bool selected;
  final void Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      labelStyle: TextStyle(color: selected ? null : context.color.onSurface),
      label: label,
      selected: selected,
      onSelected: onSelected,
    );
  }
}
