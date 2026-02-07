import 'package:flutter/material.dart';
import '../services/LocalizationProvider.dart';

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({super.key});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> {
  // Track which FAQ item is expanded (only one at a time)
  int? _expandedIndex;

  // FAQ items - add more here easily!
  List<FAQItem> _getFAQItems() {
    return [
      FAQItem(
        questionKey: 'faq_brush_teeth_q',
        answerKey: 'faq_brush_teeth_a',
        icon: Icons.brush,
        color: const Color(0xFF7DD3C0),
      ),
      FAQItem(
        questionKey: 'faq_tooth_hurts_q',
        answerKey: 'faq_tooth_hurts_a',
        icon: Icons.healing,
        color: const Color(0xFFFF8B94),
      ),
      FAQItem(
        questionKey: 'faq_floss_q',
        answerKey: 'faq_floss_a',
        icon: Icons.medical_services,
        color: const Color(0xFFA8E6CF),
      ),
      // Add more FAQ items here in the future
    ];
  }

  @override
  Widget build(BuildContext context) {
    final faqItems = _getFAQItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('instructions'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7DD3C0).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.question_answer,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('dental_care_tips'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('tap_to_expand'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Items
            ...List.generate(
              faqItems.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFAQCard(
                  faqItems[index],
                  index,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Footer tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF7DD3C0).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFFB74D),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('more_questions_contact'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem item, int index) {
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? item.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? item.color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isExpanded ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Question header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Question text
                  Expanded(
                    child: Text(
                      context.tr(item.questionKey),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isExpanded ? item.color : const Color(0xFF333333),
                      ),
                    ),
                  ),
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: item.color,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Answer (expandable)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(item.answerKey),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

// FAQ Item model
class FAQItem {
  final String questionKey;
  final String answerKey;
  final IconData icon;
  final Color color;

  FAQItem({
    required this.questionKey,
    required this.answerKey,
    required this.icon,
    required this.color,
  });
}