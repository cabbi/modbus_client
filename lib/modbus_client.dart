// ignore_for_file: constant_identifier_names

library modbus_client;

import 'dart:typed_data';

export 'src/modbus_client.dart';
export 'src/modbus_request.dart';
export 'src/modbus_element.dart';
export 'src/modbus_element_group.dart';
export 'src/modbus_app_logger.dart';
export 'src/modbus_file_record.dart';

enum FunctionType { read, writeSingle, writeMultiple, custom }

abstract class FunctionCode {
  int get code;
  FunctionType get type;
}

/// The Modbus standard function codes.
class ModbusFunctionCode implements FunctionCode {
  static const ModbusFunctionCode readCoils =
      ModbusFunctionCode(0x01, FunctionType.read);
  static const ModbusFunctionCode readDiscreteInputs =
      ModbusFunctionCode(0x02, FunctionType.read);
  static const ModbusFunctionCode readHoldingRegisters =
      ModbusFunctionCode(0x03, FunctionType.read);
  static const ModbusFunctionCode readInputRegisters =
      ModbusFunctionCode(0x04, FunctionType.read);
  static const ModbusFunctionCode writeSingleCoil =
      ModbusFunctionCode(0x05, FunctionType.writeSingle);
  static const ModbusFunctionCode writeSingleHoldingRegister =
      ModbusFunctionCode(0x06, FunctionType.writeSingle);
  static const ModbusFunctionCode writeMultipleCoils =
      ModbusFunctionCode(0x0F, FunctionType.writeMultiple);
  static const ModbusFunctionCode writeMultipleHoldingRegisters =
      ModbusFunctionCode(0x10, FunctionType.writeMultiple);

  @override
  final int code;
  @override
  final FunctionType type;

  const ModbusFunctionCode(this.code, this.type);
}

/// The Modbus element types.
class ModbusElementType {
  /// Single bit [Read-Only]
  static const ModbusElementType discreteInput =
      ModbusElementType(ModbusFunctionCode.readDiscreteInputs);

  /// Single bit [Read-Write]
  static const ModbusElementType coil = ModbusElementType(
      ModbusFunctionCode.readCoils,
      ModbusFunctionCode.writeSingleCoil,
      ModbusFunctionCode.writeMultipleCoils);

  /// 16-bit word [Read-Only]
  static const ModbusElementType inputRegister =
      ModbusElementType(ModbusFunctionCode.readInputRegisters);

  /// 16-bit word [Read-Write]
  static const ModbusElementType holdingRegister = ModbusElementType(
      ModbusFunctionCode.readHoldingRegisters,
      ModbusFunctionCode.writeSingleHoldingRegister,
      ModbusFunctionCode.writeMultipleHoldingRegisters);

  const ModbusElementType(this.readFunction,
      [this.writeSingleFunction, this.writeMultipleFunction]);

  final FunctionCode readFunction;
  final FunctionCode? writeSingleFunction;
  final FunctionCode? writeMultipleFunction;

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

/// The type of endianness applied to number conversions
enum ModbusEndianness {
  ABCD(swapWord: false, swapByte: false),
  CDAB(swapWord: true, swapByte: false),
  BADC(swapWord: false, swapByte: true),
  DCBA(swapWord: true, swapByte: true);

  final bool swapWord;
  final bool swapByte;

  const ModbusEndianness({required this.swapWord, required this.swapByte});

  factory ModbusEndianness.from(
      {required bool swapWord, required bool swapByte}) {
    if (swapWord) {
      return swapByte ? DCBA : CDAB;
    } else {
      return swapByte ? BADC : ABCD;
    }
  }

  Uint8List getEndianBytes(Uint8List bytes) {
    var len = bytes.lengthInBytes;
    if (swapWord && swapByte) {
      for (int i = 0; i < len ~/ 2; i++) {
        var byte = bytes[i];
        bytes[i] = bytes[len - i - 1];
        bytes[len - i - 1] = byte;
      }
    } else if (swapByte) {
      for (int i = 0; i < len; i += 2) {
        var byte = bytes[i];
        bytes[i] = bytes[i + 1];
        bytes[i + 1] = byte;
      }
    } else if (swapWord) {
      for (int i = 0; i < len ~/ 2; i++) {
        var byte = bytes[i];
        bytes[i] = bytes[len - i - 2];
        bytes[len - i - 2] = byte;
        i++;
        byte = bytes[i];
        bytes[i] = bytes[len - i];
        bytes[len - i] = byte;
      }
    }
    return bytes;
  }
}

/// The modbus_client package base [Exception] class.
class ModbusException implements Exception {
  final String context;
  final String msg;

  ModbusException({required this.context, required this.msg});

  @override
  String toString() => "[$context] $msg";
}
