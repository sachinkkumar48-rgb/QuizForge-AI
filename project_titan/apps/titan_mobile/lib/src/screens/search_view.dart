import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_search/titan_search.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TitanSearchBar(
            controller: _controller,
            onChanged: (q) {},
            onSubmitted: (q) {},
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: SearchEmptyState(),
          ),
        ],
      ),
    );
  }
}
