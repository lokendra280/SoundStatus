import 'package:flutter/material.dart';

class SmoothPageIndicator extends StatefulWidget {
  final int pageCount;
  final PageController controller;
  final Color color;
  final Color activeColor;
  final double spacing;
  final double radius;
  final double dotHeight;
  final double dotWidth;

  const SmoothPageIndicator({
    super.key,
    required this.pageCount,
    required this.controller,
    this.color = Colors.grey,
    this.activeColor = Colors.blue,
    this.spacing = 1,
    this.radius = 15,
    this.dotHeight = 8,
    this.dotWidth = 8,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SmoothPageIndicator createState() => _SmoothPageIndicator();
}

class _SmoothPageIndicator extends State<SmoothPageIndicator> {
  late int _currentPage;
  late double _dotPosition;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.controller.initialPage;
    _dotPosition = _currentPage.toDouble();
    widget.controller.addListener(() {
      setState(() {
        _dotPosition = widget.controller.page!;
        _currentPage = widget.controller.page!.round();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: widget.radius * 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.pageCount, (index) {
            double relativePosition = index - _dotPosition;

            double leftPadding = widget.radius + widget.spacing;
            double indicatorSize = widget.dotWidth + widget.spacing;
            double left = leftPadding + relativePosition * indicatorSize;

            double scaledWidth = widget.dotWidth;
            double scaledHeight = widget.dotHeight;
            if (relativePosition < -1 || relativePosition > 1) {
              scaledWidth = widget.dotWidth / 2;
              scaledHeight = widget.dotHeight / 2;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: EdgeInsets.only(left: left),
              width: scaledWidth,
              height: scaledHeight,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? widget.activeColor
                    : widget.color,
              ),
            );
          }),
        ),
      ),
    );
  }
}
