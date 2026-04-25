import 'package:flutter/material.dart';

class OnboardPageWidget extends StatelessWidget {
  final Color color;
  final String urlImage;
  final String title;
  final String subtitle;
  const OnboardPageWidget({
    super.key,
    required this.color,
    required this.urlImage,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(urlImage, fit: BoxFit.cover, width: 200),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromRGBO(149, 150, 157, 1),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
