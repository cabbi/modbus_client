import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';
import 'package:test/test.dart';

void main() {
  group("Tests endianness for uint32", () {
    var num = 4159429653;
    test('uint32 AB CD', () {
      var bytes = Uint8List.fromList([0xF7, 0xEB, 0xDC, 0x15]);
      var reg = ModbusUint32Register(
          name: "int32", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, 4159429653);
    });
    test('uint32 DC BA', () {
      var bytes = Uint8List.fromList([0x15, 0xDC, 0xEB, 0xF7]);
      var reg = ModbusUint32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.DCBA);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, 4159429653);
    });
    test('uint32 BA DC', () {
      var bytes = Uint8List.fromList([0xEB, 0xF7, 0x15, 0xDC]);
      var reg = ModbusUint32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.BADC);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, 4159429653);
    });
    test('uint32 CD AB', () {
      var bytes = Uint8List.fromList([0xDC, 0x15, 0xF7, 0xEB]);
      var reg = ModbusUint32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.CDAB);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, 4159429653);
    });
  });
  group('Tests endianness for int32', () {
    test('int32 AB CD', () {
      var reg = ModbusInt32Register(
          name: "int32", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), [0xF7, 0xEB, 0xDC, 0x15]);
    });
    test('int32 DC BA', () {
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.DCBA);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), [0x15, 0xDC, 0xEB, 0xF7]);
    });
    test('int32 BA DC', () {
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.BADC);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), [0xEB, 0xF7, 0x15, 0xDC]);
    });
    test('int32 CD AB', () {
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.CDAB);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), [0xDC, 0x15, 0xF7, 0xEB]);
    });
  });
}
