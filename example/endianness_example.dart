import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.0.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }

  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  var int32Reg = ModbusInt32Register(
      name: "int32", address: 14, type: ModbusElementType.holdingRegister);

  var req =
      int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.ABCD);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 24;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.DCBA);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 34;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.BADC);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 44;
  req = int32Reg.getWriteRequest(123456789, endianness: ModbusEndianness.CDAB);
  await modbusClient.send(req);
  print(int32Reg.value);

  int32Reg.address = 14;
  var readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.ABCD);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 24;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.DCBA);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 34;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.BADC);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  int32Reg.address = 44;
  readReq = int32Reg.getReadRequest(endianness: ModbusEndianness.CDAB);
  await modbusClient.send(readReq);
  print(int32Reg.value);

  modbusClient.disconnect();
}
