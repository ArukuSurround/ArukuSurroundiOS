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
//  HVC_BLE.h
//

#import <Foundation/Foundation.h>

#import "HVC.h"
#import "BleDeviceService.h"

// Define Status CODE
typedef enum : NSInteger
{
    STATE_DISCONNECTED = 0,
    STATE_CONNECTING = 1,
    STATE_CONNECTED = 2,
    STATE_BUSY = 3,
} HVC_STATUS;

/**
 * HVC-C BLE Model
 * [Description]
 * HVC subclass, connects HVC to Bluetooth
 */
@class HVC_BLE;

@protocol HVC_Delegate <NSObject>
@optional
// Notice of completion of connection 
- (void)onConnected;
// Notice of completion of disconnection
- (void)onDisconnected;
// Notice of device name reception 
- (void)onPostGetDeviceName:(NSData *)value;
/**
 * Return Execute execution result and error code
 * @param result execution result value
 * @param err execution result error code 
 * @param outStatus response code
 */
- (void)onPostExecute:(HVC_RES *)result errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus;
/**
 * Return SetParam execution result and error code
 * @param err execution result error code 
 * @param outStatus response code
 */
- (void)onPostSetParam:(HVC_ERRORCODE)err status:(unsigned char)outStatus;
/**
 * Return GetParam execution result and error code
 * @param err execution result error code 
 * @param outStatus response code
 */
- (void)onPostGetParam:(HVC_PRM *)param errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus;
/**
 * Return GetVersion execution result and error code
 * @param err execution result error code 
 * @param outStatus response code
 */
- (void)onPostGetVersion:(HVC_VER *)ver errcode:(HVC_ERRORCODE)err status:(unsigned char)outStatus;
@end

@interface HVC_BLE : HVC <BleDeviceDelegate> {
    HVC_STATUS nStatus;
    NSMutableData  *recvData;
}

@property (nonatomic, strong) id<HVC_Delegate> delegateHVC;


// Application I/F

// HVC_BLE Device Search
-(void)deviceSearch;
// Obtain list of detected HVC_BLE devices
-(NSMutableArray *)getDevices;

/**
 * HVC_BLE connect
 * [Description]
 * Connect with HVC_BLE device
 */
-(void)connect:(CBPeripheral *)device;
/**
 * HVC_BLE disconnect
 * [Description]
 * Disconnect HVC_BLE device
 */
-(void)disconnect;
/**
 * Set HVC Device name
 * [Description]
 * Set HVC Device name.
 * @param value setting device name
 * @return int execution result error code 
 */
-(int)setDeviceName:(NSData *)value;
/**
 * Get HVC Device name
 * [Description]
 * Get HVC Device name. Store name in value
 * @param value device name stored
 * @return int execution result error code 
 */
-(int)getDeviceName:(NSData *)value;

/**
 * Execute HVC functions
 * [Description]
 * Execute each HVC function. Store results in HVC_RES
 * @param inExec execution flag
 * @param result results stored
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)Execute:(HVC_FUNCTION)inExec result:(HVC_RES *)result;
/**
 * Set HVC Parameters
 * [Description]
 * Set each HVC parameter. 
 * @param param parameter
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)setParam:(HVC_PRM *)param;
/**
 * Get HVC Parameters
 * [Description]
 * Get each HVC parameter. 
 * @param param parameter stored
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)getParam:(HVC_PRM *)param;
/**
 * Get HVC Version
 * [Description]
 * Get HVC Version. 
 * @param ver version stored
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)getVersion:(HVC_VER *)ver;

/**
 * Bluetooth send signal
 * [Description]
 * none
 * [Notes]
 * @param data send signal data
 * @return int send signal complete data number
 */
-(int)Send:(NSMutableData *)data;

/**
 * Bluetooth receive signal
 * [Description]
 * none
 * [Notes]
 * @param data receive signal data
 * @param dataLength receive signal data size
 * @param timeout timeout time
 * @return int receive signal complete data number
 */
-(int)Receive:(NSMutableData **)data length:(int)dataLength timeOut:(int)timeout;

@end
