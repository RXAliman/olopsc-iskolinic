import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QueueItem {
  final String id;
  final String studentName;
  final String studentNumber;
  final String reason;
  final DateTime timestamp;
  final String status; // 'waiting', 'in_progress', 'done'

  QueueItem({
    required this.id,
    required this.studentName,
    required this.studentNumber,
    required this.reason,
    required this.timestamp,
    this.status = 'waiting',
  });

  factory QueueItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueItem(
      id: doc.id,
      studentName: data['studentName'] ?? '',
      studentNumber: data['studentNumber'] ?? '',
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'waiting',
    );
  }
}

class QueueProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueueItem> _queueItems = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<QueueItem> get queueItems => _queueItems;
  List<QueueItem> get waitingItems =>
      _queueItems.where((i) => i.status == 'waiting').toList();
  List<QueueItem> get inProgressItems =>
      _queueItems.where((i) => i.status == 'in_progress').toList();
  List<QueueItem> get doneItems =>
      _queueItems.where((i) => i.status == 'done').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get waitingCount => waitingItems.length;

  /// Start listening to the queue collection in real-time
  void startListening() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _firestore
        .collection('queue')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            _queueItems = snapshot.docs
                .map((doc) => QueueItem.fromFirestore(doc))
                .toList();
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Update a queue item's status
  Future<void> updateStatus(String id, String newStatus) async {
    await _firestore.collection('queue').doc(id).update({'status': newStatus});
  }

  /// Remove a queue item
  Future<void> removeFromQueue(String id) async {
    await _firestore.collection('queue').doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
