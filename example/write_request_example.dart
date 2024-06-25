import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

enum BatteryStatus implements ModbusIntEnum {
  offline(0),
  standby(1),
  running(2),
  fault(3),
  sleepMode(4);

  const BatteryStatus(this.intValue);

  @override
  final int intValue;

  @override
  String toString() {
    return name;
  }
}

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var batteryStatus = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 11,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values,
      onUpdate: (self) => print(self));

  // Discover the Modbus server
  var serverIp = "127.0.0.1"; //await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }

  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  var req = batteryStatus.getWriteRequest(BatteryStatus.running);
  var res = await modbusClient.send(req);
  print(res.name);

  var int32Reg = ModbusInt32Register(
      name: "int32", address: 14, type: ModbusElementType.holdingRegister);
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.ABCD);
  res = await modbusClient.send(req);
  print(int32Reg.value);
  int32Reg.address = 24;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.DCBA);
  res = await modbusClient.send(req);
  print(int32Reg.value);
  int32Reg.address = 34;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.BADC);
  res = await modbusClient.send(req);
  print(int32Reg.value);
  int32Reg.address = 44;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.CDAB);
  res = await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 14;
  var readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.ABCD);
  res = await modbusClient.send(readReq);
  print(int32Reg.value);
  int32Reg.address = 24;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.DCBA);
  res = await modbusClient.send(readReq);
  print(int32Reg.value);
  int32Reg.address = 34;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.BADC);
  res = await modbusClient.send(readReq);
  print(int32Reg.value);
  int32Reg.address = 44;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.CDAB);
  res = await modbusClient.send(readReq);
  print(int32Reg.value);

  modbusClient.disconnect();
}
