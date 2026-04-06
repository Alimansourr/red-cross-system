import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_input_decoration.dart';
import '../widgets/patient_label.dart';
import '../widgets/patient_section_card.dart';
import '../services/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController commentController = TextEditingController();

  String? selectedRating;
  bool _isLoading = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final comment = commentController.text.trim();

    if (selectedRating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating.'),
        ),
      );
      return;
    }

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write your feedback.'),
        ),
      );
      return;
    }

    final rating = int.tryParse(selectedRating!);
    if (rating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid rating selected.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _feedbackService.submitFeedback(
        rating: rating,
        comment: comment,
      );

      if (!mounted) return;

      setState(() {
        selectedRating = null;
      });
      commentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: patientAppBar(context, 'Feedback'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: PatientSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Feedback',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Rate the experience and leave a comment about the provided service.',
                    style: TextStyle(color: Color(0xff6b7280)),
                  ),
                  const SizedBox(height: 24),

                  const PatientLabel('Rating'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRating,
                    items: const [
                      DropdownMenuItem(value: '5', child: Text('5 - Excellent')),
                      DropdownMenuItem(value: '4', child: Text('4 - Very Good')),
                      DropdownMenuItem(value: '3', child: Text('3 - Good')),
                      DropdownMenuItem(value: '2', child: Text('2 - Fair')),
                      DropdownMenuItem(value: '1', child: Text('1 - Poor')),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                      setState(() {
                        selectedRating = value;
                      });
                    },
                    decoration: patientInputDecoration('Select rating'),
                  ),

                  const SizedBox(height: 16),
                  const PatientLabel('Comment'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 5,
                    enabled: !_isLoading,
                    decoration: patientInputDecoration(
                      'Write your feedback here',
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffef3b4c),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Submit Feedback'),
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