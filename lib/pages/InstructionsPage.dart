import 'package:flutter/material.dart';
import '../services/LocalizationProvider.dart';

class InstructionsPage extends StatefulWidget {
  const InstructionsPage({super.key});

  @override
  State<InstructionsPage> createState() => _InstructionsPageState();
}

class _InstructionsPageState extends State<InstructionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('instructions_and_tips'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            height: 1.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 18,
            height: 1.2,
          ),
          tabs: [
            Tab(
              child: Text(
                context.tr('before_treatment'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            Tab(
              child: Text(
                context.tr('after_treatment'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            Tab(
              child: Text(
                context.tr('faq'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
            Tab(
              child: Text(
                context.tr('videos'),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBeforeTreatment(),
          _buildAfterTreatment(),
          _buildFAQ(),
          _buildVideos(),
        ],
      ),
    );
  }

  Widget _buildBeforeTreatment() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildSmallCard(
          icon: Icons.clean_hands,
          title: context.tr('personal_hygiene'),
          color: const Color(0xFF7DD3C0),
          items: [
            context.tr('brush_before_treatment'),
            context.tr('floss_before_treatment'),
            context.tr('rinse_mouthwash'),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallCard(
          icon: Icons.restaurant,
          title: context.tr('food_and_drink'),
          color: const Color(0xFFFF8B94),
          items: [
            context.tr('light_meal_before'),
            context.tr('avoid_alcohol_24h'),
            context.tr('stay_hydrated'),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallCard(
          icon: Icons.psychology,
          title: context.tr('emotional_preparation'),
          color: const Color(0xFF9C27B0),
          items: [
            context.tr('share_concerns_doctor'),
            context.tr('ask_questions'),
            context.tr('relax_breathe'),
          ],
        ),
      ],
    );
  }

  Widget _buildAfterTreatment() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildSmallCard(
          icon: Icons.health_and_safety,
          title: context.tr('filling_cavity'),
          color: const Color(0xFF9C27B0),
          items: [
            context.tr('avoid_eating_2h'),
            context.tr('no_hard_foods_24h'),
            context.tr('gentle_brushing'),
            context.tr('pain_normal_24h'),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallCard(
          icon: Icons.medical_information,
          title: context.tr('root_canal'),
          color: const Color(0xFFFF8B94),
          items: [
            context.tr('take_prescribed_meds'),
            context.tr('avoid_chewing_side'),
            context.tr('salt_water_rinse'),
            context.tr('expect_mild_discomfort'),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallCard(
          icon: Icons.remove_circle,
          title: context.tr('tooth_extraction'),
          color: const Color(0xFFFFB74D),
          items: [
            context.tr('bite_gauze_30min'),
            context.tr('no_smoking_72h'),
            context.tr('soft_foods_only'),
            context.tr('avoid_straw'),
            context.tr('ice_pack_swelling'),
          ],
        ),
        const SizedBox(height: 12),
        _buildSmallCard(
          icon: Icons.add_circle,
          title: context.tr('dental_implant'),
          color: const Color(0xFF7DD3C0),
          items: [
            context.tr('follow_medication_plan'),
            context.tr('soft_diet_week'),
            context.tr('gentle_hygiene'),
            context.tr('avoid_exercise_24h'),
            context.tr('attend_followups'),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQ() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildFAQItem(
          question: context.tr('how_often_dental_visit'),
          answer: context.tr('twice_yearly_recommended'),
          icon: Icons.calendar_today,
          color: const Color(0xFF7DD3C0),
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          question: context.tr('is_xray_safe'),
          answer: context.tr('xray_safe_minimal_radiation'),
          icon: Icons.camera_alt,
          color: const Color(0xFF9C27B0),
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          question: context.tr('what_if_pain_after'),
          answer: context.tr('mild_pain_normal'),
          icon: Icons.healing,
          color: const Color(0xFFFF8B94),
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          question: context.tr('can_i_eat_after'),
          answer: context.tr('wait_2_hours_eating'),
          icon: Icons.restaurant,
          color: const Color(0xFFFFB74D),
        ),
        const SizedBox(height: 10),
        _buildFAQItem(
          question: context.tr('how_long_filling_last'),
          answer: context.tr('filling_lasts_years'),
          icon: Icons.timer,
          color: const Color(0xFF7DD3C0),
        ),
      ],
    );
  }

  Widget _buildVideos() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildVideoCard(
          title: context.tr('proper_brushing_technique'),
          duration: "2:30",
          description: context.tr('learn_correct_brushing'),
        ),
        const SizedBox(height: 12),
        _buildVideoCard(
          title: context.tr('flossing_tutorial'),
          duration: "1:45",
          description: context.tr('master_flossing_technique'),
        ),
        const SizedBox(height: 12),
        _buildVideoCard(
          title: context.tr('understanding_root_canal'),
          duration: "3:15",
          description: context.tr('what_happens_root_canal'),
        ),
        const SizedBox(height: 12),
        _buildVideoCard(
          title: context.tr('dental_implant_process'),
          duration: "4:00",
          description: context.tr('implant_procedure_explained'),
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard({
    required String title,
    required String duration,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFB74D).withOpacity(0.3),
                      const Color(0xFF7DD3C0).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    size: 50,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('video_feature_coming_soon')),
                          backgroundColor: const Color(0xFF7DD3C0),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(
                      context.tr('watch_video'),
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DD3C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}