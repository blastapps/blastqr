import 'package:blast_qr/color_scheme.dart';
import 'package:flutter/material.dart';

class BlastTextField extends StatefulWidget {
  const BlastTextField({
    super.key,
    this.obscureText = false,
    this.keyboardType,
    this.hintText,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
    this.controller,
    this.autofillHints,
    this.leading,
    this.scrollPadding,
    this.trailingHintText,
    this.minLines,
    this.maxLines = 1,
    this.style,
    this.textAlign,
  });

  final TextEditingController? controller;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final String? hintText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final EdgeInsets? scrollPadding;
  final Widget? leading;
  final String? trailingHintText;
  final int? minLines;
  final int? maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  State<BlastTextField> createState() => _BlastTextFieldState();
}

class _BlastTextFieldState extends State<BlastTextField> {
  bool _obscureTextIsVisible = false;
  bool _hasText = false;

  bool get _hasTrailingHint => widget.trailingHintText?.isNotEmpty == true;

  TextStyle? get _hintStyle => Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w400,
    color: context.color.secondary,
  );

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller?.text.isNotEmpty == true;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (text) {
        setState(() {
          _hasText = text.isNotEmpty;
        });
      },
      controller: widget.controller,
      obscureText: widget.obscureText && !_obscureTextIsVisible,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autofocus: widget.autofocus,
      scrollPadding: widget.scrollPadding ?? const EdgeInsets.all(20),
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: widget.style,
      textAlign: widget.textAlign ?? TextAlign.start,
      decoration: InputDecoration(
        contentPadding: EdgeInsetsDirectional.fromSTEB(
          widget.textAlign == TextAlign.center ? 48 : 12,
          0,
          8,
          0,
        ),
        hintText: widget.hintText,
        hintStyle: _hintStyle,
        prefixIcon: widget.leading,
        suffixIcon: ExcludeSemantics(child: _buildSuffix()),
      ),
    );
  }

  Widget? _buildSuffix() {
    if (_hasTrailingHint) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 0, 0),
        child: Text(widget.trailingHintText!, style: _hintStyle),
      );
    }
    if (!_hasText) {
      return null;
    }
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child:
          widget.obscureText
              ? IconButton(
                icon: Icon(
                  _obscureTextIsVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureTextIsVisible = !_obscureTextIsVisible;
                  });
                },
              )
              : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.controller?.clear();
                  setState(() {
                    _hasText = false;
                  });
                },
              ),
    );
  }
}
