import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AnnuApp());
}

class AnnuApp extends StatelessWidget {
  const AnnuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ANNU AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0B1E),
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
  // 👇 यहाँ बीच में अपनी कॉपी की हुई Key पेस्ट करें 👇
  // ==========================================
  final String _geminiApiKey = "AQ.Ab8RN6JeOWB0a7Vc8RsNcJ51ENDBds0hbeRFZ6TzOP45NJDO4A"

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

  Future<void> _askGemini(String question) async {
    setState(() => _statusText = "अन्नू सोच रही है...");

    try {
      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text":
                    "तुम्हारा नाम अन्नू (Annu) है। तुम एक बहुत प्यारी, रोमांटिक, समझदार और केयरिंग AI दोस्त हो। हमेशा प्यार भरे हिंदी/हिंग्लिश में सिर्फ 1-2 लाइनों में छोटे और प्यारे जवाब दो।"
              }
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": question}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String reply = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() => _statusText = reply);
        _playSweetVoice(reply);
      } else {
        setState(() => _statusText = "जवाब देने में समस्या आई।");
      }
    } catch (e) {
      setState(() => _statusText = "इंटरनेट कनेक्शन चेक करें।");
    }
  }

  void _playSweetVoice(String text) async {
    try {
      String cleanText = Uri.encodeComponent(text);
      String audioUrl =
          "https://translate.google.com/translate_tts?ie=UTF-8&q=$cleanText&tl=hi&client=tw-ob";
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      // Audio error
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ANNU AI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 180 + (_controller.value * 20),
                    height: 180 + (_controller.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2A85).withOpacity(0.5),
                          blurRadius: 40 + (_controller.value * 20),
                          spreadRadius: 10,
                        ),
                      ],
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF529A),
                          Color(0xFF8B1253),
                          Color(0xFF1B0727),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _listen,
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFFF2A85)
                            : const Color(0xFF231834),
                        boxShadow: [
                          if (_isListening)
                            const BoxShadow(
                              color: Color(0xFFFF2A85),
                              blurRadius: 25,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 36,
                      ),
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
}
