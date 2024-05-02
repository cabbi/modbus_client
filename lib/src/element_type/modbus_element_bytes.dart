part of '../modbus_element.dart';

/// This register type reads and writes byte array.
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
      {bool rawValue = false, int? unitId, Duration? responseTimeout}) {
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
    // Build the request object
    var pdu = Uint8List(6 + value.length);
    pdu.setAll(6, value);
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.writeMultipleFunction!.code)
      ..setUint16(1, address)
      ..setUint16(3, value.length ~/ 2) // value register count
      ..setUint8(5, value.length); // value byte count
    return ModbusWriteRequest(this, pdu, type.writeMultipleFunction!,
        unitId: unitId, responseTimeout: responseTimeout);
  }
}
