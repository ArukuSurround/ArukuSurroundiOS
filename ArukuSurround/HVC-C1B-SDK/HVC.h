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
//  HVC.h
//

#import <Foundation/Foundation.h>

#import "HVC_PRM.h"
#import "HVC_RES.h"
#import "HVC_VER.h"

/**
 * HVC object
 * [Description]
 * New class object definition HVC
 */
@class HVC;

@interface HVC : NSObject {
}

// GetVersion
-(HVC_ERRORCODE)GetVersion:(int)timeOut status:(unsigned char *)outStatus version:(HVC_VER *)ver;
// SetCameraAngle
-(HVC_ERRORCODE)SetCameraAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// GetCameraAngle
-(HVC_ERRORCODE)GetCameraAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// SetThreshold
-(HVC_ERRORCODE)SetThreshold:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// GetThreshold
-(HVC_ERRORCODE)GetThreshold:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// SetSizeRange
-(HVC_ERRORCODE)SetSizeRange:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// GetSizeRange
-(HVC_ERRORCODE)GetSizeRange:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// SetFaceDetectionAngle
-(HVC_ERRORCODE)SetFaceDetectionAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// GetFaceDetectionAngle
-(HVC_ERRORCODE)GetFaceDetectionAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param;
// Execute
-(HVC_ERRORCODE)ExecuteFunc:(int)timeOut exec:(HVC_FUNCTION)inExec status:(unsigned char *)outStatus result:(HVC_RES *)result;


// Method to be implemented in the sub class

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
 * Send Signal
 * [Description]
 * none
 * [Notes]
 * @param data send signal data
 * @return int send signal complete data number
 */
-(int)Send:(NSMutableData *)data;

/**
 * Receive Signal
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
