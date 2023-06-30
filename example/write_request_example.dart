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
  var batteryStatus = ModbusEnumRegister(
      name: "BatteryStatus",
      address: 11,
      type: ModbusElementType.holdingRegister,
      enumValues: BatteryStatus.values,
      onUpdate: (self) => print(self));

  var modbusClient = ModbusClientTcp("127.0.0.1", unitId: 1);

  var req = batteryStatus.getWriteRequest(BatteryStatus.running);
  var res = await modbusClient.send(req);
  print(res.name);

  modbusClient.disconnect();
}
