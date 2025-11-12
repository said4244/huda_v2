import 'package:flutter/material.dart';
import '../models/section_model.dart';

class UnitIcon extends StatefulWidget {
  final UnitModel unit;
  final bool isEnabled;
  final VoidCallback? onTap;

  const UnitIcon({
    super.key,
    required this.unit,
    required this.isEnabled,
    this.onTap,
  });

  @override
  State<UnitIcon> createState() => _UnitIconState();
}

class _UnitIconState extends State<UnitIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
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

  Color _getBackgroundColor() {
    if (!widget.isEnabled) return const Color(0xFFEEEEEE);
    
    switch (widget.unit.status) {
      case UnitStatus.completed:
        return const Color(0xFFC8E6C9);
      case UnitStatus.current:
        return const Color(0xFFFFF3C4);
      case UnitStatus.unlocked:
        return const Color(0xFFDDE5FE);
      case UnitStatus.locked:
        return const Color(0xFFEEEEEE);
    }
  }

  Color _getBorderColor() {
    if (!widget.isEnabled) return const Color(0xFFBDBDBD);
    
    switch (widget.unit.status) {
      case UnitStatus.completed:
        return const Color(0xFF81C784);
      case UnitStatus.current:
        return const Color(0xFFFFB300);
      case UnitStatus.unlocked:
        return const Color(0xFFA5B4F3);
      case UnitStatus.locked:
        return const Color(0xFFBDBDBD);
    }
  }

  Color _getTextColor() {
    if (!widget.isEnabled) return const Color(0xFF9E9E9E);
    
    switch (widget.unit.status) {
      case UnitStatus.completed:
        return const Color(0xFF2E7D32);
      case UnitStatus.current:
        return const Color(0xFF795548);
      case UnitStatus.unlocked:
        return const Color(0xFF455A64);
      case UnitStatus.locked:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !widget.isEnabled || widget.unit.status == UnitStatus.locked;
    
    return MouseRegion(
      onEnter: (_) {
        if (!isLocked) _animationController.forward();
      },
      onExit: (_) => _animationController.reverse(),
      cursor: isLocked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLocked ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getBackgroundColor(),
                border: Border.all(
                  color: _getBorderColor(),
                  width: 2,
                ),
                boxShadow: widget.unit.status == UnitStatus.current ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.3),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ] : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    widget.unit.number.toString(),
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLocked)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 20,
                        ),
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
}
