//
//  BloodOxygenBLEManager.m
//  LZBluetoothManagerDemo
//
//  Created by lkl on 2017/8/4.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#import "BloodOxygenBLEManager.h"

@implementation BloodOxygenBLEManager
//设备名称
- (BOOL)checkDeviceName:(NSString*) deviceName{
    if (!deviceName || deviceName.length == 0)
    {
        return NO;
    }
    return [deviceName isEqualToString:@"BerryMed"];
}

//服务
- (BOOL)checkDeviceService:(CBService *)service{
    if (!service) {
        return NO;
    }
    return [service.UUID isEqual:[CBUUID UUIDWithString:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"]];
}

//读特征
- (BOOL)checkNotifyingCharacteristics:(CBCharacteristic *)characteristic{
    if (!characteristic) {
        return NO;
    }
    return [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"49535343-1E4D-4BD9-BA61-23C647249616"]] ;//|| [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"49535343-8841-43F4-A8D4-ECBE34729BB3"]] || [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"00005343-0000-1000-8000-00805F9B34FB"]];
}

- (void)parseReceiveData:(NSData *)valueData
{
    BOOL isPackageHeaderFound = NO;
    Byte package[5]           = {0};
    int  packageIndex         = 0;
    
    int  parserIndex = 0;
    int  i = 0;
    
    Byte *resultBytes = (Byte *)[valueData bytes];
    
    for(int i= 0; i < valueData.length; i++){
        [self.dataArray addObject: [NSNumber numberWithInt:(int)(resultBytes[i]&0xff) ]];
    }
    
    if(self.dataArray.count < 10){
        return;
    }
    
    while (i < self.dataArray.count)
    {
        //scan for package header
        if([self.dataArray[i] integerValue] & 0x80)
        {
            isPackageHeaderFound     = YES;
            package[packageIndex ++] = [self.dataArray[i] integerValue];
            i++;
            continue;
        }
        
        if(isPackageHeaderFound)
        {
            package[packageIndex ++] = [self.dataArray[i] integerValue];
            if(packageIndex == 5)
            {
                BMOximeterParams *params = [[BMOximeterParams alloc] init];
                
                params.piValue        = package[0] & 0x0f;
                params.waveAmplitude  = package[1];
                params.pulseRateValue = package[3] | ((package[2] & 0x40) << 1);
                params.SpO2Value      = package[4];
                
                if (params.SpO2Value != self.oximeterParams.SpO2Value || params.pulseRateValue != self.oximeterParams.pulseRateValue){
                    if (params.SpO2Value == [BMOximeterParams SpO2InvalidValue] &  params.pulseRateValue == [BMOximeterParams pulseRateInvalidValue]){
                        NSLog(@"无效数据");
                    }
                    else{
                        self.bloodOxygenDelegate = (id<BloodOxygenBLEResultDelegate>) self.bluetoothDelegate;
                        [self.bloodOxygenDelegate didRefreshOximeterParams:params];
                    }
                }
                self.oximeterParams = params;
                
                packageIndex         = 0;
                isPackageHeaderFound = NO;
                parserIndex          = i;
                memset(package, 0, sizeof(package));
            }
        }
        i++;
    }
    [self.dataArray removeObjectsInRange:NSMakeRange(0, parserIndex+1)];
}

#pragma mark -- init
-(NSMutableArray *)dataArray
{
    if(!_dataArray)
    {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

-(BMOximeterParams *)oximeterParams
{
    if (!_oximeterParams) {
        _oximeterParams = [[BMOximeterParams alloc]init];
    }
    return _oximeterParams;
}

@end
