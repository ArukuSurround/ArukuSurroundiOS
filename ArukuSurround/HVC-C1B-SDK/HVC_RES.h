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
//  HVC_RES.h
//

#import <Foundation/Foundation.h>

#import "HVCC_Define.h"

/**
 * Detection result
 */
@interface DetectionResult : NSObject
{
    /**
     * Center x-coordinate
     */
    int posX;
    /**
     * Center y-coordinate
     */
    int posY;
    /**
     * Size
     */
    int size;
    /**
     * Degree of confidence
     */
    int confidence;
}

// Accessor
-(void) setPosX:(int)val;
-(int)posX;
-(void) setPosY:(int)val;
-(int)posY;
-(void) setSize:(int)val;
-(int)size;
-(void) setConfidence:(int)val;
-(int)confidence;

@end


/**
 * Face direction
 */
@interface DirResult : NSObject
{
    /**
     * Yaw angle
     */
    int yaw;
    /**
     * Pitch angle
     */
    int pitch;
    /**
     * Roll angle
     */
    int roll;
    /**
     * Degree of confidence
     */
    int confidence;
}

// Accessor
-(void) setYaw:(int)val;
-(int)yaw;
-(void) setPitch:(int)val;
-(int)pitch;
-(void) setRoll:(int)val;
-(int)roll;
-(void) setConfidence:(int)val;
-(int)confidence;

@end


/**
 * Age
 */
@interface AgeResult : NSObject
{
    /**
     * Age
     */
    int age;
    /**
     * Degree of confidence
     */
    int confidence;
}

// Accessor
-(void) setAge:(int)val;
-(int)age;
-(void) setConfidence:(int)val;
-(int)confidence;

@end


/**
 * Gender
 */
@interface GenResult : NSObject
{
    /**
     * Gender
     */
    HVC_GENDER  gender;
    /**
     * Degree of confidence
     */
    int confidence;
}

// Accessor
-(void) setGender:(HVC_GENDER)val;
-(HVC_GENDER)gender;
-(void) setConfidence:(int)val;
-(int)confidence;

@end


/**
 * Gaze
 */
@interface GazeResult : NSObject
{
    /**
     * Yaw angle
     */
    int gazeLR;
    /**
     * Pitch angle
     */
    int gazeUD;
}

// Accessor
-(void) setGazeLR:(int)val;
-(int)gazeLR;
-(void) setGazeUD:(int)val;
-(int)gazeUD;

@end


/**
 * Blink
 */
@interface BlinkResult : NSObject
{
    /**
     * Left eye blink result
     */
    int ratioL;
    /**
     * Right eye blink result
     */
    int ratioR;
}

// Accessor
-(void) setRatioL:(int)val;
-(int)ratioL;
-(void) setRatioR:(int)val;
-(int)ratioR;

@end


/**
 * Expression
 */
@interface ExpResult : NSObject
{
    /**
     * Expression
     */
    HVC_EXPRESSION expression;
    /**
     * Score
     */
    int score;
    /**
     * Negative-positive degree
     */
    int degree;
}

// Accessor
-(void) setExpression:(HVC_EXPRESSION)val;
-(HVC_EXPRESSION)expression;
-(void) setScore:(int)val;
-(int)score;
-(void) setDegree:(int)val;
-(int)degree;

@end


/**
 * Face Detection & Estimations results
 */
@interface FaceResult : DetectionResult
{
    /**
     * Face direction estimation result
     */
    DirResult *dir;
    /**
     * Age Estimation result
     */
    AgeResult *age;
    /**
     * Gender Estimation result
     */
    GenResult *gen;
    /**
     * Gaze Estimation result
     */
    GazeResult *gaze;
    /**
     * Blink Estimation result
     */
    BlinkResult *blink;
    /**
     * Expression Estimation result
     */
    ExpResult *exp;
}

// Accessor
-(void) setDir:(DirResult *)val;
-(DirResult *)dir;
-(void) setAge:(AgeResult *)val;
-(AgeResult *)age;
-(void) setGen:(GenResult *)val;
-(GenResult *)gen;
-(void) setGaze:(GazeResult *)val;
-(GazeResult *)gaze;
-(void) setBlink:(BlinkResult *)val;
-(BlinkResult *)blink;
-(void) setExp:(ExpResult *)val;
-(ExpResult *)exp;

@end


/**
 * HVC execution result 
 */
@interface HVC_RES : NSObject
{
    /**
     * Execution flag
     */
    HVC_FUNCTION executedFunc;
    /**
     * Human Body Detection results
     */
    NSMutableArray *body;
    /**
     * Hand Detection results
     */
    NSMutableArray *hand;
    /**
     * Face Detection, Estimations results
     */
    NSMutableArray *face;
}

// Reset
-(void)Reset:(HVC_FUNCTION)func;

// Accessor

// setter executedFunc
-(void) setExecutedFunc:(HVC_FUNCTION)func;
// getter executedFunc
-(HVC_FUNCTION)executedFunc;
// setter body DetectionResult
-(void) setBody:(DetectionResult *)dt;
// getter body DetectionResult
-(DetectionResult *)body:(int)index;
// Count of body DetectionResult
-(int)sizeBody;
// setter hand DetectionResult
-(void) setHand:(DetectionResult *)dt;
// getter hand DetectionResult
-(DetectionResult *)hand:(int)index;
// Count of hand DetectionResult
-(int)sizeHand;
// setter face DetectionResult
-(void) setFace:(FaceResult *)fd;
// getter face DetectionResult
-(FaceResult *)face:(int)index;
// Count of face DetectionResult
-(int)sizeFace;

@end
