import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vvella/components/health_card.dart';
import 'package:vvella/logic/command.dart';
import 'package:vvella/services/hive/health_log.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum AppStatus {
  initializing,
  idle,
  listening,
  processing,
}

class _HomePageState extends State<HomePage> {
  // Temporary Chat History
  List<Map> _chats = [];

  // Voice Engine Instances
  final String _accessKey = dotenv.get('PICOVOICE_ACCESS_KEY', fallback: '');
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  PorcupineManager? _porcupineManager;

  // State Variables
  AppStatus _appStatus = AppStatus.initializing;
  String _appStatusMessage = "Initializing...";
  int _bottomNavIndex = 0;
  bool _speechEnabled = false;
  String _lastWords = '';
  String? _systemLocaleId;
  late String _selectedLanguage;

  // Porcupine Wake Word
  final int wakeWordIndex = 0;
  bool _isWakeWordListening = false;

  // Scroll Controller
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeechAndPorcupine();
  }

  void _initSpeechAndPorcupine() async {
    // Text-to-speech
    _selectedLanguage = 'en-US';
    await _flutterTts.setLanguage(_selectedLanguage);
    
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);

    setState(() {
      _appStatusMessage = "TTS Ready. Waiting for speech initialization.";
    });

    // Speech-to-text
    await _speechToText.initialize(
      onStatus: (status) { 
        if (status == 'notListening' && _speechToText.isNotListening && _lastWords.isNotEmpty) {
          _handleSpeechCompletion();
        }
      },
    ).then((value) {
      _speechEnabled = value;
      if (_speechEnabled == false) {
        setState(() {
          _appStatus = AppStatus.idle;
        });
        return;
      }
    });
    final systemLocale = await _speechToText.systemLocale();
    if (systemLocale != null) {
      _systemLocaleId = systemLocale.localeId;
      print('Speech-to-Text System Locale ID fetched: $_systemLocaleId');
    }

    // Porcupine Wake Word
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        ["assets/Vee-Vella_en_android_v3_0_0.ppn"],
        _wakeWordCallback,
        errorCallback: _processErrorCallback,
      );
      await _porcupineManager?.start();
      setState(() {  
        _isWakeWordListening = true;
        _appStatus = AppStatus.idle;
      });
    } on PorcupineException catch (err) {
      print("Porcupine Error: ${err.message}");
    }
  }

  void _processErrorCallback(PorcupineException error) {
    print("Porcupine Processing Error: ${error.message}");
  }

  void _wakeWordCallback(int keywordIndex) async {
    if (keywordIndex == 0 && _speechToText.isNotListening) {
      print("Wake word detected! Starting STT.");
      
      await _porcupineManager?.stop();
      _isWakeWordListening = false;

      await _handleTtsSpeak("How can I help you?");
      setState(() {
        _appStatus = AppStatus.listening;
      }); 
      
      Future.delayed(Duration(milliseconds: 2000)).then(
        (value) {
          if (_appStatus == AppStatus.listening) {
            _startListening();
          }
        }
      );
    }
  }

  void _handleSpeechCompletion() async {
    if (_lastWords.isEmpty) {
      await _handleTtsSpeak("Listening timed out. Please try again.");
      
      await _porcupineManager?.start();
      setState(() {
        _isWakeWordListening = true;
        _appStatus = AppStatus.idle;
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled || _speechToText.isListening) return;

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
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords; 
    
    setState(() {
      _lastWords = recognizedText;
      
      if (result.finalResult) {
        _appStatus = AppStatus.processing;
        _addChatLog('User', recognizedText);
        _handleFinalCommand(recognizedText); 
      } else {
        // If not final, keep showing the intermediate transcription
        // _updateAppStatus('Listening: $_lastWords...');
      }
    });
  }

  void _handleFinalCommand(String finalCommand) async {
    if (finalCommand.isEmpty) {
        await _handleTtsSpeak("I didn't catch that. Please try again.");
    } else {
      String response = await CommandService.process(finalCommand.toLowerCase().trim());
      await _handleTtsSpeak(response);
    }
    
    await _porcupineManager?.start();
    setState(() {
      _isWakeWordListening = true;
      _appStatus = AppStatus.idle;
    });
  }

  Future<void> _handleTtsSpeak(String content) async {
    await _flutterTts.speak(content);
    _addChatLog('vvella', content);
  }

  void _addChatLog(String actor, String content) => setState(() {  
    _chats.add({
      'actor': actor,
      'content': content,
    });
    _scrollDown();
  });

  void _scrollDown() {
    try {
      _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
    } catch (e) {}
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    _porcupineManager?.stop();
    _porcupineManager?.delete();
    super.dispose();
  }

  Widget _buildChatWidget() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: 40.0,
      ),
      child: _chats.isEmpty
      ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _appStatus == AppStatus.initializing
          ? Column(
            spacing: 12.0,
            children: [
              SpinKitWave(
                color: Colors.black45,
                size: 20.0,
                itemCount: 3,
              ),
              Text(
                _appStatusMessage,
                style: TextStyle(
                  fontSize: 24.0,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
          : RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.black45,
                fontStyle: FontStyle.italic,
              ),
              children: [
                TextSpan(text: "Say 'VVella' (pronounced 'Vee-velah') or Tap  "),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.mic,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                TextSpan(text: "  to start monitoring."),
              ],
            ),
          ),
        ],
      )
      : ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
            stops: [0.0, 0.0, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
        child: ListView.separated(
          controller: _chatScrollController,
          padding: EdgeInsets.only(bottom: 40.0),
          separatorBuilder: (context, index) => Divider(height: 32.0),
          itemCount: _chats.length,
          itemBuilder: (context, index) {
            String actor = _chats[index]['actor'];
            bool isVvella = actor == 'vvella';
            return IntrinsicHeight(
              child: Column(
                crossAxisAlignment: isVvella ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  Text(
                    isVvella ? 'VVella' : actor,
                    textAlign: isVvella ? TextAlign.left : TextAlign.right,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: isVvella ? Colors.green.shade700 : Colors.black45,
                      fontWeight: isVvella ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    _chats[index]['content'],
                    textAlign: isVvella ? TextAlign.left : TextAlign.right,
                    style: TextStyle(
                      fontSize: isVvella ? 22.0 : 20.0,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenu() {
    // Blood Pressure
    int? systole = HealthLogService.getLatestBloodPressureLog()?['systolic'];
    int? diastole = HealthLogService.getLatestBloodPressureLog()?['diastolic'];
    String? bloodPressureStatus;
    if (systole != null && diastole != null) {
      if (systole < 120 && diastole < 80) {
        bloodPressureStatus = "Recent Log: $systole/$diastole\nStatus: Normal";
      }
      else if ((systole >= 120 && systole <= 129) && diastole < 80) {
        bloodPressureStatus = "Recent Log: $systole/$diastole\nStatus: Elevated";
      }
      else if ((systole >= 130 && systole <= 139) || (diastole >= 80 && diastole <= 89)) {
        bloodPressureStatus = "Recent Log: $systole/$diastole\nStatus: High Blood Pressure (Stage 1)";
      }
      else if ((systole >= 140 && systole < 180) || (diastole >= 90 && diastole < 120)) {
        bloodPressureStatus = "Recent Log: $systole/$diastole\nStatus: High Blood Pressure (Stage 2)";
      }
      else {
        bloodPressureStatus = "Recent Log: $systole/$diastole\nStatus: Hypertensive Emergency";
      }
    }
    // Blood Sugar Level
    double? bloodSugar = HealthLogService.getLatestBloodSugarLog()?['readingInMilligramPerDeciliter'];

    // Weight
    double? weight = HealthLogService.getLatestWeightLog()?['weightInKilograms'];

    return Padding(
      padding: EdgeInsetsGeometry.only(
        top: 8.0,
        left: 8.0,
        right: 8.0,
        bottom: 32.0,
      ),
      child: ShaderMask(
        shaderCallback: (Rect rect) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.transparent, Colors.transparent, Colors.purple],
            stops: [0.0, 0.0, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstOut,
        child: ListView(
          padding: EdgeInsets.only(
            top: 16.0,
            bottom: 42.0,
          ),
          children: [
            HealthCard(
              title: "Blood Pressure", 
              content: bloodPressureStatus ?? "No data recorded",
            ),
            HealthCard(
              title: "Blood Sugar Level", 
              content: bloodSugar != null ? "Recent Log: $bloodSugar mg/dL" : "No data recorded",
            ),
            HealthCard(
              title: "Weight", 
              content: weight != null ? "Recent Log: $weight kg" : "No data recorded",
            ),
            HealthCard(
              title: "Exercise", 
              content: "No data recorded",
            ),
            HealthCard(
              title: "Meal Tracking", 
              content: "No data recorded",
            ),
            HealthCard(
              title: "Sleep Pattern", 
              content: "No data recorded",
            ),
            HealthCard(
              title: "Water Intake", 
              content: "No data recorded",
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _bottomNavIndex == 0
          ? _buildChatWidget()
          : _buildMenu(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _appStatus == AppStatus.initializing
      ? Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0,5),
            ),
          ],
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox(
          width: 80,
          height: 80,
          child: SpinKitThreeBounce(
            color: Colors.white,
            size: 20.0,
          ),
        ),
      )
      : Ink(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          gradient: LinearGradient(
            colors: switch (_appStatus) {
              AppStatus.idle || AppStatus.processing => [Colors.teal.shade400, Colors.teal.shade700],
              AppStatus.listening => [Colors.red.shade400, Colors.red.shade700],
              _ => [Colors.black54, Colors.black],
            },
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          onTap: () {
            switch (_appStatus) {
              case AppStatus.idle:
                _wakeWordCallback(0);
                break;
              case AppStatus.listening:
                _speechToText.stop();
                _flutterTts.stop();
                setState(() {
                  _isWakeWordListening = true;
                  _appStatus = AppStatus.idle;
                });
                break;
              default:
                break;
            }
          },
          borderRadius: BorderRadius.circular(50.0),
          splashFactory: InkRipple.splashFactory,
          highlightColor: Colors.black.withValues(alpha: 0.05),
          splashColor: Colors.black.withValues(alpha: 0.1),
          child: SizedBox(
            width: 80,
            height: 80,
            child: _appStatus == AppStatus.processing
            ? SpinKitThreeBounce(
              color: Colors.white,
              size: 20.0,
            )
            : Icon(
              switch (_appStatus) {
                AppStatus.listening => Icons.stop,
                _ => Icons.mic,
              },
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: [
          _bottomNavIndex == 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
          _bottomNavIndex == 1 ? Icons.menu_open : Icons.menu,
        ],
        iconSize: 28.0,
        activeColor: Colors.teal,
        height: 72.0,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (index) => setState(() {
          _bottomNavIndex = index;
        }),
      ),
    );
  }
}