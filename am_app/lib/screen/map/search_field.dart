// search_field.dart 파일
import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final Function(String) onSubmitted;
  final String label;

  SearchField({required this.onSubmitted, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }
}
