import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';

/// Module 7: Universal Search across Knowledge Objects, Evidence, Articles, Cases, Acts, etc.
class SearchScreen extends StatefulWidget {
  final EditorialStudioController controller;

  const SearchScreen({super.key, required this.controller});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'ID',
    'Title',
    'Topic',
    'Subject',
    'Evidence',
    'Article',
    'Case',
    'Act',
    'Committee',
    'Report',
    'PYQ',
    'Current Affairs',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final objects = widget.controller.objects;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Universal Knowledge Studio Search',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (val) {
              widget.controller.setSearchQuery(val);
            },
            decoration: InputDecoration(
              hintText: 'Search by ID, Title, Topic, Article (e.g. Art 21), Case (e.g. Puttaswamy), Act...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.controller.setSearchQuery('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Results List
          Expanded(
            child: objects.isEmpty
                ? const Center(child: Text('No Knowledge Objects match the search query.'))
                : ListView.separated(
                    itemCount: objects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final obj = objects[index];
                      return Card(
                        child: ListTile(
                          title: Text(obj.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${obj.id} • ${obj.subject} • ${obj.topic} • References: ${obj.references.join(", ")}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 16),
                            onPressed: () {
                              widget.controller.selectKnowledgeObject(obj);
                              widget.controller.selectTab(2); // Jump to KO Manager
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
