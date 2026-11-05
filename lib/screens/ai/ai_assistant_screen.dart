import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../database/database_helper.dart';
import '../../theme/app_colors.dart';
import '../../widgets/nothing_card.dart';
import '../../widgets/nothing_button.dart';
import '../../widgets/petsync_logo.dart';
import '../../widgets/app_snackbar.dart';
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

  // Gemini Live AI state
  String? _geminiApiKey;
  GenerativeModel? _geminiModel;
  ChatSession? _geminiChat;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hello! I am SyncAI, your veterinary care & clinical triage advisor. Describe any symptoms, food concerns, behavioral shifts, or emergency questions.',
      isUser: false,
      timestamp: DateTime.now(),
      severity: 'info',
    ),
  ];

  final List<String> _quickPrompts = [
    '🚨 Ingested chocolate / toxic food',
    '🤢 Vomiting or diarrhea',
    '💧 How to test dehydration',
    '💉 Puppy & kitten vaccine schedule',
    '🦗 How to remove a tick safely',
    '🍎 Safe human snacks for pets',
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await DatabaseHelper.instance.getGeminiApiKey();
    if (key != null && key.isNotEmpty) {
      _initGemini(key);
    }
  }

  void _initGemini(String apiKey) {
    try {
      _geminiApiKey = apiKey;
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          'You are SyncAI, an empathetic and authoritative veterinary health and clinical triage assistant designed for the PetSync offline-first application. '
          'Your job is to provide accurate, science-based guidance on pet care, nutrition, clinical symptoms, and first-aid protocols for dogs, cats, and small animals. '
          'Formatting requirements:\n'
          '- Structure replies with concise paragraphs and bullet points.\n'
          '- When clinical symptoms are described, always categorize severity at the top: [🔴 URGENT EMERGENCY], [🟡 MODERATE RISK], or [🟢 MILD / HOME CARE].\n'
          '- If potentially fatal substances (chocolate, onions, garlic, xylitol, grapes, lilies, rodenticides) or breathing distress are mentioned, immediately advise seeking emergency veterinary trauma care.\n'
          '- Keep advice focused, clear, and easy for an anxious pet owner to read quickly.',
        ),
      );
      _geminiChat = _geminiModel!.startChat();
      setState(() {});
    } catch (_) {
      _geminiModel = null;
      _geminiChat = null;
    }
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
    if (text.isEmpty) return;

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

    // Check if live Gemini API is configured
    if (_geminiChat != null) {
      try {
        final responsePlaceholder = _ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        );

        setState(() {
          _messages.add(responsePlaceholder);
        });

        final stream = _geminiChat!.sendMessageStream(Content.text(text));
        String accumulated = '';

        await for (final chunk in stream) {
          if (chunk.text != null) {
            accumulated += chunk.text!;
            setState(() {
              _messages[_messages.length - 1] = _ChatMessage(
                text: accumulated,
                isUser: false,
                timestamp: DateTime.now(),
                severity: _detectSeverity(accumulated),
                showEmergencyVetButton: accumulated.contains('URGENT') || accumulated.contains('EMERGENCY'),
                isStreaming: true,
              );
            });
            _scrollToBottom();
          }
        }

        setState(() {
          _messages[_messages.length - 1] = _ChatMessage(
            text: accumulated,
            isUser: false,
            timestamp: DateTime.now(),
            severity: _detectSeverity(accumulated),
            showEmergencyVetButton: accumulated.contains('URGENT') || accumulated.contains('EMERGENCY'),
            isStreaming: false,
          );
          _isTyping = false;
        });
        return;
      } catch (e) {
        // Fall back gracefully to offline triage if API call fails or offline
        if (mounted) {
          AppSnackBar.show(
            context,
            'Gemini API unreachable. Using offline triage engine.',
          );
        }
      }
    }

    // Offline rule-based triage inference
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final response = _generateTriageResponse(text);
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isStreaming) {
        _messages[_messages.length - 1] = response;
      } else {
        _messages.add(response);
      }
      _isTyping = false;
    });
    _scrollToBottom();
  }

  String _detectSeverity(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('URGENT') || upper.contains('EMERGENCY') || upper.contains('FATAL') || upper.contains('POISON')) {
      return 'urgent';
    }
    if (upper.contains('MODERATE') || upper.contains('MONITOR')) {
      return 'moderate';
    }
    return 'info';
  }

  _ChatMessage _generateTriageResponse(String query) {
    final q = query.toLowerCase();

    // 1. TOXIC FOODS / POISONING
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
        q.contains('tylenol') ||
        q.contains('ibuprofen')) {
      return _ChatMessage(
        text: 'POTENTIAL TOXIN INGESTION DETECTED\n\n'
            'Immediate Actions:\n'
            '1. Identify the substance, estimated quantity ingested, and pet weight.\n'
            '2. DO NOT induce vomiting unless specifically instructed by a veterinary toxicologist (corrosives can cause esophageal rupture).\n'
            '3. Bring packaging or samples of the ingested substance with you to the clinic.\n\n'
            'Critical Signs of Toxicity: Hyperactivity, vomiting, tremors, rapid heart rate, dark or pale gums, collapse.\n\n'
            'Recommendation: Immediate escalation to a 24/7 veterinary emergency trauma facility.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'urgent',
        showEmergencyVetButton: true,
      );
    }

    // 2. RESPIRATORY & CHOKING
    if (q.contains('choking') ||
        q.contains('cough') ||
        q.contains('breathing') ||
        q.contains('breath') ||
        q.contains('gasp') ||
        q.contains('blue tongue') ||
        q.contains('blue gums')) {
      return _ChatMessage(
        text: 'ACUTE RESPIRATORY / AIRWAY EMERGENCY\n\n'
            '1. Check airway: Carefully inspect the mouth for a foreign object (ball, bone, stick). Only sweep finger if object is clearly visible and loose.\n'
            '2. Check gum color: Pink = adequate oxygenation. Blue, pale grey, or purple = severe hypoxia.\n'
            '3. Keep pet calm in a cool, well-ventilated space. Minimize handling or stress.\n\n'
            'Recommendation: Transport immediately to emergency care. Call ahead so oxygen cage can be prepared.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'urgent',
        showEmergencyVetButton: true,
      );
    }

    // 3. VOMITING & DIARRHEA
    if (q.contains('vomit') ||
        q.contains('puke') ||
        q.contains('diarrhea') ||
        q.contains('stool') ||
        q.contains('poop') ||
        q.contains('belly') ||
        q.contains('bloat')) {
      final isBloat = q.contains('bloat') || q.contains('dry retch') || q.contains('swollen stomach');
      if (isBloat) {
        return _ChatMessage(
          text: 'SUSPECTED GASTRIC DILATATION-VOLVULUS (GDV / BLOAT)\n\n'
              'Bloating with non-productive retching is a rapid life-threatening emergency in dogs.\n'
              '• Time is vital: Stomach twisting cuts off blood supply to vital organs.\n'
              '• Immediate Action: Proceed immediately to the nearest 24/7 emergency veterinary hospital.',
          isUser: false,
          timestamp: DateTime.now(),
          severity: 'urgent',
          showEmergencyVetButton: true,
        );
      }

      return _ChatMessage(
        text: 'GASTROINTESTINAL DISTRESS TRIAGE\n\n'
            'Evaluation & Monitoring:\n'
            '• Mild / Single episode: Withhold food for 6-8 hours (provide small sips of fresh water). Follow with a bland diet (boiled chicken breast and plain white rice in 1:2 ratio) for 24-48 hours.\n'
            '• Red Flags Requiring Immediate Vet Care:\n'
            '  - Blood in vomit or black tarry stool (melena)\n'
            '  - Persistent vomiting (> 3 times in 12 hours)\n'
            '  - Complete lethargy or refusal to stand\n'
            '  - Ingestion of foreign objects (toys, string, socks)',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'moderate',
        showEmergencyVetButton: false,
      );
    }

    // 4. DEHYDRATION
    if (q.contains('dehydrat') || q.contains('water') || q.contains('drinking') || q.contains('skin tent')) {
      return _ChatMessage(
        text: 'PET HYDRATION ASSESSMENT PROTOCOL\n\n'
            '1. Skin Turgor Test: Gently lift a fold of skin over your pet\'s shoulder blades and release.\n'
            '   • Normal: Snaps back smoothly in under 1 second.\n'
            '   • Dehydrated: Retracts slowly or stays tented.\n\n'
            '2. Gum Capillary Refill:\n'
            '   • Lift upper lip and touch gums. They should feel moist and slippery.\n'
            '   • Press firmly with your thumb: White blanch should return to healthy pink within 1.5 seconds.\n\n'
            'Home Care: Offer clean bowl, water fountain, or unseasoned diluted bone broth. If gums are dry and tacky, subcutaneous or IV fluids at a clinic are required.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'mild',
      );
    }

    // 5. VACCINATION TIMELINES
    if (q.contains('vaccin') || q.contains('shot') || q.contains('deworm') || q.contains('parvo') || q.contains('rabies')) {
      return _ChatMessage(
        text: 'STANDARD VACCINATION & PREVENTATIVE TIMELINE\n\n'
            'Canine Core Schedule:\n'
            '• 6-8 Weeks: DHPP Booster #1 (Distemper, Hepatitis, Parvovirus, Parainfluenza) + Deworming\n'
            '• 10-12 Weeks: DHPP Booster #2 + Bordetella (Kennel Cough)\n'
            '• 14-16 Weeks: DHPP Booster #3 + Rabies (1-Year)\n'
            '• Adult: Annual or 3-Year DHPP & Rabies boosters\n\n'
            'Feline Core Schedule:\n'
            '• 6-8 Weeks: FVRCP Booster #1 (Panleukopenia, Rhinotracheitis, Calicivirus)\n'
            '• 10-12 Weeks: FVRCP Booster #2 + FeLV (Leukemia)\n'
            '• 14-16 Weeks: FVRCP Booster #3 + Rabies\n\n'
            'Tip: Keep all completion dates logged in PetSync Health Journal.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
      );
    }

    // 6. TICKS & FLEAS
    if (q.contains('tick') || q.contains('flea') || q.contains('itch') || q.contains('scratch') || q.contains('parasite')) {
      return _ChatMessage(
        text: 'TICK REMOVAL & PARASITE FIRST AID\n\n'
            'Tick Removal Protocol:\n'
            '1. Use fine-tipped tweezers or a tick removal hook.\n'
            '2. Grasp the tick as close to the skin surface as possible.\n'
            '3. Pull straight upward with steady, even pressure. DO NOT twist or jerk, and NEVER burn or smother with petroleum jelly.\n'
            '4. Disinfect bite site with antiseptic solution (chlorhexidine or povidone-iodine).\n\n'
            'Flea Prevention: Monthly veterinary-grade oral (isoxazoline) or topical spot-on treatments. Wash pet bedding in hot water.',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'mild',
      );
    }

    // 7. SAFE HUMAN FOODS
    if (q.contains('food') ||
        q.contains('snack') ||
        q.contains('peanut') ||
        q.contains('apple') ||
        q.contains('banana') ||
        q.contains('carrot') ||
        q.contains('cheese') ||
        q.contains('human food')) {
      return _ChatMessage(
        text: 'PET NUTRITIONAL COMPATIBILITY GUIDE\n\n'
            '✅ Safe in Moderation:\n'
            '• Carrots & Green Beans (low calorie, high fiber)\n'
            '• Apples (remove seeds and core - seeds contain cyanide)\n'
            '• Plain cooked pumpkin (excellent for digestive regularity)\n'
            '• Peanut Butter (check label carefully: MUST NOT contain Xylitol/Birch Bark Extract)\n'
            '• Plain boiled chicken and white rice\n\n'
            '❌ Never Feed:\n'
            '• Chocolate, Coffee, Caffeinated items\n'
            '• Grapes, Raisins, Currants (acute renal failure)\n'
            '• Onions, Garlic, Chives, Leeks\n'
            '• Macadamia nuts & Walnuts\n'
            '• Cooked bones (splinter hazard causing intestinal perforation)',
        isUser: false,
        timestamp: DateTime.now(),
        severity: 'info',
      );
    }

    // GENERAL ADVICE
    return _ChatMessage(
      text: 'CLINICAL CARE ADVISORY\n\n'
          'Regarding "$query":\n\n'
          '1. Monitor vital baseline: appetite, water consumption, energy level, and urination/defecation regularity.\n'
          '2. If symptoms have persisted for over 24 hours or your pet appears lethargic or in pain (whining, panting, hunched posture), schedule a hands-on examination.\n'
          '3. Record timestamps and observable progression directly in your PetSync Health Journal.\n\n'
          'Need immediate medical attention? Use Vets Near Me to locate an open animal hospital.',
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

  // ==========================================
  // GEMINI API KEY CONFIGURATION MODAL
  // ==========================================
  void _showApiKeyDialog() {
    final keyController = TextEditingController(text: _geminiApiKey ?? '');
    bool isTesting = false;
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.key, color: AppColors.accentRed, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '// GEMINI LIVE AI KEY',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Guide box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfElevated(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brd(context)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HOW TO GET YOUR FREE API KEY:',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '1. Visit aistudio.google.com in your browser.\n'
                            '2. Sign in with any Google account & tap "Create API Key".\n'
                            '3. Copy and paste it below.\n'
                            'Your key is saved locally in private storage on your device only.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: keyController,
                      obscureText: obscure,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'GOOGLE GEMINI API KEY',
                        hintText: 'AIzaSy...',
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setModalState(() => obscure = !obscure),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (isTesting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text(
                                'Verifying key with Google AI Studio...',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: NothingButton(
                              label: 'VALIDATE & SAVE',
                              onPressed: () async {
                                final enteredKey = keyController.text.trim();
                                if (enteredKey.isEmpty) {
                                  AppSnackBar.show(context, 'Please enter a Gemini API key.', isError: true);
                                  return;
                                }

                                setModalState(() => isTesting = true);

                                try {
                                  // Live test verification call
                                  final testModel = GenerativeModel(
                                    model: 'gemini-1.5-flash',
                                    apiKey: enteredKey,
                                  );
                                  await testModel.generateContent([Content.text('Ping')]);

                                  // Success: save key
                                  await DatabaseHelper.instance.saveGeminiApiKey(enteredKey);
                                  _initGemini(enteredKey);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    AppSnackBar.show(context, 'Gemini Live AI validated & active!');
                                  }
                                } catch (e) {
                                  setModalState(() => isTesting = false);
                                  if (context.mounted) {
                                    AppSnackBar.show(context, 'Key verification failed: $e', isError: true);
                                  }
                                }
                              },
                            ),
                          ),
                          if (_geminiApiKey != null) ...[
                            const SizedBox(width: 8),
                            NothingButton.danger(
                              label: 'CLEAR',
                              onPressed: () async {
                                await DatabaseHelper.instance.clearGeminiApiKey();
                                setState(() {
                                  _geminiApiKey = null;
                                  _geminiModel = null;
                                  _geminiChat = null;
                                });
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  AppSnackBar.show(context, 'Key cleared. Switched to offline triage.');
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiveAi = _geminiChat != null;

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
          // Live Gemini vs Offline Triage status pill
          InkWell(
            onTap: _showApiKeyDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLiveAi ? const Color(0xFF1B3320) : AppColors.surfElevated(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLiveAi ? Colors.greenAccent.withValues(alpha: 0.6) : AppColors.brd(context),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLiveAi ? Icons.cloud_done : Icons.bolt,
                    size: 13,
                    color: isLiveAi ? Colors.greenAccent : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLiveAi ? 'GEMINI LIVE' : 'OFFLINE TRIAGE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isLiveAi ? Colors.greenAccent : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.key_outlined, size: 20),
            tooltip: 'Configure Gemini API Key',
            onPressed: _showApiKeyDialog,
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
              if (_geminiModel != null) {
                _geminiChat = _geminiModel!.startChat();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Disclaimer / status pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: AppColors.surf(context),
              child: Row(
                children: [
                  Icon(
                    isLiveAi ? Icons.auto_awesome : Icons.info_outline,
                    size: 13,
                    color: isLiveAi ? Colors.greenAccent : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isLiveAi
                          ? 'Connected to Google Gemini 1.5 Flash. Real-time veterinary AI triage active.'
                          : 'Offline clinical triage mode active. Tap the key icon to connect live Gemini AI.',
                      style: TextStyle(
                        fontSize: 10,
                        color: isLiveAi ? Colors.greenAccent : AppColors.textMuted,
                        fontFamily: 'monospace',
                      ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isLiveAi ? 'Gemini 1.5 generating triage...' : 'SyncAI analyzing symptoms...',
                            style: const TextStyle(
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
                        hintText: isLiveAi
                            ? 'Ask Gemini live pet triage & advice...'
                            : 'Describe symptoms or ask care questions...',
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
    String badgeText = _geminiChat != null ? 'GEMINI 1.5 LIVE' : 'SYNCAI ADVICE';

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
                msg.text.isEmpty && msg.isStreaming ? 'Thinking...' : msg.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.45,
                ),
              ),
              if (msg.showEmergencyVetButton) ...[
                const SizedBox(height: 14),
                NothingButton.danger(
                  label: 'FIND NEARBY EMERGENCY VET',
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
