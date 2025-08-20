import 'package:flutter/material.dart';
import './arabic_keyboard.dart';
import './chat_message.dart';

class ArabicKeyboardWidget extends StatefulWidget {
  final Function(String character) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback? onEnter;
  final InputState? currentInputState;
  final bool highlightNextKey;
  final bool enabled;

  const ArabicKeyboardWidget({
    Key? key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onSpace,
    this.onEnter,
    this.currentInputState,
    this.highlightNextKey = true,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ArabicKeyboardWidget> createState() => _ArabicKeyboardWidgetState();
}

class _ArabicKeyboardWidgetState extends State<ArabicKeyboardWidget> {
  bool _isShiftPressed = false;
  String? _selectedBaseKey; // For showing diacritic options
  
  Set<String> _getBaseLayoutCharacters() {
    final set = <String>{};
    for (final row in ArabicKeyboard.layout) {
      for (final ch in row) {
        set.add(ch);
      }
    }
    return set;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Diacritics popup if a base key is selected
              if (_selectedBaseKey != null && 
                  ArabicKeyboard.hasDiacritics(_selectedBaseKey!))
                _buildDiacriticsRow(_selectedBaseKey!),
              
              // Main keyboard rows
              ...ArabicKeyboard.layout.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final row = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildRowKeys(row, rowIndex),
                  ),
                );
              }),
              
              // Special keys row (Space on the left of Shift)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Space first, then Shift, then Enter, then Backspace
                    Expanded(
                      flex: 2,
                      child: _buildSpecialKey(
                        context,
                        'مسافة',
                        widget.onSpace,
                        color: _shouldHighlightSpace() ? Colors.green[300] : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildSpecialKey(
                      context,
                      'Shift',
                      () {
                        setState(() {
                          _isShiftPressed = !_isShiftPressed;
                        });
                      },
            color: _isShiftPressed
              ? Colors.blue
              : (_shouldHighlightShift() ? Colors.green[300] : null),
                    ),
                    const SizedBox(width: 4),
                    _buildSpecialKey(context, ArabicKeyboard.enter, widget.onEnter ?? () {}),
                    const SizedBox(width: 4),
                    _buildSpecialKey(context, ArabicKeyboard.backspace, widget.onBackspace,
                        color: _shouldHighlightBackspace() ? Colors.orange : null),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRowKeys(List<String> row, int rowIndex) {
    final keys = <Widget>[];
    
  // When Shift is pressed, show only keys that have a shift mapping to reduce clutter
  final baseSet = _getBaseLayoutCharacters();
  final displayRow = _isShiftPressed
    ? row
      .where((k) => ArabicKeyboard.shiftMappings.containsKey(k))
      // Hide keys whose shifted value duplicates a base layout character
      .where((k) => !baseSet.contains(ArabicKeyboard.shiftMappings[k]))
      .toList()
    : row;

  // Remove space-handling inside rows; only regular keys
  for (final key in displayRow) {
      keys.add(Expanded(child: _buildKey(context, key)));
    }
    
    return keys;
  }

  Widget _buildKey(BuildContext context, String character) {
    // Check if shift is pressed and we have a shift mapping
    String displayChar = character;
    if (_isShiftPressed && ArabicKeyboard.shiftMappings.containsKey(character)) {
      displayChar = ArabicKeyboard.shiftMappings[character]!;
    }
    
    // Ensure base and shift layouts do not duplicate: when shift is on, show only shifted symbols
    // but we still tap the displayed character.
    final shouldHighlight = _shouldHighlightKey(character) || _shouldHighlightKey(displayChar);
    final isEnabled = widget.enabled;
    final hasDiacritics = ArabicKeyboard.hasDiacritics(character);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: GestureDetector(
        onLongPress: hasDiacritics && isEnabled
            ? () {
                setState(() {
                  _selectedBaseKey = character;
                });
              }
            : null,
        child: Material(
          color: shouldHighlight 
              ? Colors.green[300] 
              : (_selectedBaseKey == character ? Colors.blue[200] : Colors.white),
          borderRadius: BorderRadius.circular(8),
          elevation: shouldHighlight ? 4 : 2,
          child: InkWell(
            onTap: isEnabled 
                ? () {
                    // Send the displayed character (handles shift variants)
                    widget.onKeyPressed(displayChar);
                    setState(() {
                      _selectedBaseKey = null;
                      if (_isShiftPressed) {
                        _isShiftPressed = false;
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              // Use responsive width by expanding in row; keep min width for tap comfort
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: shouldHighlight 
                      ? Colors.green[700]! 
                      : (_selectedBaseKey == character 
                          ? Colors.blue[400]!
                          : Colors.grey[400]!),
                  width: shouldHighlight || _selectedBaseKey == character ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayChar,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isEnabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  if (hasDiacritics)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDiacriticsRow(String baseKey) {
    final diacritics = ArabicKeyboard.getDiacritics(baseKey);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: diacritics.map((variant) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  widget.onKeyPressed(variant);
                  setState(() {
                    _selectedBaseKey = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    variant,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Removed fixed width calculation; keys are responsive using Expanded.

  Widget _buildSpecialKey(
    BuildContext context,
    String label,
    VoidCallback onPressed, {
    Color? color,
  }) {
    final isEnabled = widget.enabled;
    
  return Material(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color != null ? Colors.orange[700]! : Colors.grey[400]!,
              width: color != null ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldHighlightKey(String character) {
    if (!widget.highlightNextKey || widget.currentInputState == null) return false;
    
    final expectedInput = widget.currentInputState!.expectedInput;
    final currentLength = widget.currentInputState!.characterStates
        .where((s) => s.status != CharacterStatus.pending)
        .length;
    
    // If we've typed everything, don't highlight anything
    if (currentLength >= expectedInput.length) return false;
    
    // Get the next expected character
    final nextChar = expectedInput[currentLength];
    
    // Check if this character matches directly
    if (character == nextChar) return true;
    
    // Check if this is a base character for the expected character
    final baseChar = ArabicKeyboard.getBaseCharacter(nextChar);
    if (baseChar != null && character == baseChar) {
      return true;
    }
    
    // Check if this character could produce the expected character with shift
    if (_isShiftPressed && ArabicKeyboard.shiftMappings[character] == nextChar) {
      return true;
    }
    
    return false;
  }

  bool _shouldHighlightSpace() {
    if (!widget.highlightNextKey || widget.currentInputState == null) return false;
    final expectedInput = widget.currentInputState!.expectedInput;
    final currentLength = widget.currentInputState!.characterStates
        .where((s) => s.status != CharacterStatus.pending)
        .length;
    if (currentLength >= expectedInput.length) return false;
    return expectedInput[currentLength] == ' ';
  }

  bool _shouldHighlightBackspace() {
    if (widget.currentInputState == null) return false;
    
    // Highlight backspace if there are incorrect characters
    return widget.currentInputState!.characterStates
        .any((s) => s.status == CharacterStatus.incorrect);
  }

  bool _shouldHighlightShift() {
    if (!widget.highlightNextKey || widget.currentInputState == null) return false;
    final expectedInput = widget.currentInputState!.expectedInput;
    final currentLength = widget.currentInputState!.characterStates
        .where((s) => s.status != CharacterStatus.pending)
        .length;
    if (currentLength >= expectedInput.length) return false;
    final nextChar = expectedInput[currentLength];

    // If nextChar is produced only via shift from any base key, highlight Shift.
    // That is, it appears among shiftMappings.values, and it is not directly present in the base layout.
    final isShiftProduct = ArabicKeyboard.shiftMappings.values.contains(nextChar);
    final baseSet = _getBaseLayoutCharacters();
    final inBase = baseSet.contains(nextChar);
    return isShiftProduct && !inBase;
  }
}