import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client/src/modbus_file_record.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.8.0");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }

  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  // Write two file records
  var r1 = ModbusFileRecord(
      fileNumber: 4,
      recordNumber: 1,
      recordBytes: Uint8List.fromList([125, 232]));
  var r2 = ModbusFileRecord(
      fileNumber: 3, recordNumber: 9, recordBytes: Uint8List.fromList([3, 4]));
  await modbusClient.send(ModbusFileRecordsWriteRequest([r1, r2]));

  // Read two file records
  r1 = ModbusFileRecord.empty(fileNumber: 4, recordNumber: 1, recordLength: 2);
  r2 = ModbusFileRecord.empty(fileNumber: 3, recordNumber: 9, recordLength: 2);
  await modbusClient.send(ModbusFileRecordsReadRequest([r1, r2]));

  // Ending here
  modbusClient.disconnect();
}
