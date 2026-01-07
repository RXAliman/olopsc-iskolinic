import 'package:vvella/services/hive/health_log.dart';

enum CommandType {
  logBloodPressure,
  logBloodSugar,
  logExercise,
  logMeal,
  logSleep,
  logWaterIntake,
  logWeight,
  unknown,
  error,
}

class Command {
  final CommandType type;
  final Map<String, dynamic> data;

  const Command({
    required this.type,
    required this.data,
  });
}

class CommandService {
  bool _phraseContainsKeywords(String word, List<String> keywords) {
    for (String kw in keywords) {
      if (word.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  Command _parse(String command) {
    if (_phraseContainsKeywords(command, ['log','track','record', 'i have', 'note'])) {
      // Blood Pressure
      if (_phraseContainsKeywords(command, ['blood pressure'])) {
        final RegExp bpExp = RegExp(
          r'(\d+)\s*(over|\/|and)\s*(\d+)',
          caseSensitive: false,
        );
        final Match? match = bpExp.firstMatch(command.toLowerCase());
        if (match != null) {
          final String? systoleStr = match.group(1);
          final String? diastoleStr = match.group(3);
          if (systoleStr != null && diastoleStr != null) {
            try {
              final int systole = int.parse(systoleStr);
              final int diastole = int.parse(diastoleStr);
              return Command(
                type: CommandType.logBloodPressure,
                data: {
                  "systole": systole,
                  "diastole": diastole,
                },
              );
            } catch (e) {
              print('Parsing Error: Could not convert captured strings to integers: $e');
              return Command(
                type: CommandType.error, 
                data: {
                  'cause': 'logging blood pressure'
                }
              );
            }
          }
        }
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging blood pressure'
          }
        );
      }
      // Blood Sugar Level
      else if (_phraseContainsKeywords(command, ['blood sugar','glucose'])) {
        final RegExp sugarExp = RegExp(
          r'(\d+)\s*(mg\/dl|mmol\/l|mg|mmol|units|milligrams per deciliter|milligram per deciliter|millimoles per liter|millimole per liter)',
          caseSensitive: false, 
        );
        final Match? match = sugarExp.firstMatch(command.toLowerCase());
        if (match != null) {
          final String? valueStr = match.group(1);
          final String? unitStr = match.group(2);
          if (valueStr != null && unitStr != null) {
            try {
              final double value = double.parse(valueStr);
              if (_phraseContainsKeywords(unitStr, ['mg/dl','mg','milligram','units'])) {
                return Command(
                  type: CommandType.logBloodSugar,
                  data: {
                    "reading": value,
                    "unit": "mg/dl",
                  }
                );
              }
              else if (_phraseContainsKeywords(unitStr, ['mmol/L','mmol','millimoles'])) {
                return Command(
                  type: CommandType.logBloodSugar,
                  data: {
                    "reading": value,
                    "unit": "mmol/L",
                  }
                );
              }
              else {
                return Command(
                  type: CommandType.error, 
                  data: {
                    'cause': 'logging blood sugar level'
                  },
                );
              }
            } catch (e) {
              print('Parsing Error: Could not convert blood sugar value to integer: $e');
              return Command(
                type: CommandType.error, 
                data: {
                  'cause': 'logging blood sugar level'
                },
              );
            }
          }
        }
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging blood sugar level'
          },
        );
      }
      // Weight
      else if (_phraseContainsKeywords(command, ['weight','weighted'])) {
        final RegExp weightExp = RegExp(
          r'(\d+)\s*(kilograms|kg|pounds|lbs)',
          caseSensitive: false,
        );
        final Match? match = weightExp.firstMatch(command);
        if (match != null) {
          final String? amountStr = match.group(1);
          final String? unitStr = match.group(2);
          if (amountStr != null && unitStr != null) {
            try {
              final double amount = double.parse(amountStr);
              String normalizedUnit;
              if (unitStr.startsWith('k')) {
                normalizedUnit = 'kilogram';
              } else {
                normalizedUnit = 'pound';
              }
              return Command(
                type: CommandType.logWeight,
                data: {
                  "amount": amount,
                  "unit": normalizedUnit,
                }
              );
            } catch (e) {
              print('Parsing Error: Could not convert weight value to integer: $e');
              return Command(
                type: CommandType.error, 
                data: {
                  'cause': 'logging weight'
                },
              );
            }
          }
        }
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging weight'
          },
        );
      }
      else if (_phraseContainsKeywords(command, ['exercise','workout','activity'])) {
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging exercise'
          },
        );
      }
      else if (_phraseContainsKeywords(command, ['meal','ate','eat'])) {
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging meal'
          },
        );
      }
      else if (_phraseContainsKeywords(command, ['sleep','nap','sleeping'])) {
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging sleep'
          },
        );
      }
      else if (_phraseContainsKeywords(command, ['water','hydration','drink','drank'])) {
        return Command(
          type: CommandType.error, 
          data: {
            'cause': 'logging water intake'
          },
        );
      }
      else {
        return Command(
          type: CommandType.unknown, 
          data: {},
        );
      }
    }
    else {
      return Command(
        type: CommandType.unknown,
        data: {},
      );
    }
  }

  static Future<String> process(String command) async {
    final instance = CommandService();
    final DateTime datetime = DateTime.now();

    Command parsed = instance._parse(command.trim().toLowerCase());
    switch (parsed.type) {
    case CommandType.logBloodPressure:
      int sys = parsed.data['systole'];
      int dia = parsed.data['diastole'];
      await HealthLogService.addBloodPressureLog(
        date: datetime, 
        systolic: sys, 
        diastolic: dia,
      );
      return "Got it. Logging your blood pressure as $sys over $dia.";
    case CommandType.logBloodSugar:
      double amount = parsed.data['reading'];
      if (parsed.data['unit'] == 'mg/dl' || parsed.data['unit'] == 'units') {
        await HealthLogService.addBloodSugarLog(
          date: datetime, 
          readingInMilligramPerDeciliter: amount,
        );
        return "Got it. Logging your blood sugar level as $amount milligram per deciliter.";
      }
      else {
        await HealthLogService.addBloodSugarLog(
          date: datetime, 
          readingInMilligramPerDeciliter: amount * 18,
        );
        return "Got it. Logging your blood sugar level as ${amount * 18} milligram per deciliter converted from $amount millimoles per liter.";
      }
    case CommandType.logWeight:
      double amount = parsed.data['amount'];
      if (parsed.data['unit'] == 'kg' || parsed.data['unit'] == 'kilogram') {
        await HealthLogService.addWeightLog(
          date: datetime,
          weightInKilograms: amount,
        );
        return "Got it. Logging your weight data as $amount kilograms.";
      }
      else {
        await HealthLogService.addWeightLog(
          date: datetime, 
          weightInKilograms: amount * 2.20462,
        );
        return "Got it. Logging your weight data as ${amount * 2.20462} kilograms converted from $amount pounds.";
      }
    case CommandType.error:
      return "Sorry. An error has occured when ${parsed.data['cause']}.";
    case CommandType.unknown:
    default:
      return "Sorry. I couldn't identify that command. Please try again with a health term.";
    }
  }
}