import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// --- Data Structure for Local Storage ---
class HealthLog {
  final String type;
  final String value;
  final String? symptomDescription;
  // CHANGED: Use DateTime for local storage instead of Timestamp
  final DateTime timestamp; 

  HealthLog({
    required this.type,
    required this.value,
    this.symptomDescription,
    required this.timestamp,
  });
}

class _HomePageState extends State<HomePage> {
  // --- Voice Engine Instances ---
  final String ACCESS_KEY = dotenv.get('PICOVOICE_ACCESS_KEY', fallback: '');
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  PorcupineManager? _porcupineManager;

  // --- State Variables ---
  bool _speechEnabled = false;
  String _lastWords = '';
  String _appStatus = 'Initializing...';
  String _currentSuggestion = 'Remember to take your 10 AM medication.';
  
  List<String> _languages = [];
  String? _selectedLanguage;

  
  // NEW: State variable to store the fetched system locale ID for STT
  String? _systemLocaleId; 
  List<HealthLog> _recentLogs = []; // In-memory storage

  // --- Porcupine Wake Word Setup ---
  final int wakeWordIndex = 0; 
  
  // The system state: dictates whether STT or Porcupine is listening
  bool _isWakeWordListening = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize in order
    _initTts();
    _initSpeechAndPorcupine();
  }

  // --- TTS Initialization (flutter_tts) ---
  void _initTts() async {
    await _getLanguages();
    
    if (_languages.isNotEmpty) {
      String defaultLang = _languages.contains('en-US') ? 'en-US' : _languages.first;
      _setLanguage(defaultLang);
    }
    
    // Set accessible speech parameters
    await _flutterTts.setSpeechRate(0.5);   // Slow rate for elderly users
    await _flutterTts.setVolume(1.0);       // Max volume
    
    // Announce ready status
    _updateAppStatus('TTS Ready. Waiting for speech initialization.');
  }

  Future<void> _getLanguages() async {
    try {
      List<dynamic> languages = await _flutterTts.getLanguages;
      setState(() {
        _languages = languages.map((e) => e.toString()).toList();
      });
    } catch (e) {
      print('Error fetching languages: $e');
    }
  }

  void _setLanguage(String? newLanguage) async {
    if (newLanguage != null) {
      setState(() {
        _selectedLanguage = newLanguage;
      });
      await _flutterTts.setLanguage(newLanguage);
    }
  }

  // --- STT Initialization (speech_to_text) ---
  void _initSpeechAndPorcupine() async {
    _speechToText.initialize(
      onStatus: (status) { 
        if (status == 'notListening' && _speechToText.isNotListening && _lastWords.isNotEmpty) {
          _handleSpeechCompletion();
        }
      },
    ).then((value) {
      _speechEnabled = value;
      if (_speechEnabled) {
        _initPorcupine();
      }
    },);
    
    // NEW: Correctly await the systemLocale() call to get the localeId
    final systemLocale = await _speechToText.systemLocale();
    if (systemLocale != null) {
      _systemLocaleId = systemLocale.localeId;
      print('Speech-to-Text System Locale ID fetched: $_systemLocaleId');
    }
    
    _updateAppStatus(_speechEnabled ? 'Speech initialized. Starting wake word.' : 'Speech Not Available.');
  }

  // --- Porcupine Initialization and Callback ---
  void _initPorcupine() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        ACCESS_KEY,
        ["assets/Vee-Vella_en_android_v3_0_0.ppn"],
        _wakeWordCallback,
        errorCallback: _processErrorCallback,
      );
      
      await _porcupineManager?.start();
      _isWakeWordListening = true;
      _updateAppStatus('Ready. Say "VVella" to activate.');

    } on PorcupineException catch (err) {
      _updateAppStatus("Wake Word Error: ${err.message}");
      print("Porcupine Error: ${err.message}");
    }
  }

  void _processErrorCallback(PorcupineException error) {
    _updateAppStatus('Porcupine Error: ${error.message}');
    print("Porcupine Processing Error: ${error.message}");
  }

  void _wakeWordCallback(int keywordIndex) async {
    if (keywordIndex == 0 && _speechToText.isNotListening) {
      print("Wake word detected! Starting STT.");
      
      // 1. Stop Porcupine
      await _porcupineManager?.stop();
      _isWakeWordListening = false;

      // 2. TTS Cue
      await _flutterTts.speak("Yes, I am listening."); 
      
      // 3. Start STT
      Future.delayed(Duration(milliseconds: 2500)).then(
        (value) {
          _startListening(); 
        }
      );
    }
  }

  // --- STT Control Functions ---
  void _startListening() async {
  if (!_speechEnabled || _speechToText.isListening) return;

  // CRITICAL: Ensure _lastWords is reset before a new listening session
  setState(() {
    _lastWords = '';
  });

  await _speechToText.listen(
    onResult: _onSpeechResult,
    localeId: _systemLocaleId ?? 'en_US', 
    listenFor: const Duration(seconds: 30), 
    pauseFor: const Duration(seconds: 3),   
    listenOptions: SpeechListenOptions(
      listenMode: ListenMode.dictation,
      cancelOnError: true,
    ),
  );
  _updateAppStatus('Listening for command...');
}

  void _onSpeechResult(SpeechRecognitionResult result) {
    // Use a local variable to prevent processing if the result is empty
    String recognizedText = result.recognizedWords; 
    
    setState(() {
      // Always update _lastWords, even if it's a partial result
      _lastWords = recognizedText;
      
      if (result.finalResult) {
        // *** PRIMARY FIX: Process command immediately when finalResult is true ***
        _updateAppStatus('Processing command...');
        _handleFinalCommand(recognizedText); 
      } else {
        // If not final, keep showing the intermediate transcription
        _updateAppStatus('Listening: $_lastWords...');
      }
    });
  }

  // NEW: Dedicated handler for the FINAL recognized text
  void _handleFinalCommand(String finalCommand) async {
    if (finalCommand.isEmpty) {
        await _flutterTts.speak("I didn't catch that. Please try again.");
    } else {
        String response = await _processCommand(finalCommand.toLowerCase().trim());
        print(response);
        await _flutterTts.speak(response);
    }
    
    // Restart Porcupine for the next wake word detection
    await _porcupineManager?.start();
    _isWakeWordListening = true;
    _updateAppStatus('Ready. Say "VVella" to activate.');
  }
  
  // --- OLD _handleSpeechCompletion FUNCTION IS NOW SIMPLIFIED ---
  // We keep this function mainly for the Porcupine restart logic, 
  // and prevent it from running the processCommand logic again.
  // We remove the contents of this function as the processing is now in _onSpeechResult
  void _handleSpeechCompletion() async {
    // If the command processing was already triggered by finalResult=true, 
    // we don't need to do anything here except for potentially catching timeouts.
    // We leave this function primarily for the purpose of the onStatus listener 
    // as defined in _initSpeech(). If _lastWords is empty, it's a timeout/error.
    if (_lastWords.isEmpty) {
      _updateAppStatus('Timeout detected. No words recognized.');
      await _flutterTts.speak("Listening timed out. Please try again.");
      
      // Restart Porcupine regardless of timeout
      await _porcupineManager?.start();
      _isWakeWordListening = true;
      _updateAppStatus('Ready. Say "VVella" to activate.');
    }
  }

  Future<String> _processCommand(String command) async {
    // Simplified NLU: Keyword and pattern matching
    String logType = '';
    String logValue = '';
    String? description;

    // VITAL LOGGING: "log blood pressure 120 over 80"
    if (command.contains('log') || command.contains('track')) {
      if (command.contains('blood pressure') || command.contains('bp') || command.contains('heart rate')) {
        logType = command.contains('heart rate') ? 'Heart Rate' : 'Blood Pressure';
        RegExp exp = RegExp(r'(\d+)\s*(over|\/|and)\s*(\d+)|\d+');
        Match? m = exp.firstMatch(command.replaceAll(RegExp(r'\s+rate'), '')); // Remove rate for cleaner match
        if (m != null) {
          logValue = m.group(0)!.contains('over') ? m.group(0)!.replaceAll(' ', '') : m.group(0)!;
        }
      } else if (command.contains('weight')) {
        logType = 'Weight';
        RegExp exp = RegExp(r'(\d+)\s*(pounds|lbs|kg)');
        Match? m = exp.firstMatch(command);
        if (m != null) {
          logValue = m.group(0) ?? 'N/A';
        }
      } else if (command.contains('blood sugar')) {
        logType = 'Blood Sugar';
        RegExp exp = RegExp(r'(\d+)\s*(mg|mmol)');
        Match? m = exp.firstMatch(command);
        if (m != null) {
          logValue = m.group(0) ?? 'N/A';
        }
      } else if (command.contains('sleep') || command.contains('rest')) {
        logType = 'Sleep Quality';
        if (command.contains('good') || command.contains('well')) {
          logValue = 'Good';
        } else if (command.contains('bad') || command.contains('poor')) {
          logValue = 'Poor';
        }
      } else if (command.contains('activity') || command.contains('exercise')) {
        logType = 'Activity';
        logValue = command.contains('walked') ? 'Walked' : (command.contains('run') ? 'Ran' : 'Logged');
        description = command.replaceAll(RegExp(r'log|track|activity|exercise'), '').trim();
      } else if (command.contains('hydration') || command.contains('meal')) {
        logType = command.contains('hydration') ? 'Hydration' : 'Meal';
        logValue = command.contains('drank') ? 'Drank' : (command.contains('ate') ? 'Ate' : 'Logged');
        description = command.replaceAll(RegExp(r'log|track|hydration|meal|drank|ate'), '').trim();
      }
    } 
    
    // SYMPTOM LOGGING: "I feel dizzy" or "log symptom dizzy"
    else if (command.contains('symptom') || command.contains('i feel')) {
      logType = 'Symptom';
      logValue = 'Logged';
      if (command.contains('symptom')) {
        description = command.substring(command.indexOf('symptom') + 7).trim();
      } else {
        description = command.substring(command.indexOf('i feel') + 6).trim();
      }
    }

    // EXECUTION: Save to local memory if logType is identified
    if (logType.isNotEmpty && logValue.isNotEmpty) {
      final log = HealthLog(
        type: logType,
        value: logValue,
        symptomDescription: description,
        timestamp: DateTime.now(), // CHANGED: Use DateTime.now()
      );
      
      // Save to local memory and update UI
      setState(() {
        _recentLogs.insert(0, log); // Add to the start
        // Ensure only the top 5 logs are kept for memory management
        if (_recentLogs.length > 5) {
          _recentLogs = _recentLogs.sublist(0, 5);
        }
      });
      return 'Confirmed. Logging your $logType data as $logValue.';
    } 
    
    // REMINDER/SCHEDULE: Mock functionality 
    else if (command.contains('remind me to') || command.contains('schedule medication')) {
        return 'Confirmed. I will set a reminder for your medication or appointment.';
    }

    return "I couldn't identify that command. Please try again with a health term.";
  }

  // --- UI and Status Management ---
  void _updateAppStatus(String status) {
    setState(() {
      _appStatus = status;
    });
  }

  // Widget to display recent log entries
  Widget _buildRecentLogList() {
    if (_recentLogs.isEmpty) {
      return const Center(child: Text('No recent logs. Start logging via voice!'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CHANGED: Removed User ID display
        Text(
          'Recent Activity (In-Memory)', 
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: Colors.teal),
        ),
        const Divider(),
        ..._recentLogs.map((log) {
          // CHANGED: Use DateTime.toLocal() and substring for time display
          final time = log.timestamp.toLocal().toString().substring(11, 16);
          return ListTile(
            dense: true,
            leading: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
            title: Text('${log.type}: ${log.value}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Time: $time${log.symptomDescription != null && log.symptomDescription!.isNotEmpty ? ' | Detail: ${log.symptomDescription}' : ''}'),
          );
        }).toList(),
      ],
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    _porcupineManager?.stop();
    _porcupineManager?.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the icon and color based on state
    IconData fabIcon = _isWakeWordListening 
      ? Icons.mic_external_on_outlined // Porcupine is listening for wake word
      : _speechToText.isListening 
        ? Icons.mic // STT is actively listening for command
        : Icons.mic_off; // Nothing is actively listening

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // --- Status Display ---
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          _appStatus,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _isWakeWordListening ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'TTS Language:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // Language Selector Dropdown
                        DropdownButton<String>(
                          hint: const Text('Select TTS Language'),
                          value: _selectedLanguage,
                          items: _languages.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: _setLanguage,
                          isExpanded: true,
                        ),
                      ],
                    ),
                  ),
                ),
            
                // --- Health Suggestion Tile ---
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Health Prompt',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.deepOrange,
                          ),
                        ),
                        const Divider(color: Colors.orange),
                        const SizedBox(height: 8),
                        Text(
                          _currentSuggestion,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),

                // --- Recent Log Display (In-Memory Data) ---
                // Expanded(
                //   child: Padding(
                //     padding: const EdgeInsets.only(top: 16.0),
                //     child: _buildRecentLogList(),
                //   ),
                // ),
                
                // --- Recognized Words Area ---
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    _lastWords.isNotEmpty 
                      ? 'Last heard: "$_lastWords"' 
                      : 'Awaiting voice command...',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                
                const SizedBox(height: 100), // Space for FAB
              ],
            ),
          ),
        ),
      ),
      
      // --- Centered Gradient FAB ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () {
          // If the wake word is listening, tap stops it (debug/override)
          if (_isWakeWordListening) {
             _porcupineManager?.stop();
             _isWakeWordListening = false;
             _updateAppStatus('Wake word manually stopped.');
          } else {
            // If STT is listening, tap stops it
            if (_speechToText.isListening) {
               _speechToText.stop();
               _updateAppStatus('STT manually stopped.');
            } else {
               // Fallback: manually start listening if neither is active
               _wakeWordCallback(0); 
            }
          }
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
            // Use a linear gradient for visual appeal
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(
            fabIcon,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
      
      // --- Bottom AppBar for Docking (Optional but cleans up the dock space) ---
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(height: 60), 
      ),
    );
  }
}