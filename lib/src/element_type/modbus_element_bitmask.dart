part of modbus_element;

/// A Modbus bit mask type used by [ModbusBitMaskRegister].
/// If the specified register [bit] number (0 based index) is 1 then [isActive]
/// is set to true and the bit mask [value] returns the [activeValue] else the
/// [inactiveValue].
class ModbusBitMask {
  final int bit;
  bool isActive = false;
  final dynamic activeValue;
  final dynamic inactiveValue;
  ModbusBitMask(this.bit, this.activeValue, [this.inactiveValue]);

  dynamic get value => isActive ? activeValue : inactiveValue;

  @override
  String toString() => value == null ? "" : value.toString();

  /// Sets to [pduValue] this bit-mask bit to 1 or 0 based on [isActive] value.
  int _setBit(int pduValue) {
    return isActive ? pduValue | (1 << bit) : pduValue & (~(1 << bit));
  }
}

/// This Uint16 register type sets the value of a list of [ModbusBitMask]
/// objects.
class ModbusBitMaskRegister extends ModbusElement<List<ModbusBitMask>> {
  final Map<int, ModbusBitMask> bitMaskMap = {};

  ModbusBitMaskRegister(
      {required super.name,
      required super.address,
      required super.type,
      super.description,
      super.onUpdate,
      required List<ModbusBitMask> bitMasks})
      : super(byteCount: 2) {
    _value = bitMasks;
    for (var bitMask in bitMasks) {
      bitMaskMap[bitMask.bit] = bitMask;
    }
  }

  @override
  int _getRawValue(dynamic value) {
    // Expecting a List of ModbusBitMask
    if (value! is List<ModbusBitMask>) {
      throw ModbusException(
          context: "ModbusBitElement",
          msg: "Write request expects value to be List<ModbusBitMask>!");
    }
    int pduValue = 0;
    for (ModbusBitMask bitMask in value) {
      pduValue = bitMask._setBit(pduValue);
    }
    return pduValue;
  }

  @override
  List<ModbusBitMask>? setValueFromBytes(Uint8List rawValues) {
    bool anyChange = false;
    var rawValue = ByteData.view(rawValues.buffer).getUint16(0);
    int mask = 0x01;
    for (int bit = 0; bit < 16; bit++) {
      var bitMask = bitMaskMap[bit];
      if (bitMask != null) {
        var newValue = (rawValue & mask) != 0;
        if (bitMask.isActive != newValue) {
          anyChange = true;
        }
        bitMask.isActive = newValue;
      }
      mask <<= 1;
    }
    if (anyChange && onUpdate != null) {
      onUpdate!(this);
    }
    return _value;
  }
}
