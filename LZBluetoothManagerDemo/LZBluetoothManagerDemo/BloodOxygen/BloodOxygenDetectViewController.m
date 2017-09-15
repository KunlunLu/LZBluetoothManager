//
//  BloodOxygenDetectViewController.m
//  LZBluetoothManagerDemo
//
//  Created by lkl on 2017/8/29.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#import "BloodOxygenDetectViewController.h"
#import "BloodOxygenBLEManager.h"

@interface BloodOxygenDetectViewController () <LZBluetoothManagerDelegate>
{
    BloodOxygenBLEManager *bleControl;
}
@end

@implementation BloodOxygenDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    bleControl = [[BloodOxygenBLEManager alloc] initWithDelegate:self];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    if (bleControl) {
        //停止扫描并断开连接
        [bleControl stopScanning];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (bleControl && bleControl.currentCentralManagerState == BLEStatePoweredOn){
        [bleControl startScanning];
    }
}

#pragma mark --  JYBluetoothManagerDelegate
- (void)currentCentralManagerStatus:(BLEStatus)status{
    switch (status) {
        case BLEStatePoweredOff:
        {

            break;
        }
            
        case BLEStatePoweredOn:
        {

            break;
        }
            
        default:
            break;
    }
}

#pragma mark - 连接设备
- (void)bleConnectSuccess
{

}

- (void)bleConnectFailed
{
}

- (void)bleDisConnected
{
//    [self showAlertMessage:@"设备连接断开" clicked:^{
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }];
    NSLog(@"设备连接断开");
}

- (void)bleDeviceScanTimeOut{
//    [self showAlertMessage:@"设备连接超时，您可以手动上传数据,或者重新测量" clicked:^{
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }];
    NSLog(@"设备连接超时");
}


#pragma mark -- BloodOxygenBLEResultDelegate
-(void)didRefreshOximeterParams:(BMOximeterParams*)params
{
    //结果
    NSLog(@"---%lu %lu %lu", params.SpO2Value,params.pulseRateValue,params.piValue);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
