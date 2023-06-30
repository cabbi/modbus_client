part of modbus_element;

/// A numeric register where [type] can be [ModbusElementType.inputRegister] or
/// [ModbusElementType.inputRegister]. The returned device value
/// (i.e. raw value) can be of type Int16, Uint16, Int32 or Uint32.
///
/// This raw value might be converted into an engineering value by this formula:
///    engineering value = raw value * [multiplier] + [offset]
///
/// The string representation of the engineering value can have a unit of
/// measure [uom] and rounded decimal places [viewDecimalPlaces].
abstract class ModbusNumRegister<T extends num> extends ModbusElement<T> {
  final double multiplier;
  final double offset;
  final String uom;
  final int viewDecimalPlaces;

  ModbusNumRegister(
      {required super.name,
      super.description,
      super.onUpdate,
      required super.type,
      required super.address,
      required super.byteCount,
      this.uom = "",
      this.multiplier = 1,
      this.offset = 0,
      this.viewDecimalPlaces = 2});

  @override
  ModbusWriteRequest getWriteRequest(dynamic value,
      {bool rawValue = false, int? unitId, Duration? responseTimeout}) {
    switch (byteCount) {
      case 2:
        return super.getWriteRequest(value,
            rawValue: rawValue,
            unitId: unitId,
            responseTimeout: responseTimeout);
      case 4:
        return _getWriteRequest32(value,
            rawValue: rawValue,
            unitId: unitId,
            responseTimeout: responseTimeout);
    }
    throw ModbusException(
        context: "ModbusNumRegister",
        msg: "$type element does not support write request!");
  }

  ModbusWriteRequest _getWriteRequest32(dynamic value,
      {required bool rawValue, int? unitId, Duration? responseTimeout}) {
    if (type.writeMultipleFunction == null) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "$type element does not support 32 bits write request!");
    }
    // Build the request object
    var pdu = Uint8List(10);
    ByteData.view(pdu.buffer)
      ..setUint8(0, type.writeMultipleFunction!.code)
      ..setUint16(1, address)
      ..setUint16(3, 2) // value register count
      ..setUint8(5, 4) // value byte count
      ..setUint32(6, rawValue ? value : _getRawValue(value));
    return ModbusWriteRequest(this, pdu,
        unitId: unitId, responseTimeout: responseTimeout);
  }

  @override
  int _getRawValue(dynamic value) => (value - offset) ~/ multiplier;

  @override
  T? setValueFromBytes(Uint8List rawValues) {
    return value = (_getValueFromData(rawValues) * multiplier) + offset as T;
  }

  @override
  String get _valueStr => _value == null
      ? "<none>"
      : "${_value!.toStringAsFixed(viewDecimalPlaces).replaceFirst(RegExp(r'\.?0*$'), '')}$uom";

  int _getValueFromData(Uint8List rawValues);
}

/// A signed 16 bit register
class ModbusInt16Register extends ModbusNumRegister {
  ModbusInt16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier = 1,
      super.offset = 0})
      : super(byteCount: 2);

  @override
  int _getValueFromData(Uint8List rawValues) =>
      ByteData.view(rawValues.buffer, 0, 2).getInt16(0);
}

/// An unsigned 16 bit register
class ModbusUint16Register extends ModbusNumRegister {
  ModbusUint16Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier = 1,
      super.offset = 0})
      : super(byteCount: 2);

  @override
  int _getValueFromData(Uint8List rawValues) =>
      ByteData.view(rawValues.buffer, 0, 2).getUint16(0);
}

/// A signed 32 bit register
class ModbusInt32Register extends ModbusNumRegister {
  ModbusInt32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier = 1,
      super.offset = 0})
      : super(byteCount: 4);

  @override
  int _getValueFromData(Uint8List rawValues) =>
      ByteData.view(rawValues.buffer, 0, 4).getInt32(0);
}

/// An unsigned 32 bit register
class ModbusUint32Register extends ModbusNumRegister {
  ModbusUint32Register(
      {required super.name,
      required super.address,
      required super.type,
      super.uom,
      super.description,
      super.onUpdate,
      super.multiplier = 1,
      super.offset = 0})
      : super(byteCount: 4);

  @override
  int _getValueFromData(Uint8List rawValues) =>
      ByteData.view(rawValues.buffer, 0, 4).getUint32(0);
}
