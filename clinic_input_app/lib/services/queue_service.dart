import 'package:cloud_firestore/cloud_firestore.dart';

class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a patient to the clinic queue.
  ///
  /// The document structure matches what [QueueProvider] in clinic_desktop_app
  /// reads from the 'queue' collection:
  ///   - studentName, studentNumber, reason, timestamp, status
  ///
  /// Extra fields (address, guardianName, guardianContact, symptoms list,
  /// treatment, remarks) are stored alongside for richer data without breaking
  /// the desktop app's existing reads.
  Future<void> addToQueue({
    required String studentName,
    required String studentNumber,
    required String address,
    required String guardianName,
    required String guardianContact,
    required List<String> symptoms,
    required String treatment,
    required String remarks,
  }) async {
    await _firestore.collection('queue').add({
      // Fields read by clinic_desktop_app QueueProvider
      'studentName': studentName,
      'studentNumber': studentNumber,
      'reason': symptoms.join(', '),
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'waiting',

      // Extended fields for full form data
      'address': address,
      'guardianName': guardianName,
      'guardianContact': guardianContact,
      'symptoms': symptoms,
      'treatment': treatment,
      'remarks': remarks,
    });
  }
}
