import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/petsync_logo.dart';
import '../vets/vets_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hello! I am SyncAI, your on-device clinical veterinary triage and pet care intelligence assistant.\n\n'
          'Ask me anything about symptoms, toxic foods, puppy/kitten care, Mumbai veterinary hospitals, or first-aid protocols.',
      isUser: false,
      timestamp: DateTime.now(),
      severity: 'info',
    ),
  ];

  final List<String> _quickPrompts = [
    '🏥 Recommend emergency vets in Mumbai',
    '🚨 Ingested chocolate / toxic food',
    '🤢 Vomiting or diarrhea home triage',
    '💧 How to test dehydration in pets',
    '💉 Puppy & kitten vaccination schedule',
    '🍎 Can dogs eat eggs, apples & peanut butter?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String input) async {
    final text = input.trim();
    if (text.isEmpty || _isTyping) return;

    _textController.clear();
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    // Generate comprehensive clinical veterinary response
    final responseTemplate = _generateIntelligentTriageResponse(text);

    // Realistic streaming typing effect (streams text word-by-word)
    final words = responseTemplate.text.split(' ');
    String streamedText = '';

    // Add streaming placeholder
    setState(() {
      _messages.add(
        _ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          severity: responseTemplate.severity,
          showEmergencyVetButton: responseTemplate.showEmergencyVetButton,
          isStreaming: true,
        ),
      );
    });

    for (int i = 0; i < words.length; i++) {
      if (!mounted) return;
      streamedText += (i == 0 ? '' : ' ') + words[i];

      if (i % 3 == 0 || i == words.length - 1) {
        setState(() {
          _messages[_messages.length - 1] = _ChatMessage(
            text: streamedText,
            isUser: false,
            timestamp: DateTime.now(),
            severity: responseTemplate.severity,
            showEmergencyVetButton: responseTemplate.showEmergencyVetButton,
            isStreaming: i < words.length - 1,
          );
        });
        _scrollToBottom();
      }

      await Future.delayed(const Duration(milliseconds: 25));
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  _ChatMessage _generateIntelligentTriageResponse(String query) {
    final q = query.toLowerCase();

    // 1. MUMBAI VETERINARY RECOMMENDATIONS
    if (q.contains('mumbai') ||
        q.contains('vet') && (q.contains('near') || q.contains('recommend') || q.contains('hospital') || q.contains('clinic') || q.contains('best') || q.contains('where'))) {
      return _ChatMessage(
        text: 'ACCREDITED MUMBAI VETERINARY RECOMMENDATIONS\n\n'
            'For emergency trauma and comprehensive companion animal care in Mumbai:\n\n'
            '1. Bai Sakarbai Dinshaw Petit Hospital for Animals (BSPCA Hospital, Parel)\n'
            '   • Type: 24/7 Trauma Emergency, Critical Care & Animal Hospital\n'
            '   • Address: Dr. S.S. Rao Road, Near Gandhi Hospital, Parel, Mumbai 400012\n'
            '   • Emergency Contact: +91 22 2413 7518\n'
            '   • Best for: Round-the-clock emergency surgeries, ICU care, digital X-ray, and animal ambulances.\n\n'
            '2. Crown Vet - Worli (24-Hour Emergency & Advanced Surgery)\n'
            '   • Address: Below Mahalaxmi Bridge, Dr. E Moses Road, Worli, Mumbai 400018\n'
            '   • Emergency Hotline: +91 84519 11911 / +91 22 4971 7888\n'
            '   • Best for: Advanced soft tissue surgery, in-house laboratory, diagnostic ultrasound, ICU.\n\n'
            '3. Dr. Karkare\'s Happy Pets Clinic & Surgery (Bandra West)\n'
            '   • Address: Sunbeam Apartments, Perry Cross Road, Bandra West, Mumbai 400050\n'
            '   • Contact: +91 22 2640 4545\n'
            '   • Best for: Comprehensive internal medicine, vaccinations, ultrasonic dental scaling.\n\n'
            'Tap the button below to view all verified Mumbai hospitals with live Google Maps directions.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
        showEmergencyVetButton: true,
      );
    }

    // 2. TOXIC FOODS & POISONING EMERGENCIES
    if (q.contains('chocolate') ||
        q.contains('cocoa') ||
        q.contains('theobromine') ||
        q.contains('onion') ||
        q.contains('garlic') ||
        q.contains('grape') ||
        q.contains('raisin') ||
        q.contains('xylitol') ||
        q.contains('gum') ||
        q.contains('rat poison') ||
        q.contains('lily') ||
        q.contains('lilies') ||
        q.contains('poison') ||
        q.contains('toxic') ||
        q.contains('paracetamol') ||
        q.contains('crocin') ||
        q.contains('combiflam') ||
        q.contains('ibuprofen') ||
        q.contains('sago palm')) {
      return _ChatMessage(
        text: 'CRITICAL TOXIN INGESTION PROTOCOL\n\n'
            'Clinical Risk Assessment: Severe Toxicity Hazard\n\n'
            'Emergency Action Steps:\n'
            '1. DO NOT induce vomiting unless explicitly directed by a veterinary toxicologist (substances like corrosives cause severe esophageal burns upon regurgitation).\n'
            '2. Calculate Toxicity: Note the pet\'s weight, approximate time of ingestion, and packaging details.\n'
            '   • Chocolate: Contains theobromine & caffeine; induces cardiac arrhythmias and seizures.\n'
            '   • Grapes/Raisins: Incur sudden acute renal failure even in tiny doses.\n'
            '   • Onions/Garlic: Destroys red blood cells leading to hemolytic anemia.\n'
            '   • Xylitol (Artificial Sweetener): Triggers massive insulin surge and acute hypoglycemic collapse within 30-60 minutes.\n'
            '   • Human Painkillers (Paracetamol/Ibuprofen): Highly lethal to cats (methemoglobinemia) and severe renal failure in dogs.\n\n'
            'Recommendation: Immediate admission to a 24/7 veterinary trauma center (e.g. BSPCA Parel or Crown Vet Worli).',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'urgent',
        showEmergencyVetButton: true,
      );
    }

    // 3. RESPIRATORY & CHOKING
    if (q.contains('choking') ||
        q.contains('cough') ||
        q.contains('breathing') ||
        q.contains('breath') ||
        q.contains('gasp') ||
        q.contains('blue tongue') ||
        q.contains('blue gums') ||
        q.contains('collapse')) {
      return _ChatMessage(
        text: 'ACUTE RESPIRATORY / AIRWAY TRIAGE\n\n'
            'Immediate Clinical Assessment:\n'
            '1. Airway Inspection: Open pet\'s mouth gently. Look for a lodged ball, stick, or bone. Only sweep your finger if the object is clearly visible, loose, and safe to dislodge.\n'
            '2. Mucous Membrane Check: Normal gums are healthy pink. Pale white, blue, or purple gums indicate severe oxygen deprivation (hypoxia).\n'
            '3. Keep Calm: Do not compress the chest or neck. Place in a cool, well-ventilated space.\n\n'
            'Recommendation: Transport immediately to emergency veterinary care. Call the hospital in advance so an oxygen cage is primed upon arrival.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'urgent',
        showEmergencyVetButton: true,
      );
    }

    // 4. HEATSTROKE (MUMBAI CLIMATE)
    if (q.contains('heat') || q.contains('heatstroke') || q.contains('hot car') || q.contains('panting') && q.contains('heavy')) {
      return _ChatMessage(
        text: 'HEATSTROKE EMERGENCY FIRST-AID\n\n'
            'Heatstroke is common in warm, humid coastal climates like Mumbai, especially for brachycephalic breeds (Pugs, Bulldogs, Boxers, Shih Tzus).\n\n'
            'Clinical Symptoms:\n'
            '• Heavy, frantic panting and excessive thick drool\n'
            '• Brick red or dark purple gums\n'
            '• Disorientation, stumbling, or collapse\n\n'
            'Immediate First Aid:\n'
            '1. Move immediately into air-conditioned room or deep shade.\n'
            '2. Apply cool or room-temperature tap water to paws, neck, and inner thighs.\n'
            '3. NEVER use freezing ice or ice water bath — ice induces peripheral vasoconstriction, trapping lethal heat inside core organs.\n'
            '4. Provide small sips of water; do not force drink.\n\n'
            'Recommendation: Immediate veterinary evaluation to assess internal organ function and IV hydration.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'urgent',
        showEmergencyVetButton: true,
      );
    }

    // 5. VOMITING, DIARRHEA & GASTROINTESTINAL
    if (q.contains('vomit') ||
        q.contains('puke') ||
        q.contains('diarrhea') ||
        q.contains('loose') ||
        q.contains('stool') ||
        q.contains('poop') ||
        q.contains('stomach') ||
        q.contains('bloat')) {
      final isBloat = q.contains('bloat') || q.contains('swollen') || q.contains('retch');
      if (isBloat) {
        return _ChatMessage(
          text: 'SUSPECTED GASTRIC VOLVULUS (GDV / BLOAT)\n\n'
              'Warning: Non-productive dry retching with a distended, hard abdomen is a surgical emergency. The stomach can twist and cut off vena cava blood flow within hours.\n\n'
              'Action: Proceed immediately to the nearest 24/7 emergency veterinary hospital without delay.',
          isUser: false,
          timestamp: DateTime.now(),
          severity: 'urgent',
          showEmergencyVetButton: true,
        );
      }

      return _ChatMessage(
        text: 'GASTROINTESTINAL TRIAGE & HOME CARE PROTOCOL\n\n'
            'Clinical Evaluation:\n'
            '• Single mild vomiting/diarrhea episode:\n'
            '  1. Withhold dry kibble for 6-8 hours while providing continuous access to fresh clean water.\n'
            '  2. Introduce a bland recovery diet: 2 parts plain boiled white rice + 1 part boiled skinless, boneless chicken breast (no oil, salt, garlic, or onions).\n'
            '  3. Feed small portions 3-4 times daily for 48 hours before gradually mixing back normal food.\n\n'
            'Red Flag Symptoms (Require Hands-on Vet Visit):\n'
            '• Presence of fresh blood or black tarry stools (melena)\n'
            '• Repeated vomiting (> 3 times in 12 hours)\n'
            '• Complete lethargy, whining, or abdominal guarding\n'
            '• Ingestion of toys, strings, or cloth items (foreign body obstruction)',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'moderate',
        showEmergencyVetButton: false,
      );
    }

    // 6. HUMAN FOOD SAFETY & NUTRITION
    if (q.contains('food') ||
        q.contains('eat') ||
        q.contains('snack') ||
        q.contains('egg') ||
        q.contains('banana') ||
        q.contains('apple') ||
        q.contains('peanut') ||
        q.contains('chicken') ||
        q.contains('rice') ||
        q.contains('milk') ||
        q.contains('curd') ||
        q.contains('dairy') ||
        q.contains('bone')) {
      return _ChatMessage(
        text: 'VETERINARY HUMAN FOOD SAFETY GUIDE\n\n'
            '✅ Highly Safe & Nutritious (in moderation):\n'
            '• Plain Boiled Eggs: Excellent source of bioavailable protein, amino acids, and riboflavin. Always cook thoroughly.\n'
            '• Apples: Rich in vitamin A and C. Core and seeds MUST be removed (seeds contain trace cyanide).\n'
            '• Bananas: Good potassium and fiber boost; treat as an occasional snack due to natural sugar.\n'
            '• Carrots & Cucumbers: Low-calorie crunchy treats great for dental health and hydration.\n'
            '• Plain Curd / Yogurt: Provides beneficial gut probiotics; ensure unflavored and unsweetened.\n'
            '• Peanut Butter: Check label diligently — MUST be 100% Xylitol-free.\n'
            '• Plain Boiled Chicken & White Rice: The gold-standard bland diet for sensitive stomachs.\n\n'
            '❌ Strictly Prohibited & Toxic:\n'
            '• Cooked Bones: Splinter into sharp shards causing intestinal perforation and choking.\n'
            '• Onions, Garlic, Shallots: Destroys red blood cells causing Heinz body anemia.\n'
            '• Grapes & Raisins: Triggers acute renal failure.\n'
            '• Chocolate, Coffee, Tea: Theobromine toxicity.\n'
            '• Raw dough / Yeast: Ferments inside stomach creating alcohol and severe bloating.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
        showEmergencyVetButton: false,
      );
    }

    // 7. VACCINATION & DEWORMING TIMELINES
    if (q.contains('vaccin') ||
        q.contains('shot') ||
        q.contains('deworm') ||
        q.contains('rabies') ||
        q.contains('parvo') ||
        q.contains('distemper')) {
      return _ChatMessage(
        text: 'VETERINARY VACCINATION & PREVENTATIVE SCHEDULE\n\n'
            'Canine Core Schedule (WSAVA Guidelines):\n'
            '• 6-8 Weeks: DHPP Initial Booster (Distemper, Hepatitis, Parvovirus, Parainfluenza) + Deworming\n'
            '• 10-12 Weeks: DHPP Booster #2 + Corona + Kennel Cough (Bordetella)\n'
            '• 14-16 Weeks: DHPP Booster #3 + Anti-Rabies Vaccine (1st dose)\n'
            '• 1 Year & Annual: Annual DHPP Booster + Annual Anti-Rabies Booster\n\n'
            'Feline Core Schedule:\n'
            '• 8-9 Weeks: FVRCP / Tricat (Panleukopenia, Rhinotracheitis, Calicivirus)\n'
            '• 11-12 Weeks: FVRCP Booster #2 + FeLV\n'
            '• 14-16 Weeks: Anti-Rabies Vaccination\n'
            '• Adult: Annual boosters as advised by your vet.\n\n'
            'Deworming Protocol:\n'
            '• Every 2 weeks until 12 weeks of age.\n'
            '• Monthly until 6 months of age.\n'
            '• Every 3 months (quarterly) throughout adult life.\n\n'
            'Log each administered shot in the PetSync Health Journal module for digital tracking.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
        showEmergencyVetButton: false,
      );
    }

    // 8. HYDRATION & VITAL SIGNS CHECKS
    if (q.contains('dehydrat') || q.contains('water') || q.contains('skin tent') || q.contains('vital') || q.contains('temperature')) {
      return _ChatMessage(
        text: 'VITAL SIGNS & HYDRATION ASSESSMENT PROTOCOL\n\n'
            'Normal Vital Ranges (Healthy Dog & Cat):\n'
            '• Resting Heart Rate: Dogs: 70-120 bpm (smaller dogs higher); Cats: 140-200 bpm.\n'
            '• Resting Respiratory Rate: 15 to 30 breaths per minute while calm and sleeping.\n'
            '• Body Temperature: 101.0°F to 102.5°F (38.3°C to 39.2°C). Over 103.5°F indicates fever.\n\n'
            'Hydration Tests:\n'
            '1. Skin Turgor Test (Skin Tent):\n'
            '   • Gently pinch skin over the shoulder blades into a tent and release.\n'
            '   • Well hydrated: Snaps back flat immediately (< 1 second).\n'
            '   • Dehydrated: Retracts slowly or stands in a tent.\n\n'
            '2. Capillary Refill Time (CRT):\n'
            '   • Lift upper lip and touch gums. They should feel moist and slick.\n'
            '   • Press firmly on the pink gum with your finger and release: The blanched white spot should return to pink within 1.5 seconds.\n'
            '   • If gums feel dry, tacky, or CRT is > 2 seconds, pet requires immediate hydration support.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'mild',
        showEmergencyVetButton: false,
      );
    }

    // 9. TICKS, FLEAS & SKIN ISSUES
    if (q.contains('tick') || q.contains('flea') || q.contains('itch') || q.contains('scratch') || q.contains('hair loss') || q.contains('skin')) {
      return _ChatMessage(
        text: 'PARASITE CONTROL & DERMATOLOGY TRIAGE\n\n'
            'Tick Removal Protocol:\n'
            '1. Use fine-tipped tweezers or a specialized tick hook.\n'
            '2. Grasp the tick firmly as close to the skin as possible.\n'
            '3. Pull straight upward with slow, steady pressure. Never twist, burn, or apply kerosene/nail polish.\n'
            '4. Disinfect the bite site with chlorhexidine or Betadine.\n'
            '5. Watch for Tick Fever (Babesiosis/Ehrlichiosis) signs over the next 1-3 weeks: sudden lethargy, high fever, pale gums, or dark urine.\n\n'
            'Preventative Care: Administer veterinarian-prescribed oral isoxazoline chews (e.g. Bravecto/NexGard) or spot-on solutions monthly.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'mild',
        showEmergencyVetButton: false,
      );
    }

    // 10. PUPPY / DOG TRAINING & BEHAVIOR
    if (q.contains('train') || q.contains('bark') || q.contains('bite') || q.contains('potty') || q.contains('anxiety') || q.contains('behavior')) {
      return _ChatMessage(
        text: 'CANINE BEHAVIORAL & TRAINING INSIGHTS\n\n'
            'Puppy Mouthing & Biting:\n'
            '• Natural exploration behavior during teething (up to 6 months).\n'
            '• Redirection: When teeth touch skin, give a high-pitched "Ouch!", remove attention for 10 seconds, and immediately offer an approved chew toy.\n\n'
            'House / Potty Training:\n'
            '• Take puppy outside every 2 hours: immediately upon waking, 15 minutes after feeding, and post-play.\n'
            '• Reward with praise and a treat within 3 seconds of eliminating outside.\n'
            '• Never scold or rub their nose in past accidents — clean thoroughly with an enzymatic cleaner to eliminate scent markers.\n\n'
            'Separation Anxiety:\n'
            '• Practice short 2-5 minute departures without fanfare.\n'
            '• Leave frozen LickMats or stuffed Kongs with peanut butter to associate departure with positive mental engagement.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
        showEmergencyVetButton: false,
      );
    }

    // 11. GENERAL / PETSYNC PROJECT INQUIRIES
    if (q.contains('petsync') || q.contains('who are you') || q.contains('what is this') || q.contains('about')) {
      return _ChatMessage(
        text: 'ABOUT PETSYNC PLATFORM\n\n'
            'PetSync is a local-first, privacy-respecting pet-care management and veterinary intelligence platform.\n\n'
            'Key Architecture Highlights:\n'
            '• 100% Offline-First Privacy: Local embedded SQLite database guarantees pet health records and routines never leave the device.\n'
            '• Nothing OS Inspired UI: Clean monochrome styling, high-contrast typography, and functional minimalism.\n'
            '• Integrated Modules: Pet Profiles, Daily Care Routines, Health Journals, Vets & Emergency Hospitals, Knowledge Quiz, and SyncAI Clinical Assistant.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
        showEmergencyVetButton: false,
      );
    }

    // 12. GENERAL CONTEXTUAL FALLBACK
    return _ChatMessage(
      text: 'CLINICAL TRIAGE ASSESSMENT\n\n'
          'Regarding "$query":\n\n'
          '1. Baseline Monitoring Checklist:\n'
          '   • Appetite & Water Consumption: Is pet accepting food and retaining fluids?\n'
          '   • Energy & Demeanor: Note any lethargy, hiding, restless pacing, or whining.\n'
          '   • Elimination: Track frequency of urination and consistency of stool.\n\n'
          '2. Care Guideline:\n'
          '   • If symptoms have persisted for over 24 hours or show rapid escalation, schedule a physical hands-on veterinary examination.\n'
          '   • Log observable timestamps and symptom progression directly in your PetSync Health Journal.\n\n'
          '3. Need Immediate Medical Assistance?\n'
          '   • Use the button below to view verified animal hospitals with live Google Maps navigation.',
      isUser: false,
      timestamp: DateTime.now(),
      severity: 'info',
      showEmergencyVetButton: true,
    );
  }

  void _openVetsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VetsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Row(
          children: [
            PetSyncLogo(size: 22),
            SizedBox(width: 8),
            Text(
              'SYNCAI ASSISTANT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          // Active intelligence status badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3320),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Colors.greenAccent),
                SizedBox(width: 4),
                Text(
                  'AI ACTIVE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            tooltip: 'Clear Conversation',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    text: 'Conversation cleared. How can SyncAI assist your pet today?',
                    isUser: false,
                    timestamp: DateTime.now(),
                    severity: 'info',
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: AppColors.surf(context),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 13, color: Colors.greenAccent),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SyncAI On-Device Clinical Intelligence active. Real-time veterinary guidance & triage.',
                      style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Prompt Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final prompt = _quickPrompts[i];
                  return InkWell(
                    onTap: () => _handleSend(prompt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brd(context)),
                      ),
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Typing Indicator
            if (_isTyping && (_messages.isEmpty || !_messages.last.isStreaming))
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.brd(context)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SyncAI analyzing symptoms...',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surf(context),
                border: Border(top: BorderSide(color: AppColors.brd(context))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe symptoms or ask pet care questions...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        fillColor: AppColors.surfElevated(context),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.brd(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppColors.brd(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white, width: 1.2),
                        ),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                      onPressed: () => _handleSend(_textController.text),
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

  Widget _buildMessageBubble(_ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16).copyWith(bottomRight: const Radius.circular(2)),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      );
    }

    // AI message
    Color badgeBg = AppColors.surfElevated(context);
    Color badgeBorder = AppColors.brd(context);
    String badgeText = 'SYNCAI CLINICAL ADVICE';

    if (msg.severity == 'urgent') {
      badgeBg = AppColors.accentRedDim;
      badgeBorder = AppColors.danger;
      badgeText = '🔴 URGENT CLINICAL EMERGENCY';
    } else if (msg.severity == 'moderate') {
      badgeBg = const Color(0xFF332A10);
      badgeBorder = Colors.amber;
      badgeText = '🟡 MODERATE RISK // MONITOR CLOSELY';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 30),
        child: NothingCard(
          padding: const EdgeInsets.all(14),
          borderColor: msg.severity == 'urgent' ? AppColors.danger : AppColors.brd(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                msg.text.isEmpty && msg.isStreaming ? 'Analyzing symptoms...' : msg.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
              if (msg.showEmergencyVetButton) ...[
                const SizedBox(height: 14),
                NothingButton.danger(
                  label: 'VIEW MUMBAI VETS & HOSPITALS',
                  icon: Icons.local_hospital,
                  isExpanded: true,
                  height: 38,
                  onPressed: _openVetsScreen,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? severity; // 'urgent', 'moderate', 'mild', 'info'
  final bool showEmergencyVetButton;
  final bool isStreaming;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.severity,
    this.showEmergencyVetButton = false,
    this.isStreaming = false,
  });
}
