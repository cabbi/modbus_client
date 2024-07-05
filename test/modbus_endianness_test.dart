import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';
import 'package:test/test.dart';

void main() {
  group("Tests endianness for uint32", () {
    final num = 4159429653;
    test('uint32 AB CD', () {
      final bytes = Uint8List.fromList([0xF7, 0xEB, 0xDC, 0x15]);
      var reg = ModbusUint32Register(
          name: "int32", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, 4159429653);
    });
    test('uint32 DC BA', () {
      final bytes = Uint8List.fromList([0x15, 0xDC, 0xEB, 0xF7]);
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
      final bytes = Uint8List.fromList([0xEB, 0xF7, 0x15, 0xDC]);
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
      final bytes = Uint8List.fromList([0xDC, 0x15, 0xF7, 0xEB]);
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
    final num = -135537643;
    test('int32 AB CD', () {
      final bytes = Uint8List.fromList([0xF7, 0xEB, 0xDC, 0x15]);
      var reg = ModbusInt32Register(
          name: "int32", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('int32 DC BA', () {
      final bytes = Uint8List.fromList([0x15, 0xDC, 0xEB, 0xF7]);
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.DCBA);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('int32 BA DC', () {
      final bytes = Uint8List.fromList([0xEB, 0xF7, 0x15, 0xDC]);
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.BADC);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('int32 CD AB', () {
      final bytes = Uint8List.fromList([0xDC, 0x15, 0xF7, 0xEB]);
      var reg = ModbusInt32Register(
          name: "int32",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.CDAB);
      var write = reg.getWriteRequest(-135537643);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
  });

  group('Tests endianness for float', () {
    final num = -9.567605972290039;
    test('float AB CD', () {
      final bytes = Uint8List.fromList([0xC1, 0x19, 0x14, 0xEA]);
      var reg = ModbusFloatRegister(
          name: "float", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('float DC BA', () {
      final bytes = Uint8List.fromList([0xEA, 0x14, 0x19, 0xC1]);
      var reg = ModbusFloatRegister(
          name: "float",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.DCBA);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('float BA DC', () {
      final bytes = Uint8List.fromList([0x19, 0xC1, 0xEA, 0x14]);
      var reg = ModbusFloatRegister(
          name: "float",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.BADC);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('float CD AB', () {
      final bytes = Uint8List.fromList([0x14, 0xEA, 0xC1, 0x19]);
      var reg = ModbusFloatRegister(
          name: "float",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.CDAB);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
  });
  group('Tests endianness for double', () {
    final num = -98566587389.567605972290039;
    test('double AB CD', () {
      final bytes =
          Uint8List.fromList([0xC2, 0x36, 0xF3, 0x06, 0xC3, 0xFD, 0x91, 0x4F]);
      var reg = ModbusDoubleRegister(
          name: "double", address: 14, type: ModbusElementType.holdingRegister);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('double DC BA', () {
      final bytes =
          Uint8List.fromList([0x4F, 0x91, 0xFD, 0xC3, 0x06, 0xF3, 0x36, 0xC2]);
      var reg = ModbusDoubleRegister(
          name: "double",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.DCBA);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('double BA DC', () {
      final bytes =
          Uint8List.fromList([0x36, 0xC2, 0x06, 0xF3, 0xFD, 0xC3, 0x4F, 0x91]);
      var reg = ModbusDoubleRegister(
          name: "double",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.BADC);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
    test('double CD AB', () {
      final bytes =
          Uint8List.fromList([0x91, 0x4F, 0xC3, 0xFD, 0xF3, 0x06, 0xC2, 0x36]);
      var reg = ModbusDoubleRegister(
          name: "double",
          address: 14,
          type: ModbusElementType.holdingRegister,
          endianness: ModbusEndianness.CDAB);
      var write = reg.getWriteRequest(num);
      expect(write.protocolDataUnit.sublist(6), bytes);

      var read = reg.getReadRequest();
      read.internalSetElementData(Uint8List.fromList(bytes));
      expect(read.element.value, num);
    });
  });
}
