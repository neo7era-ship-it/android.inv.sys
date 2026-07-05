import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;

  const VoiceInputButton({super.key, required this.isListening, required this.onTap, this.size = 56, this.activeColor});

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(VoiceInputButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _controller.repeat(reverse: true);
    } else if (!widget.isListening && old.isListening) { _controller.stop(); _controller.reset(); }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.activeColor ?? AppTheme.voiceActiveColor;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final v = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isListening) ...[
                Container(width: widget.size + 24 * v, height: widget.size + 24 * v, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15 * (1 - v)))),
                Container(width: widget.size + 12 * v, height: widget.size + 12 * v, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.25 * (1 - v)))),
              ],
              Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isListening ? color : AppTheme.primaryColor,
                  boxShadow: [BoxShadow(color: (widget.isListening ? color : Colors.black).withValues(alpha: 0.2), blurRadius: widget.isListening ? 12 : 4)],
                ),
                child: Icon(widget.isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: widget.size * 0.45),
              ),
            ],
          );
        },
      ),
    );
  }
}
