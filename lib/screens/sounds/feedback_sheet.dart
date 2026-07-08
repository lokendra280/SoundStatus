import 'package:flutter/material.dart';
import 'package:soundstatus/core/feedback_service.dart';
import 'package:soundstatus/core/widget/theme.dart';

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  int _rating = 0;
  final _msgCtrl = TextEditingController();
  bool _submitting = false;
  bool _hasReviewed = false; // already went to Play Store before

  @override
  void initState() {
    super.initState();
    FeedbackService.hasReviewed().then((v) {
      if (mounted) setState(() => _hasReviewed = v);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  // Show the message box when rating is low, OR whenever the user has
  // already done the Play Store review (no store handoff possible anymore).
  bool get _showMessageField => _rating > 0 && (_rating < 4 || _hasReviewed);

  // Store handoff only for high ratings from users who haven't reviewed yet.
  bool get _goesToStore => _rating >= 4 && !_hasReviewed;

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);

    try {
      if (_goesToStore) {
        // Happy first-time reviewer → save rating, hand off to Play Store
        await FeedbackService.submitFeedback(rating: _rating);
        if (mounted) Navigator.pop(context);
        await FeedbackService.requestStoreReview();
      } else {
        // Everything else → written feedback to Supabase
        await FeedbackService.submitFeedback(
          rating: _rating,
          message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanks for your feedback! 💙'),
              backgroundColor: AppColors.teal,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      // Keep the sheet above the keyboard while typing
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasReviewed ? 'Send us feedback' : 'Enjoying SoundStatus?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _hasReviewed
                  ? 'Tell us what you think — we read everything'
                  : 'Your feedback helps us improve',
              style: TextStyle(fontSize: 13, color: c.textMuted),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.yellow : c.textMuted,
                    size: 34,
                  ),
                );
              }),
            ),

            // Message field
            if (_showMessageField) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _msgCtrl,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: _rating >= 4
                      ? 'What do you love? Anything to add?'
                      : 'What can we do better?',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: c.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _rating == 0 || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_goesToStore ? 'Rate on Play Store ⭐' : 'Submit'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe later',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
