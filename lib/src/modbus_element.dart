library modbus_element;

import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:modbus_client/modbus_client.dart';

// All defined element types
part 'element_type/modbus_element_bit.dart';
part 'element_type/modbus_element_num.dart';
part 'element_type/modbus_element_enum.dart';
part 'element_type/modbus_element_status.dart';
part 'element_type/modbus_element_bitmask.dart';
part 'element_type/modbus_element_epoch.dart';

/// The base element class
abstract class ModbusElement<T> {
  final String name;
  final String description;
  final ModbusElementType type;
  final int address;
  final int byteCount;
  T? _value;

  ModbusElement(
      {required this.name,
      this.description = "",
      required this.type,
      required this.address,
      required this.byteCount});

  T? get value => _value;
  set value(dynamic newValue) => _value = newValue;
  T? setValueFromBytes(Uint8List rawValues);

  /// Gets a read request from this element
  ModbusReadRequest getReadRequest({int? unitId}) {
    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.readFunction.code)
      ..setUint16(1, address)
      ..setUint16(3, byteCount > 1 ? byteCount ~/ 2 : 1);
    return ModbusReadRequest(this, pdu, unitId);
  }

  /// Gets a write request from this element.
  /// [value] is set to the element once request is successfully completed.
  /// If [rawValue] is true then the integer [value] is written as it is
  /// without any value or type conversion.
  ModbusWriteRequest getWriteRequest(dynamic value,
      {bool rawValue = false, int? unitId}) {
    if (type.writeSingleFunction == null) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "$type element does not support write request!");
    }
    // Build the request object
    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.writeSingleFunction!.code)
      ..setUint16(1, address)
      ..setUint16(3, rawValue ? value as int : _getRawValue(value));
    return ModbusWriteRequest(this, pdu, unitId);
  }

  int _getRawValue(dynamic value);

  @override
  String toString() =>
      "$name: $_valueStr${description == '' ? '' : ' [$description]'}";

  String get _valueStr => _value == null ? "<none>" : _value.toString();
}
