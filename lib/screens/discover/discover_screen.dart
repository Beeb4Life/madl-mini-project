import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_badge.dart';
import '../../widgets/petsync_logo.dart';
import '../ai/ai_assistant_screen.dart';
import '../vets/vets_screen.dart';
import '../quiz/quiz_screen.dart';
import '../pricing/pricing_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isPro = false;
  int _quizHighScore = 0;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final pro = await DatabaseHelper.instance.isProUser();
    final high = await DatabaseHelper.instance.getQuizHighScore();
    if (mounted) {
      setState(() {
        _isPro = pro;
        _quizHighScore = high;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const PetSyncLogo(size: 24, showText: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined, color: AppColors.accentRed),
            tooltip: 'PetSync Pro & Pricing',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PricingScreen()),
              );
              _loadState();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const Text(
                  '// SMART TOOLS & SERVICES',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 1. SyncAI Assistant Card
            _buildFeatureTile(
              context,
              tag: 'AI CLINICAL TRIAGE',
              title: 'SYNCAI ASSISTANT',
              subtitle: 'Instant symptom analysis, food toxicity check, and veterinary first-aid protocols.',
              icon: Icons.auto_awesome,
              hasRedDot: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // 2. Vets Near Me Card
            _buildFeatureTile(
              context,
              tag: 'LOCAL DIRECTORY',
              title: 'VETS & 24/7 HOSPITALS',
              subtitle: 'Emergency pet trauma centers, verified clinics, tap-to-call, and directions.',
              icon: Icons.local_hospital_outlined,
              hasRedDot: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VetsScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            // 3. Pet Care Quiz Card
            _buildFeatureTile(
              context,
              tag: _quizHighScore > 0 ? 'HIGH SCORE: $_quizHighScore' : 'INTERACTIVE TEST',
              title: 'PET UNDERSTANDING QUIZ',
              subtitle: 'Test your pet care IQ with clinical questions, body language insights, and daily needs calculator.',
              icon: Icons.psychology_outlined,
              hasRedDot: false,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
                _loadState();
              },
            ),

            const SizedBox(height: 12),

            // 4. Pricing & Business Model Card
            _buildFeatureTile(
              context,
              tag: _isPro ? 'PRO ACTIVE' : 'BUSINESS MODEL & PLANS',
              title: 'PETSYNC PRO MEMBERSHIP',
              subtitle: 'SaaS freemium tier plans, unlimited pets, unit economics, and monetization strategy.',
              icon: Icons.monetization_on_outlined,
              hasRedDot: _isPro,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PricingScreen()),
                );
                _loadState();
              },
            ),

            const SizedBox(height: 24),

            // Info Card
            NothingCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '100% OFFLINE-FIRST PRIVACY',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'All pet profiles, care logs, health journals, and local directories reside strictly on your device. Zero external cloud tracking or forced accounts.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String tag,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool hasRedDot,
    required VoidCallback onTap,
  }) {
    return NothingCard(
      hasRedDot: hasRedDot,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfElevated(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NothingBadge(label: tag, fontSize: 9),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
