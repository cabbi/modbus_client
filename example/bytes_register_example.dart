import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  var bytesRegister = ModbusBytesRegister(
      name: "BytesArray",
      address: 4,
      byteCount: 10,
      onUpdate: (self) => print(self));

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  var req1 = bytesRegister.getWriteRequest(Uint8List.fromList(
      [0x01, 0x02, 0x03, 0x04, 0x05, 0x66, 0x07, 0x08, 0x09, 0x0A]));
  var res = await modbusClient.send(req1);
  print(res);

  var req2 = bytesRegister.getReadRequest();
  res = await modbusClient.send(req2);
  print(bytesRegister.value);

  modbusClient.disconnect();
}
