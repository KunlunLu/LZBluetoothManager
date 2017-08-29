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

@end

@implementation BloodOxygenDetectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    BloodOxygenBLEManager *bleControl = [[BloodOxygenBLEManager alloc] initWithDelegate:self];
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
}

- (void)bleDeviceScanTimeOut{
//    [self showAlertMessage:@"设备连接超时，您可以手动上传数据,或者重新测量" clicked:^{
//        [self dismissViewControllerAnimated:YES completion:nil];
//    }];
}


#pragma mark -- BloodOxygenBLEResultDelegate
-(void)didRefreshOximeterParams:(BMOximeterParams*)params
{
    //结果
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
