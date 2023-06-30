import 'package:logging/logging.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

void main() async {
  ModbusAppLogger(Level.FINE);
  var batteryTemperature = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.holdingRegister,
      address: 22,
      uom: "°C",
      multiplier: 0.1,
      onUpdate: (self) => print(self));

  var modbusClient = ModbusClientTcp("127.0.0.1",
      unitId: 1, connectionMode: ModbusConnectionMode.autoConnectAndDisconnect);

  await modbusClient.send(batteryTemperature.getReadRequest());
  await modbusClient.send(batteryTemperature.getReadRequest());

  modbusClient.disconnect();
}
