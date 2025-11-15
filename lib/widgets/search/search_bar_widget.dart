import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

/// Reusable search bar widget
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onSearch;
  final Function()? onClear;
  final String? initialQuery;
  final List<String>? recentSearches;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onSearch,
    this.onClear,
    this.initialQuery,
    this.recentSearches,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _showRecentSearches = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearch('');
                      if (widget.onClear != null) {
                        widget.onClear!();
                      }
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          onChanged: (value) {
            setState(() {});
            widget.onSearch(value);
          },
          onTap: () {
            if (widget.recentSearches != null &&
                widget.recentSearches!.isNotEmpty) {
              setState(() {
                _showRecentSearches = true;
              });
            }
          },
          onSubmitted: (value) {
            widget.onSearch(value);
            setState(() {
              _showRecentSearches = false;
            });
          },
        ),
        // Recent searches dropdown
        if (_showRecentSearches &&
            widget.recentSearches != null &&
            widget.recentSearches!.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Searches',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _showRecentSearches = false;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...widget.recentSearches!.take(5).map((search) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 18),
                    title: Text(
                      search,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      _controller.text = search;
                      widget.onSearch(search);
                      setState(() {
                        _showRecentSearches = false;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
