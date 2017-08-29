//
//  BloodOxygenBLEManager.h
//  LZBluetoothManagerDemo
//
//  Created by lkl on 2017/8/4.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#import "LZBluetoothManager.h"
#import "BMOximeterParams.h"

@protocol BloodOxygenBLEResultDelegate
//血氧
- (void)didRefreshOximeterParams:(BMOximeterParams*)params;

@end

@interface BloodOxygenBLEManager : LZBluetoothManager

@property(nonatomic,copy) NSMutableArray   *dataArray;
@property(nonatomic,strong) BMOximeterParams *oximeterParams;

@property (nonatomic, weak) id<BloodOxygenBLEResultDelegate> bloodOxygenDelegate;

@end
