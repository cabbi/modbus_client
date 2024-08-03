part of 'modbus_client_serial.dart';

/// Abstract serial port client
abstract class ModbusSerialPort {
  /// The serial port name
  String get name;

  /// True if the serial port connection is open
  bool get isOpen;

  /// Opens the serial port for reading and writing.
  Future<bool> open();

  /// Closes the serial port.
  Future<void> close();

  /// Flushes serial port buffers.
  Future<void> flush();

  /// Read data from the serial port.
  ///
  /// The operation attempts to read N `bytes` of data.
  Future<Uint8List> read(int bytes, {Duration? timeout});

  /// Write data to the serial port.
  ///
  /// Returns the amount of bytes written.
  Future<int> write(Uint8List bytes, {Duration? timeout});
}
