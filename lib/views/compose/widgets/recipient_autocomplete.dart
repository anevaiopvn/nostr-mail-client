import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../models/contact.dart';
import '../../../services/contacts_service.dart';
import 'contact_suggestion_tile.dart';

class RecipientAutocomplete extends StatefulWidget {
  final TextEditingController textController;
  final String hintText;
  final Set<String> excludeIds;
  final void Function(Contact contact) onContactSelected;
  final Future<bool> Function(String input) onManualInput;
  final void Function(String value) onSubmitted;

  const RecipientAutocomplete({
    super.key,
    required this.textController,
    required this.hintText,
    required this.excludeIds,
    required this.onContactSelected,
    required this.onManualInput,
    required this.onSubmitted,
  });

  @override
  State<RecipientAutocomplete> createState() => _RecipientAutocompleteState();
}

class _RecipientAutocompleteState extends State<RecipientAutocomplete> {
  final _contactsService = Get.find<ContactsService>();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _tapRegionGroup = Object();
  final _textFieldKey = GlobalKey();
  Timer? _debounceTimer;
  List<Contact> _suggestions = [];
  int _highlightedIndex = -1;
  bool _isSearching = false;
  String _lastQuery = '';
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hideOverlay();
    widget.textController.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTapOutside() {
    _hideOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay(context));
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _onTextChanged() {
    final text = widget.textController.text;
    final trimmedText = text.trim();

    // Auto-detect complete bech32 formats (npub, nprofile, naddr)
    if (trimmedText.startsWith('npub1') ||
        trimmedText.startsWith('nprofile1') ||
        trimmedText.startsWith('naddr1')) {
      String? prefix;
      if (trimmedText.startsWith('npub1')) {
        prefix = 'npub1';
      } else if (trimmedText.startsWith('nprofile1')) {
        prefix = 'nprofile1';
      } else if (trimmedText.startsWith('naddr1')) {
        prefix = 'naddr1';
      }

      if (prefix != null) {
        final bech32Part = trimmedText.split('@').first;
        // npub1 = 5 chars + 58 chars = 63 total
        // nprofile1 = 9 chars + ~50-60 chars
        // naddr1 = 6 chars + variable
        final minLength = prefix == 'npub1'
            ? 63
            : prefix == 'nprofile1'
            ? 59
            : 56;
        if (bech32Part.length >= minLength) {
          // Valid bech32 format, add recipient
          widget.onManualInput(trimmedText).then((added) {
            if (added) {
              widget.textController.clear();
              _hideOverlay();
              setState(() {
                _suggestions = [];
              });
            }
          });
          return;
        }
      }
    }

    // Auto-detect hex pubkey (64 hex characters)
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(trimmedText)) {
      widget.onManualInput(trimmedText).then((added) {
        if (added) {
          widget.textController.clear();
          _hideOverlay();
          setState(() {
            _suggestions = [];
          });
        }
      });
      return;
    }

    // Check for space or comma to add recipient
    if (text.endsWith(' ') || text.endsWith(',')) {
      final input = text.substring(0, text.length - 1).trim();
      if (input.isNotEmpty) {
        widget.onManualInput(input).then((added) {
          if (added) {
            widget.textController.clear();
            _hideOverlay();
            setState(() {
              _suggestions = [];
            });
          }
        });
        return;
      }
    }

    // Debounce search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(trimmedText);
    });
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      _hideOverlay();
      setState(() {
        _suggestions = [];
        _highlightedIndex = -1;
        _isSearching = false;
      });
      return;
    }

    _lastQuery = query;

    // Show local results immediately
    final localResults = _contactsService.search(
      query,
      excludeIds: widget.excludeIds,
    );

    setState(() {
      _suggestions = localResults;
      _highlightedIndex = -1;
      _isSearching = query.contains('@');
    });

    if (localResults.isNotEmpty || query.contains('@')) {
      _showOverlay();
      _updateOverlay();
    } else {
      _hideOverlay();
    }

    // If looks like NIP-05, do async search
    if (query.contains('@')) {
      final asyncResults = await _contactsService.searchAsync(
        query,
        excludeIds: widget.excludeIds,
      );

      // Only update if query hasn't changed
      if (_lastQuery == query && mounted) {
        setState(() {
          _suggestions = asyncResults;
          _highlightedIndex = -1;
          _isSearching = false;
        });

        if (asyncResults.isNotEmpty) {
          _showOverlay();
          _updateOverlay();
        } else {
          _hideOverlay();
        }
      }
    }
  }

  void _selectContact(Contact contact) {
    widget.onContactSelected(contact);
    widget.textController.clear();
    _hideOverlay();
    setState(() {
      _suggestions = [];
      _highlightedIndex = -1;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_overlayEntry == null || _suggestions.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _highlightedIndex = (_highlightedIndex + 1) % _suggestions.length;
      });
      _updateOverlay();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _highlightedIndex =
            (_highlightedIndex - 1 + _suggestions.length) % _suggestions.length;
      });
      _updateOverlay();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      if (_highlightedIndex >= 0 && _highlightedIndex < _suggestions.length) {
        _selectContact(_suggestions[_highlightedIndex]);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _hideOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroup,
      onTapOutside: (_) => _onTapOutside(),
      child: Focus(
        onKeyEvent: _handleKeyEvent,
        child: CompositedTransformTarget(
          key: _textFieldKey,
          link: _layerLink,
          child: TextField(
            controller: widget.textController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (value) async {
              if (_highlightedIndex >= 0 &&
                  _highlightedIndex < _suggestions.length &&
                  _overlayEntry != null) {
                _selectContact(_suggestions[_highlightedIndex]);
              } else {
                // Try to add recipient
                final added = await widget.onManualInput(value);
                // Only clear if recipient was added (i.e., input was valid)
                if (added) {
                  widget.textController.clear();
                  _hideOverlay();
                  setState(() {
                    _suggestions = [];
                  });
                }
                // If input is still there, it was invalid, keep it visible
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 350;

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 40),
        child: TapRegion(
          groupId: _tapRegionGroup,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: colorScheme.surface,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l.composeResolvingNip05,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_suggestions.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return ContactSuggestionTile(
                              contact: _suggestions[index],
                              isHighlighted: index == _highlightedIndex,
                              onTap: () => _selectContact(_suggestions[index]),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
