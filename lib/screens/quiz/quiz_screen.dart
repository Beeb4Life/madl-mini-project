import 'dart:math';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/nothing_badge.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Quiz state
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  int _score = 0;
  bool _isFinished = false;
  int _highScore = 0;

  // Calculator state
  String _calcSpecies = 'Dog';
  double _calcWeight = 12.0;
  String _calcAgeGroup = 'Adult';
  String _calcActivity = 'Moderate';

  final List<_QuizQuestion> _questions = const [
    _QuizQuestion(
      category: 'NUTRITION & TOXINS',
      question:
          'Which of the following common foods contains theobromine and is severely toxic to dogs and cats?',
      options: ['Milk Chocolate', 'Boiled Chicken Breast', 'White Rice', 'Plain Steamed Pumpkin'],
      correctIndex: 0,
      explanation:
          'Chocolate contains theobromine and caffeine (methylxanthines). Pets cannot metabolize them, leading to tachycardia, seizures, and fatal cardiac arrhythmias.',
    ),
    _QuizQuestion(
      category: 'CLINICAL SAFETY',
      question: 'Why are onions, garlic, and chives dangerous to both dogs and cats?',
      options: [
        'They cause hemolytic anemia by destroying red blood cells',
        'They only cause temporary mild bad breath',
        'They only affect pets if eaten raw with salt',
        'They stimulate excess coat growth and shedding'
      ],
      correctIndex: 0,
      explanation:
          'Allium species contain sulfur compounds that cause oxidative damage to red blood cell hemoglobin, resulting in Heinz body hemolytic anemia.',
    ),
    _QuizQuestion(
      category: 'FELINE HEALTH',
      question: 'Why should true lilies (Lilium species) NEVER be brought into a home with cats?',
      options: [
        'Even minor pollen ingestion can cause fatal acute kidney failure',
        'Lilies cause mild sneezing in older cats',
        'Lilies are completely harmless to cats',
        'Only the roots are toxic if dried and boiled'
      ],
      correctIndex: 0,
      explanation:
          'All parts of true lilies are acutely nephrotoxic to cats. Licking a single leaf or drinking water from the vase can trigger irreversible renal failure within 24-72 hours.',
    ),
    _QuizQuestion(
      category: 'BEHAVIOR & BODY LANGUAGE',
      question: 'True or False: A dog wagging its tail always means it is friendly and approachable.',
      options: [
        'False: Tail wagging indicates arousal and intensity, not necessarily happiness',
        'True: Dogs only ever wag their tail when happy',
        'True: A wagging tail is an invitation for strangers to hug them',
        'False: Dogs only wag when looking for food'
      ],
      correctIndex: 0,
      explanation:
          'Tail wagging signals emotional arousal. A stiff, high, rapid wag or low tucked wag can indicate stress, fear, territorial defensiveness, or potential bite risk.',
    ),
    _QuizQuestion(
      category: 'EMERGENCY FIRST AID',
      question: 'What is the immediate first step if your dog suffers heatstroke on a hot day?',
      options: [
        'Move to shade and apply cool/room-temperature water to paws and groin',
        'Submerge the pet in ice water and pack with ice cubes',
        'Cover them with heavy damp woolen blankets',
        'Force them to drink cold milk immediately'
      ],
      correctIndex: 0,
      explanation:
          'Cool water allows gradual evaporative cooling. Freezing ice causes peripheral vasoconstriction, trapping heat inside the internal vital organs.',
    ),
    _QuizQuestion(
      category: 'VITAL SIGNS',
      question: 'What is the normal resting respiratory rate for a healthy calm dog or cat?',
      options: [
        '15 to 30 breaths per minute',
        '60 to 90 breaths per minute',
        '5 to 10 breaths per minute',
        '100 to 140 breaths per minute'
      ],
      correctIndex: 0,
      explanation:
          'Healthy pets take 15 to 30 breaths per minute while resting. A resting rate consistently above 35-40 breaths/minute warrants urgent veterinary evaluation.',
    ),
    _QuizQuestion(
      category: 'PEDIATRICS',
      question: 'At what age should puppy and kitten core vaccination series typically begin?',
      options: [
        '6 to 8 weeks of age',
        '6 months of age',
        '1 year of age',
        'Only after all baby teeth have fallen out'
      ],
      correctIndex: 0,
      explanation:
          'Maternal immunity antibodies wane between 6 and 8 weeks, leaving young animals vulnerable to parvovirus, distemper, and feline panleukopenia.',
    ),
    _QuizQuestion(
      category: 'HYDRATION & CHECKS',
      question: 'How can you quickly check for dehydration in your pet at home?',
      options: [
        'Pinch the skin between shoulder blades (skin tent) and inspect gums',
        'Feel if their paws are warm or cold',
        'Observe if their whiskers are curled',
        'Check if their collar is tight'
      ],
      correctIndex: 0,
      explanation:
          'Well-hydrated skin snaps back instantly. Tacky or dry gums and a slow-rebounding skin fold indicate systemic dehydration.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHighScore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final high = await DatabaseHelper.instance.getQuizHighScore();
    setState(() => _highScore = high);
  }

  void _onSelectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
      await DatabaseHelper.instance.saveQuizHighScore(_score);
      _loadHighScore();
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOption = null;
      _answered = false;
      _score = 0;
      _isFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_outlined, size: 22, color: AppColors.accentRed),
            SizedBox(width: 8),
            Text(
              'PET UNDERSTANDING & CARE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'CARE IQ QUIZ'),
            Tab(text: 'DAILY NEEDS CALC'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildQuizTab(),
            _buildCalculatorTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: QUIZ
  // ==========================================
  Widget _buildQuizTab() {
    if (_isFinished) {
      final percentage = ((_score / _questions.length) * 100).toInt();
      String ratingTitle;
      String ratingDesc;
      if (percentage >= 85) {
        ratingTitle = 'MASTER PET GUARDIAN';
        ratingDesc = 'Exceptional knowledge of clinical pet safety, nutrition, and vital signs.';
      } else if (percentage >= 60) {
        ratingTitle = 'CERTIFIED COMPANION';
        ratingDesc = 'Strong core understanding. Reviewing emergency triage will make you unbeatable.';
      } else {
        ratingTitle = 'APPRENTICE PET PARENT';
        ratingDesc = 'Good start! Retake the quiz to sharpen your pet first-aid and nutrition instincts.';
      }

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfElevated(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentRed, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.workspace_premium_outlined, size: 40, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              ratingTitle,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              ratingDesc,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          NothingCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'YOUR SCORE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_score / ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: AppColors.brd(context)),
                Column(
                  children: [
                    const Text(
                      'ACCURACY',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: AppColors.brd(context)),
                Column(
                  children: [
                    const Text(
                      'HIGH SCORE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_highScore',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          NothingButton(
            label: 'RETAKE QUIZ',
            isExpanded: true,
            icon: Icons.refresh,
            onPressed: _restartQuiz,
          ),
        ],
      );
    }

    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Progress bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '// QUESTION ${_currentIndex + 1} OF ${_questions.length}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'SCORE: $_score',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.surfElevated(context),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),

        const SizedBox(height: 20),

        // Question Card
        NothingCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NothingBadge(label: q.category, fontSize: 10),
              const SizedBox(height: 12),
              Text(
                q.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Options List
        ...List.generate(q.options.length, (index) {
          final text = q.options[index];
          final isSelected = _selectedOption == index;
          final isCorrect = q.correctIndex == index;

          Color borderCol = AppColors.brd(context);
          Color bgCol = AppColors.surf(context);
          IconData? icon;

          if (_answered) {
            if (isCorrect) {
              borderCol = Colors.white;
              bgCol = AppColors.surfElevated(context);
              icon = Icons.check_circle;
            } else if (isSelected) {
              borderCol = AppColors.danger;
              bgCol = AppColors.accentRedDim;
              icon = Icons.cancel;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _onSelectOption(index),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol, width: isSelected || (_answered && isCorrect) ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfElevated(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderCol),
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 18, color: isCorrect ? Colors.white : AppColors.danger),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),

        // Vet Explanation Card after answering
        if (_answered) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfElevated(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brd(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.accentRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VETERINARY EXPLANATION',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        q.explanation,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          NothingButton(
            label: _currentIndex < _questions.length - 1 ? 'NEXT QUESTION' : 'VIEW RESULTS',
            icon: Icons.arrow_forward,
            isExpanded: true,
            onPressed: _nextQuestion,
          ),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // TAB 2: DAILY NEEDS CALCULATOR
  // ==========================================
  Widget _buildCalculatorTab() {
    // Computations
    final isDog = _calcSpecies == 'Dog';
    final weight = _calcWeight;

    // Daily Water Intake (ml): Dogs: 55ml/kg, Cats: 45ml/kg
    final waterMl = (weight * (isDog ? 55 : 45)).round();

    // Resting Energy Requirement (RER) = 70 * (weight ^ 0.75)
    final rer = 70 * pow(weight, 0.75);
    double activityMultiplier = 1.6;
    if (_calcAgeGroup == 'Puppy/Kitten') activityMultiplier = 2.5;
    if (_calcAgeGroup == 'Senior') activityMultiplier = 1.2;
    if (_calcActivity == 'Low') activityMultiplier -= 0.2;
    if (_calcActivity == 'High') activityMultiplier += 0.4;
    final dailyKcal = (rer * activityMultiplier).round();

    // Exercise Minutes
    int exerciseMins = 45;
    if (isDog) {
      if (_calcActivity == 'High') exerciseMins = 90;
      if (_calcActivity == 'Low') exerciseMins = 30;
      if (_calcAgeGroup == 'Senior') exerciseMins = 25;
    } else {
      exerciseMins = 25; // Cats: interactive play sessions
      if (_calcActivity == 'High') exerciseMins = 40;
    }

    // Sleep Hours
    String sleepHours = isDog ? '12 - 14 hrs' : '14 - 16 hrs';
    if (_calcAgeGroup == 'Puppy/Kitten') sleepHours = '18 - 20 hrs';
    if (_calcAgeGroup == 'Senior') sleepHours = '16 - 18 hrs';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '// PET DAILY NEEDS CALCULATOR',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Calculate tailored hydration, calorie targets, and exercise regimens based on species, weight, and life stage.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
        ),
        const SizedBox(height: 16),

        // Input Controls Card
        NothingCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Species Selector
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'CANINE (DOG)',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      selected: isDog,
                      selectedColor: Colors.white,
                      backgroundColor: AppColors.surfElevated(context),
                      labelStyle: TextStyle(color: isDog ? Colors.black : Colors.white),
                      onSelected: (_) => setState(() => _calcSpecies = 'Dog'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'FELINE (CAT)',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      selected: !isDog,
                      selectedColor: Colors.white,
                      backgroundColor: AppColors.surfElevated(context),
                      labelStyle: TextStyle(color: !isDog ? Colors.black : Colors.white),
                      onSelected: (_) => setState(() => _calcSpecies = 'Cat'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Weight Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BODY WEIGHT',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${_calcWeight.toStringAsFixed(1)} KG',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _calcWeight,
                min: isDog ? 1.0 : 1.0,
                max: isDog ? 60.0 : 15.0,
                divisions: isDog ? 59 : 14,
                activeColor: Colors.white,
                inactiveColor: AppColors.surfElevated(context),
                onChanged: (val) => setState(() => _calcWeight = val),
              ),

              const SizedBox(height: 12),

              // Age Category
              const Text(
                'LIFE STAGE',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['Puppy/Kitten', 'Adult', 'Senior'].map((stage) {
                  final sel = _calcAgeGroup == stage;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            stage.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        selected: sel,
                        selectedColor: Colors.white,
                        backgroundColor: AppColors.surfElevated(context),
                        onSelected: (_) => setState(() => _calcAgeGroup = stage),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Activity Level
              const Text(
                'ACTIVITY LEVEL',
                style: TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['Low', 'Moderate', 'High'].map((act) {
                  final sel = _calcActivity == act;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            act.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: sel ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        selected: sel,
                        selectedColor: Colors.white,
                        backgroundColor: AppColors.surfElevated(context),
                        onSelected: (_) => setState(() => _calcActivity = act),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Result Grid
        const Text(
          '// ESTIMATED DAILY TARGETS',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.water_drop_outlined,
                title: 'WATER INTAKE',
                value: '$waterMl ml',
                subtitle: 'Fresh water / day',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.restaurant_outlined,
                title: 'ENERGY TARGET',
                value: '$dailyKcal kcal',
                subtitle: 'Daily RER calories',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.directions_run_outlined,
                title: 'EXERCISE / PLAY',
                value: '$exerciseMins mins',
                subtitle: isDog ? 'Walking & games' : 'Interactive sessions',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.bedtime_outlined,
                title: 'REST & SLEEP',
                value: sleepHours,
                subtitle: 'Normal sleep daily',
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfElevated(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.brd(context)),
          ),
          child: const Row(
            children: [
              Icon(Icons.medical_services_outlined, size: 16, color: AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These values are calculated using standard veterinary RER algorithms. Adjust according to pet body condition score (BCS).',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return NothingCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.accentRed),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestion {
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _QuizQuestion({
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
