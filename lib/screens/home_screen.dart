import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/care_task.dart';
import '../database/database_helper.dart';
import '../theme/app_colors.dart';
import '../widgets/nothing_card.dart';
import '../widgets/nothing_badge.dart';
import '../widgets/nothing_button.dart';
import '../widgets/section_header.dart';
import '../widgets/pet_avatar.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/petsync_logo.dart';
import 'pets/pet_form_screen.dart';
import 'pets/pet_detail_screen.dart';
import 'care/care_task_form_dialog.dart';
import 'ai/ai_assistant_screen.dart';
import 'vets/vets_screen.dart';
import 'quiz/quiz_screen.dart';
import 'pricing/pricing_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Pet> _pets = [];
  List<CareTask> _todayTasks = [];
  Map<String, int> _taskStats = {'total': 0, 'completed': 0, 'pending': 0};
  int _healthEntryCount = 0;
  bool _isPro = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final pets = await DatabaseHelper.instance.getAllPets();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final tasks = await DatabaseHelper.instance.getTasksForDate(today);
    final stats = await DatabaseHelper.instance.getTodayTaskStats();
    final healthCount = await DatabaseHelper.instance.getHealthEntryCount();
    final pro = await DatabaseHelper.instance.isProUser();

    setState(() {
      _pets = pets;
      _todayTasks = tasks;
      _taskStats = stats;
      _healthEntryCount = healthCount;
      _isPro = pro;
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(CareTask task) async {
    await DatabaseHelper.instance.toggleCareTask(task.id!, !task.isCompleted);
    _loadData();
  }

  Future<void> _addPet() async {
    if (!_isPro && _pets.length >= 2) {
      _showProLimitDialog();
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const PetFormScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showProLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.brd(context)),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_outlined, color: AppColors.accentRed, size: 22),
            SizedBox(width: 8),
            Text(
              'FREE TIER PET LIMIT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        content: const Text(
          'Free Starter tier supports up to 2 pet profiles.\n\nUpgrade to PetSync Pro for unlimited pet profiles, SyncAI emergency triage, and PDF medical record exports.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          NothingButton.secondary(
            label: 'NOT NOW',
            height: 38,
            onPressed: () => Navigator.pop(context),
          ),
          NothingButton(
            label: 'VIEW PRO PLANS',
            height: 38,
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const PricingScreen()))
                  .then((_) => _loadData());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addTask() async {
    if (_pets.isEmpty) {
      AppSnackBar.show(context, 'Please register a pet profile first.');
      return;
    }
    final created = await CareTaskFormDialog.show(context);
    if (created == true) {
      _loadData();
    }
  }

  Future<void> _loadDemoData() async {
    await DatabaseHelper.instance.seedDemoData();
    _loadData();
    if (mounted) {
      AppSnackBar.show(context, 'Demo pets and routines loaded!');
    }
  }

  String _formatTodayHeader() {
    final now = DateTime.now();
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'feeding':
        return Icons.restaurant_outlined;
      case 'walking':
        return Icons.directions_walk_outlined;
      case 'grooming':
        return Icons.brush_outlined;
      default:
        return Icons.task_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _taskStats['total'] ?? 0;
    final completed = _taskStats['completed'] ?? 0;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: PetSyncLogo(size: 24, showText: true, isPro: _isPro),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.accentRed, size: 20),
            tooltip: 'SyncAI Clinical Assistant',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
              );
            },
          ),
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PricingScreen()),
              );
              _loadData();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _isPro ? AppColors.accentRed : AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPro ? AppColors.accentRed : AppColors.brd(context),
                ),
              ),
              child: Text(
                _isPro ? 'PRO' : 'UPGRADE',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text(
                _formatTodayHeader(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.txtMut(context),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.txt(context)),
              )
            : RefreshIndicator(
                color: AppColors.txt(context),
                backgroundColor: AppColors.surf(context),
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Overview Stats Row
                    Row(
                      children: [
                        // Pets count card
                        Expanded(
                          child: NothingCard(
                            onTap: () => widget.onNavigateTab?.call(1),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PETS',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.txtMut(context),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_pets.length}',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.txt(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Tasks summary card
                        Expanded(
                          child: NothingCard(
                            onTap: () => widget.onNavigateTab?.call(2),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TODAY CARE',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.txtMut(context),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$completed / $total',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.txt(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Health logs card
                        Expanded(
                          child: NothingCard(
                            onTap: () => widget.onNavigateTab?.call(3),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HEALTH',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.txtMut(context),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_healthEntryCount',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.txt(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Progress Card for Today's Routine
                    if (total > 0)
                      NothingCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'DAILY ROUTINE PROGRESS',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.txtSec(context),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.txt(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: AppColors.surfElevated(context),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.txt(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Quick Actions Section
                    SectionHeader(
                      codePrefix: '// 01',
                      title: 'QUICK ACTIONS',
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: NothingButton(
                            label: '+ PET',
                            height: 42,
                            onPressed: _addPet,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NothingButton.secondary(
                            label: '+ TASK',
                            height: 42,
                            onPressed: _addTask,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NothingButton.secondary(
                            label: 'SYNCAI',
                            icon: Icons.auto_awesome,
                            height: 42,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NothingButton.secondary(
                            label: 'VETS',
                            icon: Icons.local_hospital_outlined,
                            height: 42,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const VetsScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Smart Tools & Services Section
                    SectionHeader(
                      codePrefix: '// 02',
                      title: 'SMART TOOLS & TRIAGE',
                      actionText: 'MORE',
                      onActionTap: () => widget.onNavigateTab?.call(4),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: NothingCard(
                            hasRedDot: true,
                            padding: const EdgeInsets.all(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                              );
                            },
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'SYNCAI',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Symptom checker & clinical first-aid triage',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NothingCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const VetsScreen()),
                              );
                            },
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.accentRed),
                                    SizedBox(width: 6),
                                    Text(
                                      'VETS NEAR ME',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '24/7 hospitals, phone dialer & maps directions',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NothingCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const QuizScreen()),
                              );
                              _loadData();
                            },
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.psychology_outlined, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'CARE QUIZ',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Test pet knowledge & daily hydration/calorie calc',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NothingCard(
                            hasRedDot: _isPro,
                            padding: const EdgeInsets.all(14),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PricingScreen()),
                              );
                              _loadData();
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on_outlined, size: 16, color: AppColors.accentRed),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isPro ? 'PRO ACTIVE' : 'PRO PLANS',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isPro
                                      ? 'Unlimited pets & premium features unlocked'
                                      : 'SaaS freemium plans & business model canvas',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Today's Care Summary Section
                    SectionHeader(
                      codePrefix: '// 03',
                      title: 'TODAY\'S CARE ROUTINE',
                      actionText: 'VIEW ALL',
                      onActionTap: () => widget.onNavigateTab?.call(2),
                    ),
                    const SizedBox(height: 6),

                    if (_todayTasks.isEmpty)
                      NothingCard(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.check_circle_outline, size: 30, color: AppColors.txtMut(context)),
                              const SizedBox(height: 10),
                              Text(
                                'NO TASKS SCHEDULED TODAY',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.txtSec(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Schedule feeding, walking, or grooming to stay on track.',
                                style: TextStyle(fontSize: 12, color: AppColors.txtMut(context)),
                                textAlign: TextAlign.center,
                              ),
                              if (_pets.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                NothingButton.secondary(
                                  label: 'ADD TASK',
                                  icon: Icons.add,
                                  height: 36,
                                  onPressed: _addTask,
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      ..._todayTasks.take(5).map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NothingCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: task.isCompleted,
                                    activeColor: AppColors.txt(context),
                                    checkColor: AppColors.bg(context),
                                    side: BorderSide(color: AppColors.brd(context), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (_) => _toggleTask(task),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: task.isCompleted ? AppColors.txtMut(context) : AppColors.txt(context),
                                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            NothingBadge(
                                              label: task.category,
                                              icon: _getCategoryIcon(task.category),
                                            ),
                                            if (task.petName != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                task.petName!,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11,
                                                  color: AppColors.txtSec(context),
                                                ),
                                              ),
                                            ],
                                            if (task.scheduledTime != null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                task.scheduledTime!,
                                                style: TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11,
                                                  color: AppColors.txtMut(context),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),

                    const SizedBox(height: 24),

                    // Pet Profiles Overview Section
                    SectionHeader(
                      codePrefix: '// 04',
                      title: 'REGISTERED PETS',
                      actionText: 'MANAGE',
                      onActionTap: () => widget.onNavigateTab?.call(1),
                    ),
                    const SizedBox(height: 6),

                    if (_pets.isEmpty)
                      NothingCard(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.pets, size: 30, color: AppColors.txtMut(context)),
                              const SizedBox(height: 10),
                              Text(
                                'NO PETS REGISTERED YET',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.txtSec(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  NothingButton(
                                    label: 'CREATE PET',
                                    icon: Icons.add,
                                    height: 38,
                                    onPressed: _addPet,
                                  ),
                                  const SizedBox(width: 10),
                                  NothingButton.secondary(
                                    label: 'LOAD DEMO',
                                    icon: Icons.auto_awesome,
                                    height: 38,
                                    onPressed: _loadDemoData,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._pets.map((pet) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: NothingCard(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PetDetailScreen(petId: pet.id!),
                                  ),
                                );
                                _loadData();
                              },
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  PetAvatar(
                                    species: pet.species,
                                    imagePath: pet.imagePath,
                                    size: 42,
                                    borderRadius: 12,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pet.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.txt(context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pet.breed != null && pet.breed!.isNotEmpty
                                              ? '${pet.species} • ${pet.breed}'
                                              : pet.species,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.txtSec(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (pet.weight != null)
                                    Text(
                                      '${pet.weight} kg',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.txtMut(context),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.chevron_right, size: 18, color: AppColors.txtMut(context)),
                                ],
                              ),
                            ),
                          )),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}
