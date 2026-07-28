import 'package:flutter/material.dart';

enum DisplayLayout { mobile, tablet, desktop }

DisplayLayout getDisplayLayout(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 1024) return DisplayLayout.desktop;
  if (width >= 600) return DisplayLayout.tablet;
  return DisplayLayout.mobile;
}

class NavigationDestinationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavigationDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

class AdaptiveNavigationLayout extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestinationItem> destinations;
  final Widget body;

  const AdaptiveNavigationLayout({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });

  @override
  State<AdaptiveNavigationLayout> createState() =>
      _AdaptiveNavigationLayoutState();
}

class _AdaptiveNavigationLayoutState extends State<AdaptiveNavigationLayout> {
  double _sidebarWidth = 240.0;
  bool _isSidebarVisible = true;

  @override
  Widget build(BuildContext context) {
    final layout = getDisplayLayout(context);

    if (layout == DisplayLayout.mobile) {
      return Scaffold(
        body: widget.body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: widget.destinations
              .map((d) => NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label,
                  ))
              .toList(),
        ),
      );
    }

    if (layout == DisplayLayout.tablet) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: widget.currentIndex,
            onDestinationSelected: widget.onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            destinations: widget.destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.body),
        ],
      );
    }

    // Desktop: Rail + Resizable Sidebar + Body
    return Row(
      children: [
        NavigationRail(
          selectedIndex: widget.currentIndex,
          onDestinationSelected: widget.onDestinationSelected,
          extended: false,
          destinations: widget.destinations
              .map((d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ))
              .toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        if (_isSidebarVisible) ...[
          SizedBox(
            width: _sidebarWidth,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quick Navigation',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() => _isSidebarVisible = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.destinations.length,
                      itemBuilder: (context, index) {
                        final item = widget.destinations[index];
                        final isSelected = index == widget.currentIndex;
                        return ListTile(
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => widget.onDestinationSelected(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sidebarWidth =
                    (_sidebarWidth + details.delta.dx).clamp(160.0, 400.0);
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: Container(
                width: 4,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() => _isSidebarVisible = true);
            },
          ),
        ],
        Expanded(child: widget.body),
      ],
    );
  }
}
