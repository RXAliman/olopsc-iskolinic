import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../logic/vvella_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bottomNavIndex = 0;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void dispose() {
    _chatScrollController.dispose();
    super.dispose();
  }

  // Scroll to bottom when new message arrives
  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VvellaProvider>(context);
    final state = provider.state;

    // Scroll to bottom when chat history changes
    if (provider.chatHistory.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _bottomNavIndex == 0
            ? _buildChatView(provider, state)
            : _buildMenuView(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButton(state),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: [
          _bottomNavIndex == 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
          _bottomNavIndex == 1 ? Icons.menu_open : Icons.menu,
        ],
        iconSize: 28.0,
        activeColor: Colors.teal,
        inactiveColor: Colors.grey,
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

  Widget _buildChatView(VvellaProvider provider, VoiceState state) {
    if (provider.chatHistory.isEmpty) {
      // Empty state - show instructions
      return _buildEmptyState(state);
    }

    // Chat messages view
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: ListView.builder(
        controller: _chatScrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.chatHistory.length,
        itemBuilder: (context, index) {
          final message = provider.chatHistory[index];
          final isVvella = message['actor'] == 'vvella';
          final content = message['content'] ?? '';

          return Padding(
            padding: isVvella
                ? const EdgeInsets.only(right: 20.0, bottom: 16.0)
                : const EdgeInsets.only(left: 20.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: isVvella
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isVvella ? Colors.teal.shade600 : Colors.white,
                      borderRadius: isVvella
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                              bottomLeft: Radius.zero,
                              bottomRight: Radius.circular(20.0),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.zero,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        color: isVvella ? Colors.white : Colors.black87,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(VoiceState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Idle state instruction
          if (state == VoiceState.idle)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 24.0,
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
                children: [
                  const TextSpan(
                    text: "Say 'VVella' (pronounced 'Vee-velah') or Tap  ",
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.mic, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: "  to start monitoring."),
                ],
              ),
            ),

          // Listening state
          if (state == VoiceState.listening)
            Column(
              children: [
                Text(
                  "Listening...",
                  style: const TextStyle(color: Colors.black54, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const SpinKitRipple(color: Colors.redAccent, size: 150),
              ],
            ),

          // Processing state
          if (state == VoiceState.processing)
            Column(
              children: [
                Text(
                  "Processing...",
                  style: const TextStyle(color: Colors.black54, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const SpinKitFadingCircle(color: Colors.teal, size: 80),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMenuView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          "Health Menu\n(Coming Soon)",
          style: TextStyle(
            fontSize: 24.0,
            color: Colors.black45,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(VoiceState state) {
    final provider = Provider.of<VvellaProvider>(context, listen: false);

    return Ink(
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
          colors: switch (state) {
            VoiceState.listening => [Colors.red.shade400, Colors.red.shade700],
            _ => [Colors.teal.shade400, Colors.teal.shade700],
          },
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Manual control based on state
          switch (state) {
            case VoiceState.idle:
              // Start listening manually (skip wake word)
              provider.startListeningManually();
              break;
            case VoiceState.listening:
              // Stop listening and return to idle
              provider.stopListening();
              break;
            case VoiceState.processing:
              // Do nothing while processing
              break;
            default:
              break;
          }
        },
        borderRadius: BorderRadius.circular(50.0),
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.black.withOpacity(0.05),
        splashColor: Colors.black.withOpacity(0.1),
        child: SizedBox(
          width: 80,
          height: 80,
          child: state == VoiceState.processing
              ? const SpinKitThreeBounce(color: Colors.white, size: 20.0)
              : Icon(
                  state == VoiceState.listening ? Icons.stop : Icons.mic,
                  size: 40,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}
