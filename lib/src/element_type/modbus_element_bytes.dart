part of '../modbus_element.dart';

/// This register type reads and writes byte array.
///
/// The [byteCount] cannot exceed 250 bytes which is the multiple read
/// bytes limit for Modbus/RTU. Note that the protocol limit depends on multiple
/// factors:
///  - Read & Write have different limits
///  - Modbus RTU and TCP have different limits
///  - Device dependent limits
/// To get the right limit please refer to Modbus specs and your device manual.
class ModbusBytesRegister extends ModbusElement<Uint8List> {
  ModbusBytesRegister({
    required super.name,
    required super.address,
    required super.byteCount,
    super.description,
    super.onUpdate,
    super.type = ModbusElementType.holdingRegister,
  }) {
    // Expecting an even length since we are handling 16 bit registers
    if (byteCount % 2 != 0) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "'byteCount' must be an even number!");
    }
    // Expecting length not bigger than 250
    if (byteCount > 250) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "'byteCount' must not be greater than 250!");
    }
  }

  @override
  Uint8List _getRawValue(dynamic value) {
    // Expecting a Uint8List object
    if (value is! Uint8List) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "Write request expects value to be 'Uint8List'!");
    }
    return value;
  }

  @override
  Uint8List? setValueFromBytes(Uint8List rawValues) {
    // Expecting a same length as the original byte count
    if (rawValues.length != byteCount) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "The length of 'rawValues' must match 'byteCount'!");
    }
    _value = rawValues;
    return rawValues;
  }

  @override
  String get _valueStr => _value == null ? "" : _value.toString();

  @override
  ModbusWriteRequest getWriteRequest(dynamic value,
      {bool rawValue = false,
      int? unitId,
      Duration? responseTimeout,
      ModbusEndianness? endianness}) {
    // Expecting a Uint8List object
    if (value is! Uint8List) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "Write request expects value to be 'Uint8List'!");
    }
    // Expecting a same length as the original byte count
    if (value.length != byteCount) {
      throw ModbusException(
          context: "ModbusBytesRegister",
          msg: "The length of 'value' must match 'byteCount'!");
    }
    // Expecting a multiple write function code
    if (type.writeMultipleFunction == null) {
      throw ModbusException(
          context: "ModbusBytesRegister.getWriteRequest",
          msg: "ModbusBytesRegister requires 'writeMultipleFunction' code!");
    }
    return getMultipleWriteRequest(value,
        unitId: unitId,
        responseTimeout: responseTimeout,
        endianness: endianness);
  }
}
