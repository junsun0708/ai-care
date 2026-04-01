import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../core/plugin/app_plugin.dart';

class VoiceAIPlugin implements AppPlugin {
  @override
  String get id => 'voice_ai';

  @override
  String get name => 'AI Voice Chat';

  @override
  String get description => '음성으로 영어 대화하며 영어 실력 UP!';

  @override
  String get icon => '🎙️';

  @override
  List<RequiredInfo> get requiredInfos => [
    const RequiredInfo(
      key: 'openai_api_key',
      label: 'OpenAI API Key',
      hint: 'sk-...',
      isSecret: true,
    ),
  ];

  @override
  bool isConfigured(Map<String, String> config) {
    final key = config['openai_api_key'];
    return key != null && key.isNotEmpty && key.startsWith('sk-');
  }

  @override
  void registerDependencies(GetIt getIt) {
    getIt.registerLazySingleton<SpeechToText>(() => SpeechToText());
    getIt.registerLazySingleton<FlutterTts>(() => FlutterTts());
  }

  @override
  Widget buildFeature(BuildContext context) {
    return const VoiceAIScreen(config: {});
  }

  @override
  Widget? buildSettingsWidget(BuildContext context, Map<String, String> config, Function(Map<String, String>) onSave) {
    return VoiceAISettings(config: config, onSave: onSave);
  }
}

class VoiceAISettings extends StatefulWidget {
  final Map<String, String> config;
  final Function(Map<String, String>) onSave;

  const VoiceAISettings({super.key, required this.config, required this.onSave});

  @override
  State<VoiceAISettings> createState() => _VoiceAISettingsState();
}

class _VoiceAISettingsState extends State<VoiceAISettings> {
  late TextEditingController _apiKeyController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.config['openai_api_key'] ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Voice Chat을 사용하려면 OpenAI API 키가 필요합니다.',
                  style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: 'OpenAI API Key',
            hintText: 'sk-...',
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'openai.com/platform/settings 에서 API 키를 생성하세요',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onSave({'openai_api_key': _apiKeyController.text});
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VoiceAIScreen extends StatefulWidget {
  final Map<String, String> config;

  const VoiceAIScreen({super.key, required this.config});

  @override
  State<VoiceAIScreen> createState() => _VoiceAIScreenState();
}

class _VoiceAIScreenState extends State<VoiceAIScreen> {
  final _speech = GetIt.I<SpeechToText>();
  final _tts = GetIt.I<FlutterTts>();
  late AICChatService _chatService;
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isLoading = false;
  String _recognizedText = '';
  String _userLevel = 'beginner';
  
  final List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _chatService = AICChatService(widget.config['openai_api_key'] ?? '');
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 인식 사용 불가')),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    
    if (_recognizedText.isNotEmpty) {
      await _sendToAI();
    }
  }

  Future<void> _sendToAI() async {
    setState(() {
      _isLoading = true;
      _chatHistory.add({'role': 'user', 'content': _recognizedText});
    });

    try {
      final response = await _chatService.sendMessage(
        message: _recognizedText,
        level: _userLevel,
      );

      setState(() {
        _chatHistory.add({'role': 'assistant', 'content': response});
      });

      await _speak(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  void _setLevel(String level) {
    setState(() => _userLevel = level);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '영어 수준',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _LevelButton(
                      label: '입문',
                      isSelected: _userLevel == 'beginner',
                      onTap: () => _setLevel('beginner'),
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _LevelButton(
                      label: '중급',
                      isSelected: _userLevel == 'intermediate',
                      onTap: () => _setLevel('intermediate'),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _LevelButton(
                      label: '고급',
                      isSelected: _userLevel == 'advanced',
                      onTap: () => _setLevel('advanced'),
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _chatHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            '마이크를 눌러 영어로 대화해보세요!',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _chatHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _chatHistory[index];
                        final isUser = msg['role'] == 'user';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('🤖', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? primaryColor : Colors.green[50],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 20),
                                  ),
                                ),
                                child: Text(
                                  msg['content']!,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('👤', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('AI가 응답하고 있습니다...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          if (_recognizedText.isNotEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎤 $_recognizedText',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Column(
            children: [
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isListening 
                          ? [Colors.red, Colors.red[400]!]
                          : [primaryColor, primaryColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.red : primaryColor).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, color: Colors.red[400], size: 12),
                          const SizedBox(width: 6),
                          Text(
                            'Listening...',
                            style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else if (_isSpeaking)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.volume_up, color: Colors.green[700], size: 16),
                          const SizedBox(width: 6),
                          Text(
                            ' Speaking...',
                            style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '마이크를 눌러 말해보세요',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _LevelButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AICChatService {
  final String? _apiKey;
  
  AICChatService(this._apiKey);

  Future<String> sendMessage({required String message, required String level}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'Please set your OpenAI API key in settings.';
    }

    final prompt = _buildPrompt(message, level);
    
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': message},
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  String _buildPrompt(String message, String level) {
    final levelInstructions = {
      'beginner': 'Use simple words (under 500 words), short sentences (5-10 words), basic grammar. Perfect for English learners.',
      'intermediate': 'Use moderate complexity, varied sentence structures. Good for intermediate speakers.',
      'advanced': 'Use native-level expressions, idioms, complex sentences. Natural and fluid.',
    };
    
    return '''You are a friendly English tutor for children. 
${levelInstructions[level]}

Keep responses under 200 words.
Be encouraging and supportive.
If the child asks about health topics, provide accurate, child-friendly information.
Always respond in English.''';
  }
}