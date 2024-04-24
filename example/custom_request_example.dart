import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  // Simple modbus logging
  ModbusAppLogger(Level.FINE);

  // Create your own element type by defining your custom read & write function codes
  ModbusElementType myCustomType = ModbusElementType(
      ModbusFunctionCode(0x04, FunctionType.read),
      ModbusFunctionCode(0x06, FunctionType.writeSingle),
      ModbusFunctionCode(0x10, FunctionType.writeMultiple));

  // Create a modbus int16 register element
  var batteryTemperature = ModbusInt16Register(
      name: "BatteryTemperature",
      type: myCustomType,
      address: 22,
      uom: "°C",
      multiplier: 0.1,
      onUpdate: (self) => print(self));

  // Discover the Modbus server
  var serverIp = await ModbusClientTcp.discover("192.168.8.106");
  if (serverIp == null) {
    ModbusAppLogger.shout("No modbus server found!");
    return;
  }

  // Create the modbus client.
  var modbusClient = ModbusClientTcp(serverIp, unitId: 1);

  // Send a read request from the element
  await modbusClient.send(batteryTemperature.getReadRequest());

  // Ending here
  modbusClient.disconnect();
}
