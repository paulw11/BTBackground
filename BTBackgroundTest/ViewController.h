//
//  ViewController.h
//  BTBackgroundTest
//
//  Created by Paul Wilkinson on 13/11/2014.
//  Copyright (c) 2014 Paul Wilkinson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,CBCentralManagerDelegate,CBPeripheralDelegate>


@end

