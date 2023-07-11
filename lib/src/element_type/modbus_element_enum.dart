part of modbus_element;

/// A Modbus enumeration type used by [ModbusEnumRegister]
abstract class ModbusIntEnum {
  int get intValue;
}

/// An enumeration register. The Uin16 register value is converted into a user
/// defined enumeration.
/// Example:
///   enum BatteryStatus implements ModbusIntEnum {
///     offline(0),
///     standby(1),
///     running(2),
///     fault(3),
///     sleepMode(4);
///
///     const BatteryStatus(this.intValue);
///     @override
///     final int intValue;
///   }
///
///   var batteryStatus = ModbusEnumRegister(
///     name: "BatteryStatus",
///     address: 37000,
///     enumValues: BatteryStatus.values);
class ModbusEnumRegister<T extends ModbusIntEnum> extends ModbusElement<T> {
  final List<T> enumValues;
  final T? defaultValue;

  ModbusEnumRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      required this.enumValues,
      this.defaultValue})
      : super(byteCount: 2);

  @override
  T? setValueFromBytes(Uint8List rawValues) {
    var rawValue = ByteData.view(rawValues.buffer).getUint16(0);
    value = enumValues.firstWhereOrNull((val) {
          return val.intValue == rawValue;
        }) ??
        defaultValue;
    return _value;
  }

  @override
  int _getRawValue(dynamic value) {
    // Expecting a ModbusIntEnum object
    if (value is! ModbusIntEnum) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "Write request expects value to be 'ModbusIntEnum'!");
    }
    return value.intValue;
  }
}
