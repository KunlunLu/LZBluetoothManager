//
//  ViewController.m
//  LZBluetoothManagerDemo
//
//  Created by lkl on 2017/8/4.
//  Copyright © 2017年 Kunlun Lu. All rights reserved.
//

#import "ViewController.h"
#import "BloodOxygenDetectViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10, 100, self.view.frame.size.width-20, 50)];
    [self.view addSubview:button];
    [button setBackgroundColor:[UIColor orangeColor]];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *value = @"<024100ee 070c1403 220576a2 11>";
    NSString *endValue = [value substringWithRange:NSMakeRange(23,2)];
    NSString *startValue = [value substringWithRange:NSMakeRange(26, 1)];
    NSString *valueStr = [NSString stringWithFormat:@"%@%@",startValue,endValue];
    
    NSString *flag = [value substringWithRange:NSMakeRange(25,1)];
    CGFloat f = strtoul([valueStr UTF8String], 0, 16);
    CGFloat valuef;
    if ([flag isEqualToString:@"a"])
    {
        valuef = f/10/18;
        NSLog(@"%f",f/1000);
    }
    else if ([flag isEqualToString:@"b"])
    {
        valuef = f/100;
    }else
    {

        NSLog(@"错误");
        return;
    }
    NSLog(@"%f",valuef);
}

- (void)buttonClick{
    BloodOxygenDetectViewController *VC = [[BloodOxygenDetectViewController alloc] init];
    [self.navigationController pushViewController:VC animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
