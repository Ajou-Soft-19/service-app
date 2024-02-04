// search_field.dart 파일
import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  final Function(String) onSubmitted;

  SearchField({required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onSubmitted,
      decoration: const InputDecoration(
        labelText: 'Search',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
