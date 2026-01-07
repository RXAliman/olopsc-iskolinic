import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../logic/vvella_provider.dart';

class VvellaScreen extends StatelessWidget {
  const VvellaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VvellaProvider>(context);
    final state = provider.state;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Vvella Health"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const Spacer(),
           // Status Text
           Text(
             provider.statusMessage,
             style: const TextStyle(color: Colors.white70, fontSize: 18),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 20),
           
           // Pulse Animation
           Center(
             child: SizedBox(
               height: 200,
               width: 200,
               child: _buildPulse(state),
             ),
           ),
           
           const SizedBox(height: 20),
           // Recognition Text
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20),
             child: Text(
               provider.lastRecognizedText,
               style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
           ),
           const Spacer(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               TextButton(
                   onPressed: () {}, 
                   child: const Text("Suggestions", style: TextStyle(color: Colors.white))
               ),
               TextButton(
                   onPressed: () {}, 
                   child: const Text("Menu", style: TextStyle(color: Colors.white))
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulse(VoiceState state) {
     switch (state) {
       case VoiceState.initializing:
         return const SpinKitDoubleBounce(color: Colors.grey, size: 100);
       case VoiceState.idle:
         // Slow pulse
         return const SpinKitPulse(color: Colors.blueAccent, size: 100);
       case VoiceState.listening:
         // Fast active pulse
         return const SpinKitRipple(color: Colors.redAccent, size: 150);
       case VoiceState.processing:
         // Busy
         return const SpinKitFadingCircle(color: Colors.white, size: 80);
     }
  }
}
