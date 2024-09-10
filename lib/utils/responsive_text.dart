import 'package:flutter/material.dart';

class ResponsiveText extends StatefulWidget {
  final String text;
  final double maxFontSize;
  final double minFontSize;
  final int maxLines;
  final TextStyle? style;
  final TextAlign textAlign;

  ResponsiveText({
    required this.text,
    required this.maxFontSize,
    required this.minFontSize,
    this.maxLines = 1,
    this.style,
    this.textAlign = TextAlign.start,
  });

  @override
  ResponsiveTextState createState() => ResponsiveTextState();
}

class ResponsiveTextState extends State<ResponsiveText> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = widget.maxFontSize;
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
          textAlign: widget.textAlign,
        );

        do {
          final effectiveTextStyle = (widget.style ?? TextStyle()).copyWith(fontSize: fontSize);
          textPainter.text = TextSpan(text: widget.text, style: effectiveTextStyle);
          textPainter.layout(maxWidth: constraints.maxWidth);

          if (textPainter.didExceedMaxLines) {
            fontSize -= 1;
          } else {
            break;
          }
        } while (fontSize > widget.minFontSize);

        return Text(
          widget.text,
          style: (widget.style ?? TextStyle()).copyWith(fontSize: fontSize),
          maxLines: widget.maxLines,
          textAlign: widget.textAlign,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
