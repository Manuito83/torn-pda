import 'package:flutter/material.dart';

class ResponsiveText extends StatefulWidget {
  final String text;
  final double maxFontSize;
  final double minFontSize;
  final int maxLines;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool avoidWordBreak;

  ResponsiveText({
    required this.text,
    required this.maxFontSize,
    required this.minFontSize,
    this.maxLines = 1,
    this.style,
    this.textAlign = TextAlign.start,
    this.avoidWordBreak = false,
  });

  @override
  ResponsiveTextState createState() => ResponsiveTextState();
}

class ResponsiveTextState extends State<ResponsiveText> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Measure with the same style and scale that the Text below will render with
        final baseStyle = DefaultTextStyle.of(context).style.merge(widget.style);
        final textScaler = MediaQuery.textScalerOf(context);

        double fontSize = widget.maxFontSize;
        final textPainter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
          textAlign: widget.textAlign,
          textScaler: textScaler,
        );
        final wordPainter = TextPainter(textDirection: TextDirection.ltr, maxLines: 1, textScaler: textScaler);
        final words = widget.avoidWordBreak
            ? widget.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList()
            : const <String>[];

        do {
          final effectiveTextStyle = baseStyle.copyWith(fontSize: fontSize);
          textPainter.text = TextSpan(text: widget.text, style: effectiveTextStyle);
          textPainter.layout(maxWidth: constraints.maxWidth);

          bool wordBroken = false;
          for (final word in words) {
            wordPainter.text = TextSpan(text: word, style: effectiveTextStyle);
            wordPainter.layout(maxWidth: constraints.maxWidth);
            if (wordPainter.didExceedMaxLines) {
              wordBroken = true;
              break;
            }
          }

          if (textPainter.didExceedMaxLines || wordBroken) {
            fontSize -= 1;
          } else {
            break;
          }
        } while (fontSize > widget.minFontSize);

        textPainter.dispose();
        wordPainter.dispose();

        return Text(
          widget.text,
          style: baseStyle.copyWith(fontSize: fontSize),
          maxLines: widget.maxLines,
          textAlign: widget.textAlign,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
