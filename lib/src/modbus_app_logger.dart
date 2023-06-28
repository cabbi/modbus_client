import 'package:logging/logging.dart';

/// A simple application logger.
class ModbusAppLogger {
  static Logger? _logger;

  /// Logs all requested [level] logs. If [onLog] is omitted a simple print is
  /// performed.
  ModbusAppLogger(Level level, [Function(LogRecord)? onLog]) {
    // Enable hierarchical logging to only trace this specific _logger logs
    hierarchicalLoggingEnabled = true;
    _logger = Logger("ModbusAppLogger");
    _logger!.level = level;
    _logger!.onRecord.listen(onLog != null
        ? (log) => onLog(log)
        : (log) {
            print('${log.level.name}: ${log.time} - ${log.message}');
            if (log.error != null) {
              print(log.error);
            }
          });
  }

  static void log(Level logLevel, Object? message,
      [Object? error, StackTrace? stackTrace]) {
    if (_logger != null) {
      _logger!.log(logLevel, message, error, stackTrace);
    }
  }

  static void info(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.INFO, message, error, stackTrace);

  static void shout(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.SHOUT, message, error, stackTrace);

  static void severe(Object? message,
          [Object? error, StackTrace? stackTrace]) =>
      log(Level.SEVERE, message, error, stackTrace);

  static void config(Object? message,
          [Object? error, StackTrace? stackTrace]) =>
      log(Level.CONFIG, message, error, stackTrace);

  static void warning(Object? message,
          [Object? error, StackTrace? stackTrace]) =>
      log(Level.WARNING, message, error, stackTrace);

  static void fine(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINE, message, error, stackTrace);

  static void finer(Object? message, [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINER, message, error, stackTrace);

  static void finest(Object? message,
          [Object? error, StackTrace? stackTrace]) =>
      log(Level.FINEST, message, error, stackTrace);

  static String toHex(Iterable<int> bytes) {
    StringBuffer hexStr = StringBuffer();
    for (var byte in bytes) {
      hexStr.write(byte.toRadixString(16).padLeft(2, "0").toUpperCase());
      hexStr.write(" ");
    }
    return hexStr.toString();
  }
}
