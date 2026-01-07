class NLUProcessor {
  // Return type could be a structured object, but Map is flexible for now
  Map<String, dynamic>? process(String text) {
    final lower = text.toLowerCase();
    
    // Blood Pressure: "120 over 80", "120/80"
    if (lower.contains("blood pressure") || lower.contains("bp")) {
      final RegExp bpRegex = RegExp(r"(\d{2,3})[\s\w\/]+(\d{2,3})");
      final match = bpRegex.firstMatch(lower);
      if (match != null) {
        return {
          "type": "bp",
          "systolic": int.parse(match.group(1)!),
          "diastolic": int.parse(match.group(2)!),
          "raw": text
        };
      }
    }
    
    // Heart Rate: "heart rate 75", "pulse 75"
    if (lower.contains("heart") || lower.contains("pulse") || lower.contains("rate")) {
       final RegExp hrRegex = RegExp(r"(\d{2,3})");
       // Find the number near the keyword
       // Simple search
       final matches = hrRegex.allMatches(lower);
       for (final m in matches) {
           // Heuristic: usually 50-200
           int val = int.parse(m.group(1)!);
           if (val > 30 && val < 220) {
              return {
                  "type": "hr",
                  "bpm": val,
                  "raw": text
              };
           }
       }
    }
    
    // Weight: "weight 70", "70 kilos"
    if (lower.contains("weight") || lower.contains("kg") || lower.contains("kilos") || lower.contains("pounds") || lower.contains("lbs")) {
        final RegExp wRegex = RegExp(r"(\d{2,3}(\.\d)?)");
        final match = wRegex.firstMatch(lower);
        if (match != null) {
            return {
                "type": "weight",
                "value": double.parse(match.group(1)!),
                "unit": (lower.contains("pound") || lower.contains("lbs")) ? "lbs" : "kg",
                "raw": text
            };
        }
    }
    
    // Sleep: "sleep 7 hours"
    if (lower.contains("sleep") || lower.contains("slept")) {
         final RegExp sRegex = RegExp(r"(\d{1,2})(\.\d)?");
         final match = sRegex.firstMatch(lower);
         if (match != null) {
             return {
                 "type": "sleep",
                 "hours": double.parse(match.group(1)!),
                 "raw": text
             };
         }
    }
    
    return null;
  }
}
