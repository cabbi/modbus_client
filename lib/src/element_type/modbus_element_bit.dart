part of modbus_element;

/// A Modbus bit value element. This is the base class of [ModbusDiscreteInput]
/// and [ModbusCoil] elements.
class ModbusBitElement extends ModbusElement<bool> {
  ModbusBitElement(
      {required super.name,
      super.description,
      required super.address,
      required super.type,
      super.onUpdate})
      : super(byteCount: 1);

  @override
  set value(dynamic newValue) =>
      newValue is num ? super.value = newValue != 0 : super.value = newValue;
  @override
  bool? setValueFromBytes(Uint8List rawValues) =>
      super.value = (rawValues.first & 0x01) != 0;

  @override

  /// NOTE: [rawValue] is ignored for bit elements!
  ModbusWriteRequest getWriteRequest(dynamic value,
      {bool rawValue = false, int? unitId, Duration? responseTimeout}) {
    return super.getWriteRequest(value,
        rawValue: false, unitId: unitId, responseTimeout: responseTimeout);
  }

  @override
  int _getRawValue(dynamic value) => value is bool
      ? !value
          ? 0x0000
          : 0xFF00
      : value == 0
          ? 0x0000
          : 0xFF00;
}

/// A Modbus [ModbusElementType.discreteInput] value element.
class ModbusDiscreteInput extends ModbusBitElement {
  ModbusDiscreteInput(
      {required super.name, super.description, required super.address})
      : super(type: ModbusElementType.discreteInput);
}

/// A Modbus [ModbusElementType.coil] value element.
class ModbusCoil extends ModbusBitElement {
  ModbusCoil({required super.name, super.description, required super.address})
      : super(type: ModbusElementType.coil);
}
