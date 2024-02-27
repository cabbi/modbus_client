import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client/src/modbus_file_record.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create the modbus client.
  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  // Write two file records
  var r1 = ModbusFileUint16Record(
      fileNumber: 4,
      recordNumber: 1,
      recordData: Uint16List.fromList([12573, 56312]));
  var r2 = ModbusFileDoubleRecord(
      fileNumber: 3,
      recordNumber: 9,
      recordData: Float64List.fromList([123.5634, 125756782.8492]));
  await modbusClient.send(ModbusFileRecordsWriteRequest([r1, r2]));

  // Read two file records
  r1 = ModbusFileUint16Record.empty(
      fileNumber: 4, recordNumber: 1, recordDataCount: 2);
  r2 = ModbusFileDoubleRecord.empty(
      fileNumber: 3, recordNumber: 9, recordDataCount: 2);
  await modbusClient.send(ModbusFileRecordsReadRequest([r1, r2]));

  // Ending here
  modbusClient.disconnect();
}
