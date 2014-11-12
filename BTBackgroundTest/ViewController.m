//
//  ViewController.m
//  BTBackgroundTest
//
//  Created by Paul Wilkinson on 13/11/2014.
//  Copyright (c) 2014 Paul Wilkinson. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@property (strong,nonatomic) CBCentralManager *central;
@property (copy,nonatomic) NSString *targetPeripheral;
@property (strong,nonatomic) NSMutableArray *discoveredPeripherals;
@property (weak,nonatomic) IBOutlet UITableView *tableview;
@property (weak,nonatomic) IBOutlet UILabel *manfLabel;
@property (strong,nonatomic) CBPeripheral *connectedPeripheral;
@property (strong,nonatomic) CBUUID *deviceInfoUUID;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.central=[[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)];
    self.discoveredPeripherals=[NSMutableArray new];

    self.deviceInfoUUID=[CBUUID UUIDWithString:@"0x180A"];
    
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.manfLabel.text=@"Not connected";
}

#pragma mark - UITableViewDataSource methods

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.discoveredPeripherals.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier=@"cell";
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    CBPeripheral *peripheral=(CBPeripheral *)self.discoveredPeripherals[indexPath.row];
    cell.textLabel.text=peripheral.name;
    cell.detailTextLabel.text=peripheral.identifier.UUIDString;
    
    if ([peripheral.identifier.UUIDString isEqualToString:self.targetPeripheral]) {
        cell.accessoryType=UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
    
    return cell;
    
}

#pragma mark - UITableViewDelegate methods;

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CBPeripheral *targetPeripheral=(CBPeripheral *)self.discoveredPeripherals[indexPath.row];
    if (![self.targetPeripheral isEqualToString:targetPeripheral.identifier.UUIDString]) {
        if (self.connectedPeripheral) {
            [self.central cancelPeripheralConnection:self.connectedPeripheral];
        }
        self.targetPeripheral=targetPeripheral.identifier.UUIDString;
        [tableView reloadData];
        [self.central connectPeripheral:targetPeripheral options:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    
}

#pragma mark - CBCentralManager Delegate methods

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            [self startScan];
            break;
    }
}


-(void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"Discovered peripheral %@ (%@)",peripheral.name,peripheral.identifier.UUIDString);
    if (![self.discoveredPeripherals containsObject:peripheral] ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.discoveredPeripherals addObject:peripheral];
            [self.tableview insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.discoveredPeripherals.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
        });
    }
}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    self.connectedPeripheral=peripheral;
    NSLog(@"Connected to %@(%@)",peripheral.name,peripheral.identifier.UUIDString);
    peripheral.delegate=self;

    [peripheral discoverServices:@[self.deviceInfoUUID]];
}

-(void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected from peripheral");
    dispatch_async(dispatch_get_main_queue(), ^{
        self.manfLabel.text=@"Not connected";
    });
    if ([self.targetPeripheral isEqualToString:peripheral.identifier.UUIDString]) {
        NSLog(@"Retrying");
        [self.central connectPeripheral:peripheral options:nil];
    }
}

#pragma mark - CBPeripheralManager delegate methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service %@",service.description);
        if ([service.UUID isEqual:self.deviceInfoUUID]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics ) {
        NSLog(@"Discovered characteristic %@(%@)",characteristic.description,characteristic.UUID.UUIDString);
        if ([characteristic.UUID.UUIDString isEqualToString:@"2A29"]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *manf=[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.manfLabel.text=manf;
    });
    
}

#pragma mark - other methods

-(void) startScan {
    NSLog(@"Starting scan");
    [self.central scanForPeripheralsWithServices:nil options:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
