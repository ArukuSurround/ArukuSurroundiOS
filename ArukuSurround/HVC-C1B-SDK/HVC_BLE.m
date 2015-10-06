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
//  HVC_BLE.m
//

#import "HVC_BLE.h"

@interface HVC_BLE () {
}
@property BleDeviceService *mBleService;
@end

/**
 * HVC-C BLE Model
 * [Description]
 * HVC subclass, connects HVC to Bluetooth
 */
@implementation HVC_BLE

@synthesize delegateHVC = _delegate;
@synthesize mBleService = _mBleService;

-(id) init
{
    nStatus = STATE_DISCONNECTED;
    recvData = [[NSMutableData alloc] init];
    self = [super init];
    if ( self ) {
        self.mBleService = [[BleDeviceService alloc] init];
        self.mBleService.delegate = self;
    }
    return self;
}

// Notice of completion of device connection Delegate
- (void)didConnect
{
    nStatus = STATE_CONNECTED;
    dispatch_async(dispatch_get_main_queue(), ^{
    	[self.delegateHVC onConnected];
    });
}

// Notice of completion of device disconnection Delegate
- (void)didDisconnect
{
    nStatus = STATE_DISCONNECTED;
    dispatch_async(dispatch_get_main_queue(), ^{
    	[self.delegateHVC onDisconnected];
    });
}

// Notice of data reception Delegate
- (void)didReceiveData:(NSData *)data
{
    @synchronized(recvData)
    {
        [recvData appendData:data];
    }
}

// Notice of device name reception Delegate
- (void)didReceiveDeviceName:(NSData *)data
{
    dispatch_async(dispatch_get_main_queue(), ^{
	    [self.delegateHVC onPostGetDeviceName:data];
    });
}


// Application I/F

// HVC_BLE Device Search
-(void)deviceSearch
{
    [self.mBleService startScan];
}

// Obtain list of detected HVC_BLE devices
-(NSMutableArray *)getDevices
{
    return self.mBleService.deviceList;
}

// HVC_BLE connect
-(void)connect:(CBPeripheral *)device
{
    nStatus = STATE_CONNECTING;
    [self.mBleService connectDevice:device];
}

// HVC_BLE disconnect
-(void)disconnect
{
    nStatus = STATE_DISCONNECTED;
    [self.mBleService disconnectDevice];
}

// Set HVC Device name
-(int)setDeviceName:(NSData *)value
{
    BOOL bRet = [self.mBleService sendDeviceName:value];
    if ( bRet == YES ) return HVC_NORMAL;
    return HVC_ERROR_NODEVICES;
}

// Get HVC Device name
-(int)getDeviceName:(NSData *)value
{
    BOOL bRet = [self.mBleService readDeviceName];
    if ( bRet == YES ) return HVC_NORMAL;
    return HVC_ERROR_NODEVICES;
}

// Execute HVC functions
-(HVC_ERRORCODE)Execute:(HVC_FUNCTION)inExec result:(HVC_RES *)result
{
    if ( nStatus == STATE_DISCONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_NODEVICES");
        return HVC_ERROR_NODEVICES;
    }
    if ( nStatus < STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_DISCONNECTED");
        return HVC_ERROR_DISCONNECTED;
    }
    if ( nStatus > STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_BUSY");
        return HVC_ERROR_BUSY;
    }
    
    nStatus = STATE_BUSY;
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned char outStatus;
        HVC_ERRORCODE err = [self ExecuteFunc:20000 exec:inExec status:&outStatus result:result];
        [self.delegateHVC onPostExecute:result errcode:err status:outStatus];
        nStatus = STATE_CONNECTED;
    });
    return HVC_NORMAL;
}

// Set HVC Parameters
-(HVC_ERRORCODE)setParam:(HVC_PRM *)param
{
    if ( nStatus == STATE_DISCONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_NODEVICES");
        return HVC_ERROR_NODEVICES;
    }
    if ( nStatus < STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_DISCONNECTED");
        return HVC_ERROR_DISCONNECTED;
    }
    if ( nStatus > STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_BUSY");
        return HVC_ERROR_BUSY;
    }
    
    nStatus = STATE_BUSY;
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned char outStatus;
        HVC_ERRORCODE err = [self SetCameraAngle:10000 status:&outStatus parameter:param];
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self SetThreshold:10000 status:&outStatus parameter:param];
        }
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self SetSizeRange:10000 status:&outStatus parameter:param];
        }
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self SetFaceDetectionAngle:10000 status:&outStatus parameter:param];
        }
        [self.delegateHVC onPostSetParam:err status:outStatus];
        nStatus = STATE_CONNECTED;
    });
    return HVC_NORMAL;
}

// Get HVC Parameters
-(HVC_ERRORCODE)getParam:(HVC_PRM *)param
{
    if ( nStatus == STATE_DISCONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_NODEVICES");
        return HVC_ERROR_NODEVICES;
    }
    if ( nStatus < STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_DISCONNECTED");
        return HVC_ERROR_DISCONNECTED;
    }
    if ( nStatus > STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_BUSY");
        return HVC_ERROR_BUSY;
    }
    
    nStatus = STATE_BUSY;
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned char outStatus;
        HVC_ERRORCODE err = [self GetCameraAngle:10000 status:&outStatus parameter:param];
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self GetThreshold:10000 status:&outStatus parameter:param];
        }
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self GetSizeRange:10000 status:&outStatus parameter:param];
        }
        if ( err == HVC_NORMAL && outStatus == 0 ) {
            err = [self GetFaceDetectionAngle:10000 status:&outStatus parameter:param];
        }
        [self.delegateHVC onPostGetParam:param errcode:err status:outStatus];
        nStatus = STATE_CONNECTED;
    });
    return HVC_NORMAL;
}

// Get HVC Version
-(HVC_ERRORCODE)getVersion:(HVC_VER *)ver
{
    if ( nStatus == STATE_DISCONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_NODEVICES");
        return HVC_ERROR_NODEVICES;
    }
    if ( nStatus < STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_DISCONNECTED");
        return HVC_ERROR_DISCONNECTED;
    }
    if ( nStatus > STATE_CONNECTED ) {
        NSLog(@"execute() : HVC_ERROR_BUSY");
        return HVC_ERROR_BUSY;
    }
    
    nStatus = STATE_BUSY;
    dispatch_async(dispatch_get_main_queue(), ^{
        unsigned char outStatus;
        HVC_ERRORCODE err = [self GetVersion:10000 status:&outStatus version:ver];
        [self.delegateHVC onPostGetVersion:ver errcode:err status:outStatus];
        nStatus = STATE_CONNECTED;
    });
    return HVC_NORMAL;
}

// Bluetooth send signal
-(int)Send:(NSMutableData *)data
{
    NSData *p = [data copy];
    [self.mBleService sendData:p];
    return (int)p.length;
}

// Bluetooth receive signal
-(int)Receive:(NSMutableData **)data length:(int)dataLength timeOut:(int)timeout
{
    int timecnt = 0;
    while (true)
    {
        // Waiting to receive
        @synchronized(recvData)
        {
            if ( recvData.length >= dataLength )
            {
                // Receive complete
                NSRange n;
                n.length = dataLength;
                n.location = 0;
                *data = [[recvData subdataWithRange:n] mutableCopy];
                // Move the received data
                n.length = recvData.length - dataLength;
                n.location = dataLength;
                NSData *backup = [recvData subdataWithRange:n];
                [recvData setLength:0];
                [recvData appendData:backup];
                NSLog(@"Recieve datalen=%d recvDataLen=%d", (int)(*data).length, (int)recvData.length);
                break;
            }
        }
        // Appropriately sleeping
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        timecnt += 100;
        if ( timeout <= timecnt )
        {
            // Receive timeout
            NSLog(@"receive timeout");
            return (int)(*data).length;
        }
    }
    
    NSLog(@"receive complete");
    return (int)(*data).length;
}

@end
