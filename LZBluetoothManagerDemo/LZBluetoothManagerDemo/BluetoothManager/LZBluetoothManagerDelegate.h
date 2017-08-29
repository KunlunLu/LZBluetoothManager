//
//  LZBluetoothManagerDelegate.h
//  LZBluetoothManage
//
//  Created by lkl on 2017/8/3.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#ifndef LZBluetoothManagerDelegate_h
#define LZBluetoothManagerDelegate_h

//========================BluetoothManager定义枚举====================
typedef NS_ENUM(NSInteger, BLEStatus) {
    //中心设备初始状态
    BLEStateUnknown = 0,   // 未知状态
    BLEStateResetting,     // 重置状态
    BLEStateUnsupported,   // 不支持
    BLEStateUnauthorized,  // 未授权
    BLEStatePoweredOff,    // 掉电状态
    BLEStatePoweredOn,     // 上电状态
} ;


//========================BluetoothManager定义协议====================
@protocol LZBluetoothManagerDelegate <NSObject>

- (void)currentCentralManagerStatus:(BLEStatus)status;

@optional

-(void)receiveBLEData:(NSData *)data; //接收到设备发送上来的原始数据
-(void)updateRSSI:(NSNumber *)RSSI;//更新信号强度

#pragma mark - 扫描设备
- (void)bleStartScanning;
- (void)bleDeviceScanned;  //指定设备已经被扫描到
- (void)bleDeviceScanTimeOut;  //扫描超时，没有找到指定设备

#pragma mark - 连接设备
- (void)bleConnectSuccess;     //设备connect成功
- (void)bleConnectFailed;      //设备connect失败
- (void)bleDisConnected;       //设备连接断开

#pragma mark - 发现Service
- (void)bleDiscoveryServiceFailed; //发现服务失败
- (void)bleServiceDiscoveried;  //发现指定服务
- (void)bleServiceNotFound;    //没能找到指定服务

#pragma mark - 发现Characteristics
- (void)bleDiscoveryCharacteristicsFailed; //发现特征值失败
- (void)bleCharacteristicsDiscoveried;  //发现指定特征值
- (void)bleCharacteristicsNotFound;    //没能找到指定特征值
@end



#endif /* LZBluetoothManagerDelegate_h */
