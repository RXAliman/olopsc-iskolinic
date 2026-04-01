class QueueService {
  /// Add a patient to the clinic queue.
  Future<void> addToQueue({
    required String studentName,
    required String studentNumber,
    required String firstName,
    required String lastName,
    required String middleName,
    required String extension,
    required DateTime? birthdate,
    required String sex,
    required String contactNumber,
    required String address,
    required String guardianName,
    required String guardianContact,
    required String guardian2Name,
    required String guardian2Contact,
    required String allergicTo,
    required List<String> symptoms,
  }) async {
    // TODO: implement submission mechanism
  }
}
