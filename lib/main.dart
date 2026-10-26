import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Annu AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late stt.SpeechToText _speech;
  late AudioPlayer _audioPlayer;

  bool _isListening = false;
  String _statusText = "माइक दबाकर अन्नू से बात करें";
  String _userSpokenText = "";

  // ==========================================
  // आपकी Gemini API Key
  // ==========================================
  final String _geminiApiKey = "AQ.Ab8RN46Je0MB0a7Vc8RsNcJ51ENDBds0hbeRFZ6TzOP45NUDO4A";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _speech = stt.SpeechToText();
    _audioPlayer = AudioPlayer();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            setState(() => _isListening = false);
            if (_userSpokenText.isNotEmpty) {
              _askGemini(_userSpokenText);
            }
          }
        },
        onError: (error) => setState(() {
          _isListening = false;
          _statusText = "आवाज़ समझ नहीं आई, फिर से कहें";
        }),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _statusText = "सुन रही हूँ...";
          _userSpokenText = "";
        });

        _speech.listen(
          localeId: "hi_IN",
          onResult: (val) {
            setState(() {
              _userSpokenText = val.recognizedWords;
              _statusText = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _askGemini(String prompt) async {
    setState(() {
      _statusText = "अन्नू सोच रही है...";
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);
      final content = [Content.text("तुम एक प्यारी और मददगार AI असिस्टेंट हो जिसका नाम अन्नू है। हिंदी में दोस्ताना और छोटा जवाब दो: $prompt")];
      final response = await model.generateContent(content);

      setState(() {
        _statusText = response.text ?? "माफ़ करना, मैं समझ नहीं पाई।";
      });
    } catch (e) {
      setState(() {
        _statusText = "कुछ गड़बड़ हो गई, दोबारा कोशिश करें।";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        title: const Text('Annu AI Assistant'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: _isListening ? 140 + (_controller.value * 25) : 120,
                    height: _isListening ? 140 + (_controller.value * 25) : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Colors.purpleAccent, Colors.deepPurple],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          blurRadius: _isListening ? 35 : 15,
                          spreadRadius: _isListening ? 10 : 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, size: 55, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.4),
                ),
              ),
              const SizedBox(height: 50),
              GestureDetector(
                onTap: _listen,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
