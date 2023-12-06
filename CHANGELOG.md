## 1.0.3+3
- Little adjustment in case 'setResponseCode' is called multiple times
- Documentation and examples update
- Warnings removal

## 1.0.2
- Removed **ModbusEpochType** from **ModbusEpochRegister** since it's only a 32 bits registry for now and it cannot handle milliseconds representation.
- Some cosmetic code changes in **ModbusRequest** and **ModbusElementRequest** to help overriding those classes.
- **README.md** and **example.md** file updates

## 1.0.1
- set dependency of "collection" to 1.17.1 in order to have flutter compatibility [https://github.com/cabbi/modbus_client/issues/1] 
  
## 1.0.0
- Initial version.
