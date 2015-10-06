/*
 * Copyright (C) 2014-2015 OMRON Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  BleDeviceService.h
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BleDeviceDelegate <NSObject>
@optional
// Notice of completion of device connection
- (void)didConnect;
// Notice of completion of device disconnection
- (void)didDisconnect;
// Notice of data reception
- (void)didReceiveData:(NSData *)data;
// Notice of device name reception
- (void)didReceiveDeviceName:(NSData *)data;
@end

@interface BleDeviceService : NSObject

@property (nonatomic, strong) id<BleDeviceDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *deviceList;

/**
 *
 * Start searching Devices
 */
-(void)startScan;
/**
 *
 * Stop searching Devices
 */
-(void)stopScan;
/**
 *
 * Connect to the Device
 */
-(void)connectDevice:(CBPeripheral *)device;
/**
 *
 * Disconnect the Device
 */
-(void)disconnectDevice;

-(BOOL)sendData:(NSData *)data;
-(BOOL)sendDeviceName:(NSData *)data;
-(BOOL)readDeviceName;

@end
