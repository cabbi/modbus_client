library modbus_client;

export 'src/modbus_client.dart';
export 'src/modbus_request.dart';
export 'src/modbus_element.dart';
export 'src/modbus_element_group.dart';
export 'src/modbus_app_logger.dart';

/// The Modbus standard function codes.
enum ModbusFunctionCode {
  readCoils(0x01),
  readDiscreteInputs(0x02),
  readHoldingRegisters(0x03),
  readInputRegisters(0x04),
  writeSingleCoil(0x05),
  writeSingleHoldingRegister(0x06),
  writeMultipleCoils(0x0F),
  writeMultipleHoldingRegisters(0x10);

  const ModbusFunctionCode(this.code);
  final int code;

  bool get isRead => isReadFunction(code);
  bool get isWrite => isWriteFunction(code);
  bool get isWriteSingle => isWriteSingleFunction(code);
  bool get isWriteMultiple => isWriteMultipleFunction(code);

  static bool isReadFunction(code) => 0x00 < code && code <= 0x04;
  static bool isWriteFunction(code) => 0x04 < code && code <= 0x10;
  static bool isWriteSingleFunction(code) => code == 0x05 || code == 0x06;
  static bool isWriteMultipleFunction(code) => code == 0x0F || code == 0x10;
  static bool isSpecialFunction(code) => code > 0x10;
}

/// The Modbus element types.
enum ModbusElementType {
  /// Single bit [Read-Only]
  discreteInput(ModbusFunctionCode.readDiscreteInputs),

  /// Single bit [Read-Write]
  coil(ModbusFunctionCode.readCoils, ModbusFunctionCode.writeSingleCoil,
      ModbusFunctionCode.writeMultipleCoils),

  /// 16-bit word [Read-Only]
  inputRegister(ModbusFunctionCode.readInputRegisters),

  /// 16-bit word [Read-Write]
  holdingRegister(
      ModbusFunctionCode.readHoldingRegisters,
      ModbusFunctionCode.writeSingleHoldingRegister,
      ModbusFunctionCode.writeMultipleHoldingRegisters);

  const ModbusElementType(this.readFunction,
      [this.writeSingleFunction, this.writeMultipleFunction]);

  final ModbusFunctionCode readFunction;
  final ModbusFunctionCode? writeSingleFunction;
  final ModbusFunctionCode? writeMultipleFunction;

  /// True if the element type represents a registry type
  bool get isRegister =>
      this == ModbusElementType.inputRegister ||
      this == ModbusElementType.holdingRegister;

  /// True if the element type represents a bit type
  bool get isBit => !isRegister;
}

/// The Modbus response codes.
///
/// These codes represents both standard Modbus exception code and custom code
/// used by this library to return requests response code.
///
/// [code] represents the numeric value of the response code.
/// [isStandardModbusExceptionCode] is set to true if the code represents a
/// Modbus standard code.
enum ModbusResponseCode {
  /* Modbus standard exception codes */
  illegalFunction(0x01),
  illegalDataAddress(0x02),
  illegalDataValue(0x03),
  deviceFailure(0x04),
  acknowledge(0x05),
  // The device accepts the request but needs a long time to process it.
  // This code is used to prevent client response timeout.
  deviceBusy(0x06),
  // The device is busy processing another command.
  negativeAcknowledgment(0x07),
  // The device cannot perform the programming request sent by the client.
  memoryParityError(0x08),
  // The device detects a parity error in the memory when attempting to read
  // extended memory.
  gatewayPathUnavailable(0x0A),
  // The gateway is overloaded or not correctly configured.
  gatewayTargetDeviceFailedToRespond(0x0B),
  // The device is not present on the network

  /* Custom to handle all possible request results */
  requestSucceed(0x00, false),
  requestTimeout(0xF0, false),
  connectionFailed(0xF1, false),
  requestTxFailed(0xF2, false),
  requestRxFailed(0xF3, false),
  requestRxWrongUnitId(0xF4, false),
  requestRxWrongFunctionCode(0xF5, false),
  requestRxWrongChecksum(0xF6, false),
  undefinedErrorCode(0xFF, false);

  const ModbusResponseCode(this.code,
      [this.isStandardModbusExceptionCode = true]);
  final int code;
  final bool isStandardModbusExceptionCode;

  factory ModbusResponseCode.fromCode(int code) =>
      values.singleWhere((e) => code == e.code,
          orElse: () => ModbusResponseCode.undefinedErrorCode);
}

/// The connection mode used when sending a request.
enum ModbusConnectionMode {
  /// Requires manual connection of the client before sending requests.
  /// Sending the request will fail if client is not connected.
  doNotConnect,

  /// Client will be connected if not already before sending the
  /// requests. After request has been sent, client is disconnected.
  autoConnectAndDisconnect,

  /// Client will be connected if not already before sending the
  /// requests. After request has been sent, client is disconnected.
  autoConnectAndKeepConnected,
}

/// The modbus_client package base [Exception] class.
class ModbusException implements Exception {
  final String context;
  final String msg;

  ModbusException({required this.context, required this.msg});

  @override
  String toString() => "[$context] $msg";
}
