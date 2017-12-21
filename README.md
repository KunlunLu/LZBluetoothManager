# LZBluetoothManager
蓝牙4.0开发CoreBuletooth封装，适应于APP中有多个蓝牙设备，便于扩展

如果项目中需要在应用进入后台或者手机锁屏状态下，仍然需要蓝牙连接，并且能够正常接收数据的话，在xxx-info.plist文件中, 新建一行  Required background modes 加入两项：
    App shares data using CoreBluetooth 和
    App communicates using CoreBluetooth

