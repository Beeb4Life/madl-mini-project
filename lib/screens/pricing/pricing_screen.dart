import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/petsync_logo.dart';
import '../../widgets/app_snackbar.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isPro = false;
  String _selectedTier = 'annual'; // 'monthly', 'annual', 'lifetime'
  bool _isLoading = true;
  bool _showBusinessModel = false;

  @override
  void initState() {
    super.initState();
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    setState(() => _isLoading = true);
    final pro = await DatabaseHelper.instance.isProUser();
    final tier = await DatabaseHelper.instance.getProTier();
    setState(() {
      _isPro = pro;
      _selectedTier = tier;
      _isLoading = false;
    });
  }

  Future<void> _activatePro(String tier) async {
    await DatabaseHelper.instance.setProUser(true, tier: tier);
    setState(() {
      _isPro = true;
      _selectedTier = tier;
    });
    if (mounted) {
      AppSnackBar.show(
        context,
        'PETSYNC PRO ACTIVATED! All premium features unlocked.',
      );
    }
  }

  Future<void> _downgradeFree() async {
    await DatabaseHelper.instance.setProUser(false);
    setState(() {
      _isPro = false;
    });
    if (mounted) {
      AppSnackBar.show(context, 'Reset to Free Starter Tier.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const PetSyncLogo(size: 24, showText: true),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isPro ? AppColors.accentRed : AppColors.surfElevated(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPro ? AppColors.accentRed : AppColors.brd(context),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _isPro ? Colors.white : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  _isPro ? 'PRO ACTIVE' : 'FREE TIER',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Hero Header
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfElevated(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.brd(context)),
                          ),
                          child: const Text(
                            '// BUSINESS MODEL & PLANS',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'UPGRADE TO PETSYNC PRO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Empower your pets with AI symptom triage, unlimited pet profiles, and instant 24/7 emergency veterinary access.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Active Status Box
                  NothingCard(
                    hasRedDot: _isPro,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          _isPro ? Icons.verified_user : Icons.shield_outlined,
                          size: 32,
                          color: _isPro ? AppColors.accentRed : AppColors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isPro
                                    ? 'MEMBERSHIP: PRO (${_selectedTier.toUpperCase()})'
                                    : 'CURRENT PLAN: FREE STARTER',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isPro
                                    ? 'All Pro features, AI clinical triage & priority vet lines are unlocked.'
                                    : 'Limited to 2 pet profiles and basic care task tracking.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isPro)
                          TextButton(
                            onPressed: _downgradeFree,
                            child: const Text(
                              'RESET',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Plan Selection Cards
                  _buildPlanCard(
                    tierKey: 'annual',
                    title: 'ANNUAL PRO MEMBERSHIP',
                    price: '₹1,499 / year',
                    subprice: 'Just ₹124 / month (Save 40%)',
                    badge: 'MOST POPULAR',
                    isBestValue: true,
                  ),

                  const SizedBox(height: 12),

                  _buildPlanCard(
                    tierKey: 'monthly',
                    title: 'MONTHLY FLEXIBLE',
                    price: '₹199 / month',
                    subprice: 'Cancel anytime. Billed monthly.',
                    badge: 'MONTH-TO-MONTH',
                    isBestValue: false,
                  ),

                  const SizedBox(height: 12),

                  _buildPlanCard(
                    tierKey: 'lifetime',
                    title: 'LIFETIME ACCESS',
                    price: '₹2,999 once',
                    subprice: 'Pay once, keep forever for all your pets.',
                    badge: 'ONE-TIME',
                    isBestValue: false,
                  ),

                  const SizedBox(height: 28),

                  // Feature Matrix Comparison Table
                  const Text(
                    '// PLAN FEATURE BREAKDOWN',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),

                  NothingCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        _buildFeatureRow('Registered Pet Profiles', '2 Pets', 'UNLIMITED', true),
                        const Divider(),
                        _buildFeatureRow('SyncAI Health & Symptom Triage', 'Basic', 'UNLIMITED 24/7', true),
                        const Divider(),
                        _buildFeatureRow('24/7 Emergency Vet Hotline', '❌', 'INSTANT CALL', true),
                        const Divider(),
                        _buildFeatureRow('PDF Health & Vaccination Passport', '❌', 'EXPORTABLE', true),
                        const Divider(),
                        _buildFeatureRow('Local Offline Privacy Guarantee', '100% Offline', '100% Offline', false),
                        const Divider(),
                        _buildFeatureRow('Priority Medical Advice Checklists', '❌', 'INCLUDED', true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Business Model Canvas & Monetization Architecture (for Academic/Investor Review)
                  NothingCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => _showBusinessModel = !_showBusinessModel);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.analytics_outlined, size: 20, color: AppColors.accentRed),
                                  SizedBox(width: 8),
                                  Text(
                                    'BUSINESS MODEL & SAAS ECONOMICS',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _showBusinessModel ? Icons.expand_less : Icons.expand_more,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        if (_showBusinessModel) ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 10),
                          _buildBusinessPillar(
                            title: '1. FREEMIUM SUBSCRIPTION ENGINE',
                            description:
                                'Free core tier ensures viral adoption and retention. Premium features (Unlimited pets, SyncAI diagnostics, PDF clinical records) convert at an estimated 6-8% rate.',
                          ),
                          const SizedBox(height: 12),
                          _buildBusinessPillar(
                            title: '2. CERTIFIED VET DIRECTORY & REFERRALS',
                            description:
                                'Partner veterinary clinics and 24/7 animal hospitals pay a monthly listing fee or per-triage booking commission for emergency patient referrals.',
                          ),
                          const SizedBox(height: 12),
                          _buildBusinessPillar(
                            title: '3. UNIT ECONOMICS & TARGET METRICS',
                            description:
                                '• Customer Acquisition Cost (CAC): ₹350 (~\$4.20)\n• Annual Customer Lifetime Value (LTV): ₹2,800 (~\$33.60)\n• LTV:CAC Ratio: 8.0x\n• Projected Payback Period: 2.3 months\n• Monthly Churn Target: < 2.5%',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String tierKey,
    required String title,
    required String price,
    required String subprice,
    required String badge,
    required bool isBestValue,
  }) {
    final isCurrent = _isPro && _selectedTier == tierKey;

    return NothingCard(
      padding: const EdgeInsets.all(16),
      borderColor: isCurrent
          ? AppColors.accentRed
          : isBestValue
              ? Colors.white
              : AppColors.brd(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBestValue ? AppColors.accentRed : AppColors.surfElevated(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isCurrent)
                const Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.accentRed),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subprice,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          NothingButton(
            label: isCurrent ? 'CURRENT ACTIVE PLAN' : 'ACTIVATE $badge (SIMULATE)',
            height: 40,
            isExpanded: true,
            type: isCurrent ? NothingButtonType.secondary : NothingButtonType.primary,
            onPressed: () => _activatePro(tierKey),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String freeVal, String proVal, bool proHighlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeVal,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              proVal,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: proHighlight ? Colors.white : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessPillar({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
