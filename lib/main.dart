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

  String _apiKey = "AQ.Ab8RN46Je0MB0a7Vc8RsNcJ51ENDBds0hbeRFZ6TzOP45NUDO4A";

  final String _charImage = "https://images.unsplash.com/photo-1578632767115-351597cf2477?q=80&w=1080&auto=format&fit=crop";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initFemaleTTS();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _status = "नमस्ते dost! मैं अन्नू हूँ। बताओ आज क्या बात करनी है?");
      _speak(_status);
    });
  }

  void _initFemaleTTS() async {
    await _tts.setLanguage("hi-IN");
    await _tts.setPitch(1.35);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);

    try {
      var voices = await _tts.getVoices;
      for (var voice in voices) {
        if (voice["locale"].toString().contains("hi") && voice["name"].toString().toLowerCase().contains("female")) {
          await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
          break;
        }
      }
    } catch (_) {}

    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((_) => setState(() => _isSpeaking = false));
  }

  void _speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
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
          _status = "आवाज़ समझ नहीं आई, फिर से बोलें";
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
        Content.text("तुम्हारा नाम अन्नू है। तुम एक बेहद क्यूट, प्यारी और केयरिंग लड़की और दोस्त हो। यूजर से हिंदी या हिंग्लिश में 'dost' कहकर बहुत प्यार और आदर से बात करो। 1 या 2 छोटे वाक्यों में ही जवाब देना: $text")
      ]);
      final reply = res.text ?? "हाँजी dost, मैंने सुना!";
      setState(() => _status = reply);
      _speak(reply);
    } catch (e) {
      setState(() => _status = "API Key अमान्य है या इंटरनेट धीमा है। सेटिंग्स में नई Key डालें।");
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
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF4FA5F7), Color(0xFF1E88E5)]),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.favorite, color: Colors.pinkAccent, size: 28)),
                  SizedBox(height: 10),
                  Text("Annu AI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Tumhari personal dost", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded, color: Color(0xFF1E88E5)),
              title: const Text("Home", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF475569)),
              title: const Text("Settings & API Key", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnuSettingsScreen(
                      currentKey: _apiKey,
                      onKeyUpdated: (newKey) {
                        setState(() => _apiKey = newKey);
                      },
                    ),
                  ),
                );
              },
            ),
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
                    Colors.black.withOpacity(0.3),
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
                        icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnnuSettingsScreen(
                                currentKey: _apiKey,
                                onKeyUpdated: (newKey) => setState(() => _apiKey = newKey),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    double scale = (_isListening || _isSpeaking) ? (1.0 + _anim.value * 0.2) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isSpeaking
                                  ? Colors.purpleAccent.withOpacity(0.8)
                                  : (_isListening ? Colors.blueAccent.withOpacity(0.8) : Colors.transparent),
                              blurRadius: 35,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 42),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
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
                      color: Colors.white.withOpacity(0.18),
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

class AnnuSettingsScreen extends StatefulWidget {
  final String currentKey;
  final Function(String) onKeyUpdated;

  const AnnuSettingsScreen({super.key, required this.currentKey, required this.onKeyUpdated});

  @override
  State<AnnuSettingsScreen> createState() => _AnnuSettingsScreenState();
}

class _AnnuSettingsScreenState extends State<AnnuSettingsScreen> {
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.currentKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gemini API Key", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white12,
                hintText: "Enter AI Studio Key (AIzaSy...)",
                hintStyle: const TextStyle(color: Colors.white38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  widget.onKeyUpdated(_keyController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("API Key सेव हो गई!")),
                  );
                  Navigator.pop(context);
                },
                child: const Text("Save Key", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
