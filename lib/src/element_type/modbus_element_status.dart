part of modbus_element;

/// A Modbus status type used by [ModbusStatusRegister]
class ModbusStatus {
  final int statusValue;
  final String statusText;
  ModbusStatus(this.statusValue, this.statusText);
}

/// This register type converts an Uint16 device value into a [ModbusStatus].
class ModbusStatusRegister extends ModbusElement<ModbusStatus> {
  final List<ModbusStatus> statusValues;
  final ModbusStatus? defaultStatus;

  ModbusStatusRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      required this.statusValues,
      this.defaultStatus})
      : super(byteCount: 2);

  @override
  int _getRawValue(dynamic value) {
    // Expecting a ModbusStatus object
    if (value! is ModbusStatus) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "Write request expects value to be 'ModbusStatus'!");
    }
    return value.statusValue;
  }

  @override
  ModbusStatus? setValueFromBytes(Uint8List rawValues) {
    var rawValue = ByteData.view(rawValues.buffer).getUint16(0);
    value = statusValues.firstWhere((val) {
      return val.statusValue == rawValue;
    },
        orElse: () => defaultStatus != null
            ? defaultStatus!
            : throw ModbusException(
                context: "ModbusBitElement",
                msg: "No status assigned to $rawValue!"));
    return _value;
  }

  @override
  String get _valueStr => _value == null ? "<none>" : _value!.statusText;
}
