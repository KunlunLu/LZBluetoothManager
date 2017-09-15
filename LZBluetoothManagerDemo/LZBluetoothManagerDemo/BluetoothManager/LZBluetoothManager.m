//
//  LZBluetoothManager.m
//  LZBluetoothManagerDemo
//
//  Created by lkl on 2017/8/4.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#import "LZBluetoothManager.h"
static LZBluetoothManager *bleManager = nil;

@interface LZBluetoothManager ()

@property (nonatomic,strong) CBCentralManager *centralManager;
@property (nonatomic,strong) CBPeripheral     *currentPeripheral;
@property (nonatomic,strong) CBCharacteristic *characteristic;
@property (nonatomic,strong) NSTimer          *scanTimer;

@end

@implementation LZBluetoothManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleManager = [[LZBluetoothManager alloc] init];
    });
    return bleManager;
}

- (id) initWithDelegate:(id<LZBluetoothManagerDelegate>) delegate
{
    self = [super init];
    if (self) {
        bleManager = [LZBluetoothManager sharedInstance];
        _bluetoothDelegate = delegate;
    }
    return self;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        bleManager = [super allocWithZone:zone];
    });
    return bleManager;
}

- (instancetype)init{
    if (self = [super init]) {
        if (!_centralManager)
        {

            //NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey:@YES};
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
    }
    return self;
}

#pragma mark - CBCentralManagerDelegate

//======================== Step 1:检测蓝牙状态============================
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if ([_centralManager isEqual:central]) {
        
        switch (central.state)
        {
                //未知状态
            case CBManagerStateUnknown:
            {
                _currentCentralManagerState = BLEStateUnknown;
                break;
            }
                
                //重置状态
            case CBManagerStateResetting:
            {
                _currentCentralManagerState = BLEStateResetting;
                break;
            }
                
                //不支持
            case CBManagerStateUnsupported:
            {
                _currentCentralManagerState = BLEStateUnsupported;
                break;
            }
                
                //未经授权的状态
            case CBManagerStateUnauthorized:
            {
                _currentCentralManagerState = BLEStateUnauthorized;
                break;
            }
                
                //掉电状态
            case CBManagerStatePoweredOff:
            {
                _currentCentralManagerState = BLEStatePoweredOff;
                break;
            }
                
                //上电状态
            case CBManagerStatePoweredOn:
            {
                _currentCentralManagerState = BLEStatePoweredOn;
                [self startScanning];
                break;
            }
                
            default:
                break;
        }
    }
    
    if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(currentCentralManagerStatus:)])
    {
        [_bluetoothDelegate currentCentralManagerStatus:self.currentCentralManagerState];
    }
    
}

//==================== Step 2:检测到外设后，停止扫描，连接外设 ===============

/**
 成功找到设备
 
 @param central 中心设备
 @param peripheral 外设
 @param advertisementData 外设携带的数据
 @param RSSI 蓝牙信号强度
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"peripheral name: %@", peripheral.name);
    
    if (!peripheral.name || peripheral.name.length == 0) {
        return;
    }
    
    //TODO:通过校验设备名，判断是否扫描到已选的设备
    if ([self checkDeviceName:peripheral.name])
    {
        self.currentPeripheral = peripheral;
        
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleDeviceScanned)])
        {
            [_bluetoothDelegate bleDeviceScanned];
        }
        
        //开始设备连接过程
        [_centralManager connectPeripheral:peripheral options:nil];
    }
}

//===================== Step 3：连接外设后回调处理 =========================
//连接成功，寻找制定的UUID服务
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"连接外设：%@成功  UUID：%@", peripheral.name , [peripheral.identifier UUIDString]);
    
    self.currentPeripheral = peripheral;
    [self stopScanning];   //停止扫描
    
    //连接成功代理
    if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleConnectSuccess)])
    {
        [_bluetoothDelegate bleConnectSuccess];
    }
    
    //    [self.currentPeripheral discoverServices:@[[CBUUID UUIDWithString:[self getBLEDeviceService]]]];  //寻找特定的服务
    [self.currentPeripheral discoverServices:nil];
    self.currentPeripheral.delegate = self;  //设置代理
}

//连接失败后回调函数的调用
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if (error) {
        [self cleanup];
    }
    
    if ([self.bluetoothDelegate respondsToSelector:@selector(bleConnectFailed)])
    {
        [_bluetoothDelegate bleConnectFailed];
    }
}


#pragma mark - CBPeripheralDelegate

//RSSI变化时的回调函数
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error
{
    if ([self.bluetoothDelegate respondsToSelector:@selector(updateRSSI:)])
    {
        [self.bluetoothDelegate updateRSSI:RSSI];
    }
    
}

//===================== Step 4 发现服务和搜索到的特征==========================
//发现的服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error) {
        NSLog(@"error :%@",[error localizedDescription]);
        
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleDiscoveryServiceFailed)])
        {
            [_bluetoothDelegate bleDiscoveryServiceFailed];
        }
        
        [self cleanup];
        return;
        
    }
    
    NSLog(@"services :%@",peripheral.services);
    
    [self startEnumDeviceServices:peripheral];
}

/**
 * 搜索到的特征
 *
 * 在didDiscoverCharacteristicsForService找到特征后,对这个特征进行读取操作
 * 在这个方法中我们要找到我们所需的服务的特性,然后调用setNotifyValue方法告知我们要监测这个服务特性的状态变化
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error){
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleDiscoveryCharacteristicsFailed)])
        {
            [_bluetoothDelegate bleDiscoveryCharacteristicsFailed];
        }
        [self cleanup];
        return;
    }
    NSLog(@"characteristics :%@",service.characteristics);
    [self startEnumCharacteristics:service];
}

//===================== Step 5 获取外设发来的数据 ===========================
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error){
        NSLog(@"Error didUpdateValueForCharacteristic: %@", [error localizedDescription]);
        return;
    }
    
    if (![self checkNotifyingCharacteristics:characteristic]){
        return;
    }
    
    NSData *valueData = characteristic.value;
    if (valueData && valueData.length > 0) {
        
        [self parseReceiveData:valueData];
    }
}

//===================== Step 6  其他 ===================================

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error){
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    if (![self checkNotifyingCharacteristics:characteristic]){
        return;    //若不是需要的特征值则退出
    }
    
    //通知已经被打开
    if (characteristic.isNotifying){
        NSLog(@"Notification began on %@", characteristic.UUID);
        NSLog(@"监听到的数据： %@",characteristic.value);
    }
}

//断开连接时的回调函数
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    //[self.peripheralArray removeObject:peripheral];
    //TDO 连接断开（设备异常断开or调用了断开函数），根据需求进行调用（重新连接）
    //[self startScanning];
    
    //断开连接
    if (self.bluetoothDelegate && [self.bluetoothDelegate respondsToSelector:@selector(bleDisConnected)])
    {
        [_bluetoothDelegate bleDisConnected];
    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"=======%@",error.userInfo);
    }else{
        NSLog(@"发送数据成功  WriteValueForCharacteristic : %@", characteristic.UUID);
    }
}

//===================== Step 7 按照需求进行调用==============================
#pragma mark -  Scanning

//判断状态开始扫瞄周围设备 第一个参数为空则会扫瞄所有的可连接设备,可以指定一个CBUUID对象,从而只扫瞄注册用指定服务的设备
-(void)startScanning
{
    if (_centralManager.isScanning){
        return;      //如果正在扫描，返回
    }
    [self setupUntil];
    if (_scanTimeOut > 0){  //启动定时器
        if (_scanTimer)
        {
            [_scanTimer invalidate];
        }
        
        _scanTimer = [NSTimer scheduledTimerWithTimeInterval:_scanTimeOut target:self selector:@selector(scanerTimeOut) userInfo:nil repeats:NO];
    }
    
    //开始扫描
    if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleStartScanning)]) {
        [_bluetoothDelegate bleStartScanning];
    }
    
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
}

//
- (void)setupUntil{
    //需要改变扫描的时间，在子类中实现
    self.scanTimeOut = 30;
}

//连接超时
- (void)scanerTimeOut
{
    [_scanTimer invalidate];
    _scanTimer = nil;
    
    [self stopScanning];
    
    if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleDeviceScanTimeOut)])
    {
        [_bluetoothDelegate bleDeviceScanTimeOut];
    }
}

//停止扫描
- (void)stopScanning
{
    [_centralManager stopScan];
    if (_scanTimer)
    {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
}

//设备名称
- (BOOL)checkDeviceName:(NSString*) deviceName{
    return NO;
}

//服务
- (BOOL)checkDeviceService:(CBService*) service{
    return NO;
}

//读特征
- (BOOL)checkNotifyingCharacteristics:(CBCharacteristic *)characteristic{
    return NO;
}

//写特征
- (BOOL)checkWriteCharacteristic:(CBCharacteristic *)characteristic{
    return NO;
}

- (NSData *)sendCommand{
    return nil;
}

//扫描复位
-(void)resetScanning
{
    [self cleanup];
    [self stopScanning];
    [self startScanning];
}

//清理
- (void)cleanup
{
    // See if we are subscribed to a characteristic on the peripheral
    if (self.currentPeripheral!= nil && self.currentPeripheral.services != nil)
    {
        for (CBService *service in _currentPeripheral.services)
        {
            if (service.characteristics != nil)
            {
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                    if ([self checkNotifyingCharacteristics:characteristic]) {
                        if (characteristic.isNotifying)
                        {
                            [_currentPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                            return;
                        }
                    }
                }
            }
        }
    }
    if (_currentPeripheral)
    {
        [_centralManager cancelPeripheralConnection:_currentPeripheral ];
    }
}


- (void)writeDate:(NSData *)data
{
    if (!data || data.length == 0){
        return ;  //没有写的数据
    }
    
    if (self.currentPeripheral && self.characteristic){
        [self.currentPeripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
    }
}

- (void)startEnumDeviceServices:(CBPeripheral *)peripheral
{
    if (!peripheral) {
        return;
    }
    
    __block CBService* specifyService;
    __weak typeof(self) weakSelf = self;
    if (peripheral.services) {
        [peripheral.services enumerateObjectsUsingBlock:^(CBService* service, NSUInteger idx, BOOL * _Nonnull stop)
         {
             if ([weakSelf checkDeviceService:service]) {
                 specifyService = service;
                 *stop = YES;
             }
         }];
    }
    
    if (specifyService)
    {
        //发现指定的Service
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleServiceDiscoveried)])
        {
            [_bluetoothDelegate bleServiceDiscoveried];
        }
        //发现设备特征
        [peripheral discoverCharacteristics:nil forService:specifyService];
    }
    else
    {
        //没能发现指定服务
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleServiceNotFound)])
        {
            [_bluetoothDelegate bleServiceNotFound];
        }
        //断开蓝牙连接
        [_centralManager cancelPeripheralConnection:peripheral];
        self.currentPeripheral = nil;
    }
}

- (void)startEnumCharacteristics:(CBService *)service
{
    if (!service)
    {
        return;
    }
    
    __block CBCharacteristic* specifyCharateristic;
    __weak typeof(self) weakSelf = self;
    
    if (service.characteristics.count <= 0) {
        return;
    }
    [service.characteristics enumerateObjectsUsingBlock:^(CBCharacteristic * characteristic, NSUInteger idx, BOOL * _Nonnull stop) {
        
        //发送命令
        if ([weakSelf checkWriteCharacteristic:characteristic]) {
            
            self.characteristic = characteristic;
            
            if (![self sendCommand]) {
                return ;
            }
            //连接成功，发送握手命令(需延时才能握手成功)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1/*延迟执行时间*/ * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.currentPeripheral writeValue:[self sendCommand] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            });
        }
        
        //监听
        if ([weakSelf checkNotifyingCharacteristics:characteristic]) {
            specifyCharateristic = characteristic;
            //            *stop = YES;
            //开启监听
            if (!characteristic.isNotifying) {
                [self.currentPeripheral setNotifyValue:YES forCharacteristic:specifyCharateristic];
                [self.currentPeripheral readValueForCharacteristic:specifyCharateristic];
            }
        }
    }];
    
    if (specifyCharateristic)
    {
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleCharacteristicsDiscoveried)])
        {
            [_bluetoothDelegate bleCharacteristicsDiscoveried];
        }
        
    }
    else
    {
        //没能发现指定特征值
        if (_bluetoothDelegate && [_bluetoothDelegate respondsToSelector:@selector(bleCharacteristicsNotFound)])
        {
            [_bluetoothDelegate bleCharacteristicsNotFound];
        }
        //断开蓝牙连接
        [_centralManager cancelPeripheralConnection:self.currentPeripheral];
        self.currentPeripheral = nil;
    }
}

//数据解析
- (void)parseReceiveData:(NSData *)valueData{
    
}

@end
