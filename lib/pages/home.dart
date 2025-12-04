import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  final String picovoiceKey = dotenv.get('PICOVOICE_ACCESS_KEY', fallback: '');
  bool _speechEnabled = false;
  String _lastWords = '';

  FlutterTts flutterTts = FlutterTts(); 
  
  // New state variables for language selection
  List<String> _languages = [];
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts(); 
  }

  void _initTts() async {
    // 1. Fetch available languages when TTS is initialized
    await _getLanguages();
    
    // 2. Set default language after fetching
    if (_languages.isNotEmpty) {
      String defaultLang = _languages.contains('fil-PH') ? 'fil-PH' 
        : _languages.contains('en-US') ? 'en-US' : _languages.first;
      
      setState(() {
        _selectedLanguage = defaultLang;
      });
      await flutterTts.setLanguage(defaultLang);
    }
    await flutterTts.setSpeechRate(0.5);   
    await flutterTts.setVolume(1.0);       
  }
  
  // New function to fetch and populate the list of languages
  Future<void> _getLanguages() async {
    try {
      // The getLanguages method returns a List<dynamic>
      List<dynamic> languages = await flutterTts.getLanguages;
      
      setState(() {
        // Convert to List<String> and save to state
        _languages = languages.map((e) => e.toString()).toList();
      });
      print('Available languages: $_languages');
    } catch (e) {
      print('Error fetching languages: $e');
    }
  }

  // Function to change the TTS language
  void _setLanguage(String? newLanguage) async {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      await flutterTts.setLanguage(newLanguage);
    }
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) { 
        if (status == 'notListening' && _lastWords.isNotEmpty) {
          _handleSpeechCompletion();
        }
      },
    );
    setState(() {});
  }

  void _handleSpeechCompletion() async {
    String responseText = _selectedLanguage != "fil-PH"
      ? "You said: $_lastWords."
      : _lastWords.contains("kumusta ka")
        ? "Ako ay nasa mabuting kalagayan! Ano ang maitutulong ko?"
        : _lastWords.contains("wala lang")
          ? "Anak ka ng tipaklong. Kakaselpon mo yan"
          : "Ang sabi mo: $_lastWords.";
    await flutterTts.speak(responseText);
  }

  void _startListening() async {
    setState(() {
      _lastWords = '';
    });
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30), 
      pauseFor: const Duration(seconds: 3),  
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // --- Language Selector Section ---
            Container(
              padding: EdgeInsets.all(16),
              child: DropdownButton<String>(
                hint: Text('Select TTS Language'),
                value: _selectedLanguage,
                items: _languages.map((String value) {
                  return DropdownMenuItem<String>(
                    // Display the language code (e.g., 'en-US')
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _setLanguage,
              ),
            ),
            // ---------------------------------
            Container(
              padding: EdgeInsets.all(16),
              child: Text(
                'Recognized words:',
                style: TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  _speechToText.isListening
                      ? _lastWords
                      : _speechEnabled
                          ? 'Tap the microphone to start listening...'
                          : 'Speech not available',
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _speechToText.isNotListening ? _startListening : _stopListening,
        tooltip: 'Listen',
        child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
}