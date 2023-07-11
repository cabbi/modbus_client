part of modbus_element;

/// The Modbus epoch type used by [ModbusEpochRegister].
enum ModbusEpochType { seconds, milliseconds }

// TODO: lets have a uint64 register for the milliseconds implementation!

/// This Uint32 register type converts the device epoch value into a [DateTime].
class ModbusEpochRegister extends ModbusElement<DateTime> {
  final bool isUtc;
  final ModbusEpochType epochType = ModbusEpochType.seconds;

  ModbusEpochRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      this.isUtc = false})
      : super(byteCount: 4);

  @override
  DateTime? setValueFromBytes(Uint8List rawValues) {
    var rawValue = ByteData.view(rawValues.buffer).getUint32(0);
    return value = DateTime.fromMillisecondsSinceEpoch(
        epochType == ModbusEpochType.seconds ? rawValue * 1000 : rawValue);
  }

  @override
  int _getRawValue(dynamic value) {
    // Expecting a DateTime object
    if (value! is DateTime) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "Write request expects value to be 'DateTime'!");
    }
    return epochType == ModbusEpochType.milliseconds
        ? value.millisecondsSinceEpoch
        : value.millisecondsSinceEpoch ~/ 1000;
  }
}
