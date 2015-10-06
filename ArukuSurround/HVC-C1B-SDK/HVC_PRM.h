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
//  HVC_PRM.h
//

#import <Foundation/Foundation.h>

#import "HVCC_Define.h"

/**
 * Detection parameters
 */
@interface DetectionParam : NSObject
{
    /**
     * Minimum detection size
     */
    int MinSize;
    /**
     * Maximum detection size
     */
    int MaxSize;
    /**
     * Degree of confidence
     */
    int Threshold;
}

// Accessor
-(void) setMinSize:(int)size;
-(int)MinSize;
-(void) setMaxSize:(int)size;
-(int)MaxSize;
-(void) setThreshold:(int)threshold;
-(int)Threshold;

@end

/**
 * Face Detection parameters
 */
@interface FaceParam : DetectionParam
{
    /**
     * Facial pose
     */
    HVC_FACE_POSE Pose;
    /**
     * Roll angle
     */
    HVC_FACE_ANGLE Angle;
}

// Accessor
-(void) setPose:(HVC_FACE_POSE)pose;
-(HVC_FACE_POSE)Pose;
-(void) setAngle:(HVC_FACE_ANGLE)angle;
-(HVC_FACE_ANGLE)Angle;

@end

/**
 * HVC parameters
 */
@interface HVC_PRM : NSObject
{
	/**
     * Camera angle
     */
    HVC_CAMERA_ANGLE CameraAngle;
    /**
     * Human Body Detection parameters
     */
    DetectionParam *body;
    /**
     * Hand Detection parameters
     */
    DetectionParam *hand;
    /**
     * Face Detection parameters
     */
    FaceParam      *face;
}

// Accessor
-(void) setCameraAngle:(HVC_CAMERA_ANGLE)angle;
-(HVC_CAMERA_ANGLE)CameraAngle;
-(void) setBody:(DetectionParam *)body;
-(DetectionParam *)body;
-(void) setHand:(DetectionParam *)hand;
-(DetectionParam *)hand;
-(void) setFace:(FaceParam *)face;
-(FaceParam *)face;

@end
