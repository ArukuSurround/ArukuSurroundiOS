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
//  HVC_VER.h
//

#import <Foundation/Foundation.h>

#import "HVCC_Define.h"

/**
 * Version (GetVersion result)
 */
@interface HVC_VER : NSObject
{
    /**
     * Version string
     */
    unsigned char str[HVC_LEN_VERSIONSTRING];
    /**
     * Major version number
     */
    unsigned char major;
    /**
     * Minor version number
     */
    unsigned char minor;
    /**
     * Release version number
     */
    unsigned char release;
    /**
     * Revision number
     */
    unsigned int rev;
}

// Accessor
-(void) setStr:(unsigned char *)value;
-(unsigned char *)Str;
-(void) setMajor:(unsigned char)value;
-(unsigned char)Major;
-(void) setMinor:(unsigned char)value;
-(unsigned char)Minor;
-(void) setRelease:(unsigned char)value;
-(unsigned char)Release;
-(void) setRev:(unsigned int)value;
-(unsigned int)Rev;

/**
 * Get version string
 * [Description]
 * Return HVC version number as a string
 * @return String version number string
 */
-(NSString *) getString;

@end
