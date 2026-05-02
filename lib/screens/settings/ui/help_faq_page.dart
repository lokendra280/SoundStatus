import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Help & FAQ"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Frequently Asked Questions",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          _faqItem(
            context,
            "What is SoundStatus?",
            "SoundStatus is a meme soundboard app to play and share funny sounds instantly.",
          ),

          _faqItem(
            context,
            "How do I use meme sounds?",
            "Browse sounds, tap to play, and use the share button to send to friends.",
          ),

          _faqItem(
            context,
            "How can I share sounds?",
            "Tap the share icon and choose apps like WhatsApp, Messenger, or Telegram.",
          ),

          _faqItem(
            context,
            "How do I find specific sounds?",
            "Use the search bar and type keywords like 'funny', 'viral', or meme names.",
          ),

          _faqItem(
            context,
            "Can I save favorite sounds?",
            "Yes! Tap the ❤️ icon to save sounds in your favorites list.",
          ),

          _faqItem(
            context,
            "How to enable Dark Mode?",
            "Go to Settings and toggle Dark Mode.",
          ),

          _faqItem(
            context,
            "Why is sound not playing?",
            "Check volume, permissions, and internet connection.",
          ),

          _faqItem(
            context,
            "App not working properly?",
            "Try restarting the app or updating to the latest version.",
          ),

          const SizedBox(height: 24),

          Text("Need Help?", style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text("Contact Support"),
              subtitle: const Text("lokendragharti3@gmail.com"),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'lokendragharti3@gmail.com',
                  query: 'subject=Support Request - SoundStatus',
                );

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open email app')),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              "Enjoy sharing meme sounds 😂",
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w200),
        ),
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(answer)),
        ],
      ),
    );
  }
}
