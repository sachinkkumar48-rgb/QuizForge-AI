import 'package:flutter/material.dart';
import '../plugins/plugins.dart';

/// Page for exploring, enabling/disabling, and managing QuizForge plugin modules.
class ModuleExplorerPage extends StatefulWidget {
  const ModuleExplorerPage({super.key});

  @override
  State<ModuleExplorerPage> createState() => _ModuleExplorerPageState();
}

class _ModuleExplorerPageState extends State<ModuleExplorerPage> {
  final PluginRegistry _registry = PluginRegistry();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _registry,
      builder: (context, _) {
        final allModules = _registry.registeredModules;
        final categories = [
          'All',
          ...{for (var m in allModules) m.category}
        ];

        final filteredModules = _selectedCategory == 'All'
            ? allModules
            : allModules.where((m) => m.category == _selectedCategory).toList();

        final activeModule = _registry.activeModule;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Plugin & Module Hub'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Plugin System Info',
                onPressed: () => _showSystemInfo(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (activeModule != null)
                Container(
                  color: activeModule.themeColor.withAlpha(25),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(activeModule.icon, color: activeModule.themeColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Module',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: activeModule.themeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              activeModule.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.check_circle, size: 16),
                        label: Text('v${activeModule.version}'),
                      ),
                    ],
                  ),
                ),

              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // Module list
              Expanded(
                child: filteredModules.isEmpty
                    ? const Center(
                        child: Text('No plugin modules found.'),
                      )
                    : ListView.builder(
                        itemCount: filteredModules.length,
                        padding: const EdgeInsets.all(12.0),
                        itemBuilder: (context, index) {
                          final module = filteredModules[index];
                          final isEnabled =
                              _registry.isModuleEnabled(module.id);
                          final isActive =
                              _registry.activeModuleId == module.id;

                          return Card(
                            elevation: isActive ? 3 : 1,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isActive
                                  ? BorderSide(
                                      color: module.themeColor, width: 2)
                                  : BorderSide.none,
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    module.themeColor.withAlpha(40),
                                child:
                                    Icon(module.icon, color: module.themeColor),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      module.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: module.themeColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${module.category} • ${module.importer.supportedFormat}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(module.description),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Switch(
                                            value: isEnabled,
                                            onChanged: (val) async {
                                              if (val) {
                                                await _registry
                                                    .enableModule(module.id);
                                              } else {
                                                await _registry
                                                    .disableModule(module.id);
                                              }
                                            },
                                          ),
                                          Text(isEnabled
                                              ? 'Enabled'
                                              : 'Disabled'),
                                          const Spacer(),
                                          if (isEnabled && !isActive)
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                _registry
                                                    .setActiveModule(module.id);
                                              },
                                              icon: const Icon(Icons.star,
                                                  size: 18),
                                              label: const Text('Set Active'),
                                            ),
                                          if (isEnabled)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.dashboard_outlined),
                                              tooltip: 'Open Dashboard',
                                              onPressed: () {
                                                _showModuleDashboard(
                                                    context, module);
                                              },
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modular Plugin System'),
        content: const Text(
          'QuizForge AI architecture allows dynamically registering new modules (UPSC, BPSC, SSC, EPFO, NDA, CDS, CAPF, Current Affairs, Vocabulary, Essay) with 5 contracts:\n\n'
          '1. Module Interface\n'
          '2. Repository Interface\n'
          '3. UI Interface\n'
          '4. Importer Interface\n'
          '5. Analytics Interface\n\n'
          'Core engine remains completely generic.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showModuleDashboard(BuildContext context, QuizModule module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            module.ui.buildDashboard(context),
            const SizedBox(height: 12),
            module.ui.buildAnalyticsView(context),
            const SizedBox(height: 12),
            module.ui.buildImporterView(context),
          ],
        ),
      ),
    );
  }
}
