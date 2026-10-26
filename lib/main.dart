import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Annu AI Assistant',
    debugShowCheckedModeBanner: false,
    home: AnnuScreen(),
  ));
}

class AnnuScreen extends StatefulWidget {
  const AnnuScreen({super.key});

  @override
  State<AnnuScreen> createState() => _AnnuScreenState();
}

class _AnnuScreenState extends State<AnnuScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  final TextEditingController _input = TextEditingController();

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late AnimationController _anim;

  bool _isListening = false;
  bool _isSpeaking = false;
  String _status = "Ek second... load ho raha hai ❤️";

  final String _apiKey = "AQ.Ab8RN46Je0MB0a7Vc8RsNcJ51ENDBds0hbeRFZ6TzOP45NUDO4A";
  final String _charImage = "https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=1000&auto=format&fit=crop";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initTts();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _status = "नमस्ते dost! मैं अन्नू हूँ। क्या बात करनी है?");
      _speak(_status);
    });
  }

  void _initTts() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setPitch(1.2);
    await _tts.setSpeechRate(0.5);

    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((_) => setState(() => _isSpeaking = false));
  }

  void _speak(String text) async {
    if (text.isNotEmpty) await _tts.speak(text);
  }

  void _talk() async {
    if (_isSpeaking) await _tts.stop();

    if (!_isListening) {
      bool ok = await _speech.initialize(
        onStatus: (s) {
          if (s == "done" || s == "notListening") setState(() => _isListening = false);
        },
        onError: (_) => setState(() {
          _isListening = false;
          _status = "आवाज़ समझ नहीं आई";
        }),
      );

      if (ok) {
        setState(() {
          _isListening = true;
          _status = "सुन रही हूँ...";
        });
        _speech.listen(
          localeId: "hi_IN",
          onResult: (res) {
            if (res.recognizedWords.isNotEmpty) {
              _askAI(res.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _askAI(String text) async {
    setState(() => _status = "अन्नू सोच रही है...");
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final res = await model.generateContent([
        Content.text("तुम एक प्यारी, क्यूट और केयरिंग AI दोस्त अन्नू हो। यूजर को 'dost' कहकर बहुत प्यार से और 1-2 लाइन में छोटा जवाब दो: $text")
      ]);
      final reply = res.text ?? "मुझे समझ नहीं आया dost!";
      setState(() => _status = reply);
      _speak(reply);
    } catch (e) {
      setState(() => _status = "इंटरनेट चेक करें।");
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      drawer: Drawer(
        backgroundColor: const Color(0xFFF1F5FB),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4FA5F7), Color(0xFF1E88E5)])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 26, backgroundColor: Colors.white24, child: Icon(Icons.auto_awesome, color: Colors.white)),
                  SizedBox(height: 8),
                  Text("Annu AI", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text("Home"), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(_charImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    const Color(0xFF0F0C20).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => _key.currentState?.openDrawer(),
                      ),
                      const Text(
                        "ANNU",
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 4),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    double scale = (_isListening || _isSpeaking) ? (1.0 + _anim.value * 0.15) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isSpeaking
                                  ? Colors.purpleAccent.withOpacity(0.7)
                                  : (_isListening ? Colors.blueAccent.withOpacity(0.7) : Colors.transparent),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 36),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Annu se baat karein...",
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.pinkAccent),
                          onPressed: () {
                            if (_input.text.isNotEmpty) {
                              _askAI(_input.text);
                              _input.clear();
                            }
                          },
                        ),
                        GestureDetector(
                          onTap: _talk,
                          child: CircleAvatar(
                            backgroundColor: _isListening ? Colors.redAccent : Colors.purpleAccent,
                            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
