import 'package:flutter/material.dart';
import '../models/section_model.dart';

/// Modern Duolingo-style section card with full-width layout
/// Features:
/// - Large horizontal card design
/// - Mascot image on the right side
/// - Section title and status on the left
/// - Call-to-action button (Continue/Locked)
/// - Grayscale styling for locked sections
/// - Responsive design for mobile and desktop
class SectionCard extends StatefulWidget {
  final SectionModel section;
  final VoidCallback? onTap;
  final Function(UnitModel)? onUnitTap;

  const SectionCard({
    super.key,
    required this.section,
    this.onTap,
    this.onUnitTap,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildCard(context, isMobile),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 280 : 280, // Keep consistent height
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 0,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        // Dynamic background color based on section status
        color: widget.section.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          if (_isHovered && widget.section.isUnlocked)
            BoxShadow(
              color: widget.section.cardBackgroundColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.section.isUnlocked ? widget.onTap : _showLockedMessage,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24), // Reduced mobile padding from 20 to 16
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  /// Mobile layout: Image on top, content below - overflow safe
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top: Mascot image (takes available space)
        Expanded(
          child: Center(
            child: _buildMascotImage(isMobile: true),
          ),
        ),
        
        // Bottom: Content row with title/status on left, button on right (minimal space)
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left side: Title and status
            Expanded(
              child: _buildTitleAndStatus(isMobile: true),
            ),
            
            const SizedBox(width: 8),
            
            // Right side: Action button (dynamic size based on button type)
            LayoutBuilder(
              builder: (context, constraints) {
                final section = widget.section;
                final buttonWidth = section.isUnlocked ? 120.0 : 80.0;
                return SizedBox(
                  width: buttonWidth,
                  child: _buildActionButton(isMobile: true),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Desktop layout: Side by side (original layout)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side: Text content and button
        Expanded(
          flex: 2,
          child: _buildTextContent(isMobile: false),
        ),
        
        // Right side: Mascot image
        Expanded(
          flex: 1,
          child: _buildMascotImage(isMobile: false),
        ),
      ],
    );
  }

  /// Left side content: title, status, and action button (for desktop)
  Widget _buildTextContent({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Section title and status
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lock icon for locked sections
            if (!widget.section.isUnlocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  Icons.lock,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ),
            
            // Section title
            Text(
              'Section ${widget.section.orderIndex}: ${widget.section.name}',
              style: TextStyle(
                fontSize: isMobile ? 24 : 21, // Decreased desktop from 28 to 21 (25% reduction)
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8), // Increased spacing
            
            // Status label (IN PROGRESS!, LOCKED, etc.)
            Text(
              widget.section.statusText,
              style: TextStyle(
                fontSize: isMobile ? 16 : 13.5, // Decreased desktop from 18 to 13.5 (25% reduction)
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        
        // Action button
        _buildActionButton(isMobile: isMobile),
      ],
    );
  }

  /// Action button (Continue or Locked)
  Widget _buildActionButton({bool isMobile = false}) {
    final isLocked = !widget.section.isUnlocked;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile 
          ? (isLocked ? 12 : 18) 
          : (isLocked ? 20 : 30), // Desktop CONTINUE: 50% bigger (20 -> 30)
        vertical: isMobile 
          ? (isLocked ? 8 : 12) 
          : (isLocked ? 12 : 18), // Desktop CONTINUE: 50% bigger (12 -> 18)
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Less rounded (was 25)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 3), // Bottom shadow
          ),
        ],
      ),
      child: FittedBox( // Ensure text fits in available space
        child: Text(
          isLocked ? 'LOCKED' : 'CONTINUE',
          style: TextStyle(
            fontSize: isMobile 
              ? (isLocked ? 10 : 15) 
              : (isLocked ? 10.5 : 15.75), // Desktop CONTINUE: 50% bigger (10.5 -> 15.75)
            fontWeight: FontWeight.bold,
            color: isLocked 
              ? Colors.grey[600] 
              : widget.section.cardBackgroundColor,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  /// Right side: Mascot image with grayscale effect for locked sections
  Widget _buildMascotImage({bool isMobile = false}) {
    if (widget.section.iconPath == null) {
      return _buildFallbackIcon(isMobile: isMobile);
    }

    Widget imageWidget;
    
    if (isMobile) {
      // Mobile: Use available space efficiently - increased by 50%
      imageWidget = LayoutBuilder(
        builder: (context, constraints) {
          final size = (constraints.maxWidth * 0.75).clamp(90.0, 150.0); // Increased from 0.6 and 60-100 to 0.75 and 90-150
          return Container(
            width: size,
            height: size,
            child: Image.asset(
              widget.section.iconPath!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isMobile: isMobile),
            ),
          );
        },
      );
    } else {
      // Desktop: Fixed constraints
      imageWidget = Container(
        constraints: const BoxConstraints(
          minWidth: 80,
          minHeight: 80,
          maxWidth: 140,
          maxHeight: 140,
        ),
        child: Image.asset(
          widget.section.iconPath!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isMobile: isMobile),
        ),
      );
    }

    // Apply grayscale effect for locked sections
    if (!widget.section.isUnlocked) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0, // Red channel
          0.2126, 0.7152, 0.0722, 0, 0, // Green channel  
          0.2126, 0.7152, 0.0722, 0, 0, // Blue channel
          0,      0,      0,      1, 0, // Alpha channel
        ]),
        child: Opacity(
          opacity: 0.6,
          child: imageWidget,
        ),
      );
    }

    return Container(
      alignment: isMobile ? Alignment.center : Alignment.centerRight,
      child: imageWidget,
    );
  }

  /// Fallback icon when image is not available
  Widget _buildFallbackIcon({bool isMobile = false}) {
    double size = isMobile ? 120 : 90; // increased by 50% from 80 : 60
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.star,
        color: Colors.white.withOpacity(0.7),
        size: size * 0.5,
      ),
    );
  }

  /// Title and status for mobile layout (left bottom)
  Widget _buildTitleAndStatus({bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock icon for locked sections
        if (!widget.section.isUnlocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Icon(
              Icons.lock,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
          ),
        
        // Section title
        Text(
          'Section ${widget.section.orderIndex}: ${widget.section.name}',
          style: TextStyle(
            fontSize: isMobile ? 18 : 18, // Decreased desktop from 24 to 18 (25% reduction)
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Status label (IN PROGRESS!, LOCKED, etc.)
        Text(
          widget.section.statusText,
          style: TextStyle(
            fontSize: isMobile ? 14 : 12, // Decreased desktop from 16 to 12 (25% reduction)
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.section.name} is locked! Complete previous sections first.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Handle hover effects (desktop only)
  void _onHover(bool isHovered) {
    if (!widget.section.isUnlocked) return;
    
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
