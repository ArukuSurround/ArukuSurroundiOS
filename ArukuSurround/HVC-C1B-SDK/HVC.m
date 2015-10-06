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
//  HVC.m
//

#import "HVC.h"

/**
 * HVC object
 * [Description]
 * New class object definition HVC
 */
@implementation HVC

-(id) init
{
    self = [super init];
    return self;
}

/**
 * Execute HVC functions
 */
-(HVC_ERRORCODE)Execute:(HVC_FUNCTION)inExec result:(HVC_RES *)result
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class Execute()");
    return HVC_NORMAL;
}

/**
 * Set HVC Parameters
 */
-(HVC_ERRORCODE)setParam:(HVC_PRM *)param
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class setParam()");
    return HVC_NORMAL;
}

/**
 * Get HVC Parameters
 */
-(HVC_ERRORCODE)getParam:(HVC_PRM *)param
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class getParam()");
    return HVC_NORMAL;
}

/**
 * Get HVC Version
 */
-(HVC_ERRORCODE)getVersion:(HVC_VER *)ver
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class getVersion()");
    return HVC_NORMAL;
}

/**
 * Send Signal
 */
-(int)Send:(NSMutableData *)data
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class send()");
    return (int)data.length;
}

/**
 * Receive Signal
 */
-(int)Receive:(NSMutableData **)data length:(int)dataLength timeOut:(int)timeout
{
    // The implementation is in the subclass. Here is dummy.
    NSLog(@"warn: HVC class receive()");
    return 0;
}

/* Command number */
typedef enum : NSInteger
{
    HVC_COM_GET_VERSION = 0x00,
    HVC_COM_SET_CAMERA_ANGLE = 0x01,
    HVC_COM_GET_CAMERA_ANGLE = 0x02,
    HVC_COM_EXECUTE = 0x03,
    HVC_COM_SET_THRESHOLD = 0x05,
    HVC_COM_GET_THRESHOLD = 0x06,
    HVC_COM_SET_SIZE_RANGE = 0x07,
    HVC_COM_GET_SIZE_RANGE = 0x08,
    HVC_COM_SET_DETECTION_ANGLE = 0x09,
    HVC_COM_GET_DETECTION_ANGLE = 0x0A,
    HVC_COM_GET_FULL_IMAGE_DATA = 0x80
} HVC_COMMAND;

#define HVC_SEND_SYNCBYTE 0xFE

/* Header for send signal data  */
typedef struct _hvc_send_header {
    unsigned char syncbyte;
    unsigned char commandno;
    unsigned char dataLengthLSB;
    unsigned char dataLengthMSB;
} HVC_SEND_HEADER;

/**
 * Send command signal
 * [Description]
 * none
 * [Notes]
 * @param inCommandNo command number
 * @param inDataSize sending signal data size
 * @param inData sending signal data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)SendCommand:(HVC_COMMAND)inCommandNo data:(NSData *)inData
{
    HVC_SEND_HEADER header;
    NSMutableData *sendData;
    
    /* Create header */
    header.syncbyte = HVC_SEND_SYNCBYTE;
    header.commandno = (unsigned char)inCommandNo;
    if ( inData != nil )
    {
        int datalen = (int)inData.length;
        header.dataLengthLSB = (unsigned char)(datalen & 0xff);
        header.dataLengthMSB = (unsigned char)((datalen >> 8) & 0xff);
    }
    else
    {
        header.dataLengthLSB = 0;
        header.dataLengthMSB = 0;
    }
    
    /* Create data */
    sendData = [[NSMutableData alloc] initWithBytes:&header length:sizeof(HVC_SEND_HEADER)];
    if ( inData != nil )
    {
        [sendData appendData:inData];
    }
    
    /* Send command signal */
    int r = [self Send:sendData];
    if ( r != sendData.length )
    {
        return HVC_ERROR_SENDDATA;
    }
    
    return HVC_NORMAL;
}

typedef struct _hvc_receive_header {
    unsigned char syncbyte;
    unsigned char status;
    unsigned char dataLenLL;
    unsigned char dataLenLM;
    unsigned char dataLenML;
    unsigned char dataLenMM;
} HVC_RECEIVE_HEADER;

/**
 * Receive header
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outDataSize receive signal data length
 * @param outStatus status
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)ReceiveHeader:(int)timeOut datalen:(int *)outDataSize status:(unsigned char *)outStatus
{
    /* Get header part */
    NSMutableData *recvData;
    int r = [self Receive:&recvData length:sizeof(HVC_RECEIVE_HEADER) timeOut:timeOut];
    if ( r != sizeof(HVC_RECEIVE_HEADER) )
    {
        NSLog(@"reH: ret=%d len=%lu", r, sizeof(HVC_RECEIVE_HEADER));
        return HVC_ERROR_HEADER_TIMEOUT;
    }
    HVC_RECEIVE_HEADER header;
    [recvData getBytes:&header length:sizeof(HVC_RECEIVE_HEADER)];
    if ( HVC_SEND_SYNCBYTE != header.syncbyte )
    {
        /* Different value indicates an invalid result */
        return HVC_ERROR_HEADER_INVALID;
    }
    
    /* Get data length */
    *outDataSize = header.dataLenLL + ( header.dataLenLM << 8 ) + ( header.dataLenML << 16 ) + ( header.dataLenMM << 24);
    /* Get command execution result */
    *outStatus = header.status;
    
    return HVC_NORMAL;
}

/**
 * Receive data
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param inDataSize receive signal data size
 * @param outResult receive signal data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)ReceiveData:(int)timeOut datalen:(int)inDataSize data:(NSMutableData **)outResult
{
    if ( inDataSize <= 0 )
    {
        return HVC_NORMAL;
    }
    
    /* Receive data */
    int r = [self Receive:outResult length:inDataSize timeOut:timeOut];
    if ( r != inDataSize )
    {
        return HVC_ERROR_DATA_TIMEOUT;
    }
    
    return HVC_NORMAL;
}


/**
 * GetVersion
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param ver version data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)GetVersion:(int)timeOut status:(unsigned char *)outStatus version:(HVC_VER *)ver
{
    HVC_ERRORCODE err;
    
    NSLog(@"start GetVersion");
    /* Send GetVersion command signal*/
    err = [self SendCommand:HVC_COM_GET_VERSION data:nil];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"sendcommand error");
        return err;
    }
    
    NSLog(@"getversion receiveHeader");
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"receiveHeader error");
        return err;
    }
    
    NSLog(@"getversion receiveData");
    /* Receive data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:dataLen data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"receiveData error");
        return err;
    }
    unsigned char rDat[HVC_LEN_VERSIONSTRING+7];
    [recvDat getBytes:&rDat length:HVC_LEN_VERSIONSTRING+7];
    for ( int i=0; i<HVC_LEN_VERSIONSTRING; i++ ) ver.Str[i] = rDat[i];
    ver.Major = rDat[HVC_LEN_VERSIONSTRING];
    ver.Minor = rDat[HVC_LEN_VERSIONSTRING+1];
    ver.Release = rDat[HVC_LEN_VERSIONSTRING+2];
    ver.Rev = rDat[HVC_LEN_VERSIONSTRING+3] +
             (rDat[HVC_LEN_VERSIONSTRING+4]<<8) +
             (rDat[HVC_LEN_VERSIONSTRING+5]<<16) +
             (rDat[HVC_LEN_VERSIONSTRING+6]<<24);
    
    return HVC_NORMAL;
}

/**
 * SetCameraAngle
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)SetCameraAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    unsigned char datasrc[1];
    datasrc[0] = (unsigned char)param.CameraAngle;
    NSData *sendData = [[NSData alloc] initWithBytes:&datasrc length:1];
    
    /* Send SetCameraAngle command signal */
    err = [self SendCommand:HVC_COM_SET_CAMERA_ANGLE data:sendData];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    return HVC_NORMAL;
}

/**
 * GetCameraAngle
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)GetCameraAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    /* Send GetCameraAngle command signal */
    err = [self SendCommand:HVC_COM_GET_CAMERA_ANGLE data:nil];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:dataLen data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    unsigned char rDat[1];
    [recvDat getBytes:&rDat length:1];
    param.CameraAngle = rDat[0];
    
    return HVC_NORMAL;
}

/**
 * SetThreshold
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)SetThreshold:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    unsigned char datasrc[8];
    datasrc[0] = (unsigned char)(param.body.Threshold & 0xff);
    datasrc[1] = (unsigned char)(param.body.Threshold >> 8);
    datasrc[2] = (unsigned char)(param.hand.Threshold & 0xff);
    datasrc[3] = (unsigned char)(param.hand.Threshold >> 8);
    datasrc[4] = (unsigned char)(param.face.Threshold & 0xff);
    datasrc[5] = (unsigned char)(param.face.Threshold >> 8);
    datasrc[6] = 0x00;
    datasrc[7] = 0x00;
    NSData *sendData = [[NSData alloc] initWithBytes:&datasrc length:8];
    
    /* Send SetThreshold command signal */
    err = [self SendCommand:HVC_COM_SET_THRESHOLD data:sendData];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    return HVC_NORMAL;
}

/**
 * GetThreshold
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)GetThreshold:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    /* Send GetThreshold command signal */
    err = [self SendCommand:HVC_COM_GET_THRESHOLD data:nil];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:dataLen data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    unsigned char rDat[8];
    [recvDat getBytes:&rDat length:8];
    param.body.Threshold = (int)(rDat[0] + ( rDat[1] << 8 ));
    param.hand.Threshold = (int)(rDat[2] + ( rDat[3] << 8 ));
    param.face.Threshold =  rDat[4] + ( rDat[5] << 8 );
    
    return HVC_NORMAL;
}

/**
 * SetSizeRange
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)SetSizeRange:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    unsigned char datasrc[12];
    datasrc[0] = (unsigned char)(param.body.MinSize & 0xff);
    datasrc[1] = (unsigned char)(param.body.MinSize >> 8);
    datasrc[2] = (unsigned char)(param.body.MaxSize & 0xff);
    datasrc[3] = (unsigned char)(param.body.MaxSize >> 8);
    datasrc[4] = (unsigned char)(param.hand.MinSize & 0xff);
    datasrc[5] = (unsigned char)(param.hand.MinSize >> 8);
    datasrc[6] = (unsigned char)(param.hand.MaxSize & 0xff);
    datasrc[7] = (unsigned char)(param.hand.MaxSize >> 8);
    datasrc[8] = (unsigned char)(param.face.MinSize & 0xff);
    datasrc[9] = (unsigned char)(param.face.MinSize >> 8);
    datasrc[10] = (unsigned char)(param.face.MaxSize & 0xff);
    datasrc[11] = (unsigned char)(param.face.MaxSize >> 8);
    NSData *sendData = [[NSData alloc] initWithBytes:&datasrc length:12];
    
    /* Send SetSizeRange command signal */
    err = [self SendCommand:HVC_COM_SET_SIZE_RANGE data:sendData];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    return HVC_NORMAL;
}

/**
 * GetSizeRange
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)GetSizeRange:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    /* Send GetSizeRange command signal */
    err = [self SendCommand:HVC_COM_GET_SIZE_RANGE data:nil];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:dataLen data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    unsigned char rDat[12];
    [recvDat getBytes:&rDat length:12];
    param.body.MinSize = (int)(rDat[0] + ( rDat[1] << 8 ));
    param.body.MaxSize = (int)(rDat[2] + ( rDat[3] << 8 ));
    param.hand.MinSize = (int)(rDat[4] + ( rDat[5] << 8 ));
    param.hand.MaxSize = (int)(rDat[6] + ( rDat[7] << 8 ));
    param.face.MinSize = (int)(rDat[8] + ( rDat[9] << 8 ));
    param.face.MaxSize = (int)(rDat[10] + ( rDat[11] << 8 ));
    
    return HVC_NORMAL;
}

/**
 * SetFaceDetectionAngle
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)SetFaceDetectionAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    unsigned char datasrc[2];
    datasrc[0] = (unsigned char)(param.face.Pose & 0xff);
    datasrc[1] = (unsigned char)(param.face.Angle & 0xff);
    NSData *sendData = [[NSData alloc] initWithBytes:&datasrc length:2];
    
    /* Send SetFaceDetectionAngle command signal */
    err = [self SendCommand:HVC_COM_SET_DETECTION_ANGLE data:sendData];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        return err;
    }
    
    return HVC_NORMAL;
}

/**
 * GetFaceDetectionAngle
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param outStatus response code
 * @param param parameter data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)GetFaceDetectionAngle:(int)timeOut status:(unsigned char *)outStatus parameter:(HVC_PRM *)param
{
    HVC_ERRORCODE err;
    
    /* Send GetFaceDetectionAngle signal command */
    err = [self SendCommand:HVC_COM_GET_DETECTION_ANGLE data:nil];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"sendcommand err:%d", (int)err);
        return err;
    }
    
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"recvhd err:%d", (int)err);
        return err;
    }
    
    /* Receive data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:dataLen data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"recvdat err:%d", (int)err);
        return err;
    }
    unsigned char rDat[2];
    [recvDat getBytes:&rDat length:2];
    param.face.Pose = (int)(rDat[0]);
    param.face.Angle = (int)(rDat[1]);
    
    return HVC_NORMAL;
}

/**
 * Execute
 * [Description]
 * none
 * [Notes]
 * @param inTimeOutTime timeout time
 * @param inExec executable function
 * @param outStatus response code
 * @param result result data
 * @return int execution result error code 
 */
-(HVC_ERRORCODE)ExecuteFunc:(int)timeOut exec:(HVC_FUNCTION)inExec status:(unsigned char *)outStatus result:(HVC_RES *)result
{
    HVC_ERRORCODE err;
    
    // Reset result data
    [result Reset:inExec];
    
    unsigned char datasrc[3];
    datasrc[0] = (unsigned char)(inExec & 0xff);
    datasrc[1] = (unsigned char)(inExec >> 8);
    datasrc[2] = 0x00;
    NSData *sendData = [[NSData alloc] initWithBytes:&datasrc length:3];
    
    NSLog(@"Execute : SendCommand");
    /* Send Execute command signal */
    err = [self SendCommand:HVC_COM_EXECUTE data:sendData];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"err:%d", (int)err);
        return err;
    }
    
    NSLog(@"Execute : ReceiveHeader");
    /* Receive header */
    int dataLen = 0;
    err = [self ReceiveHeader:timeOut datalen:&dataLen status:outStatus];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"err:%d", (int)err);
        return err;
    }
    // Length of data checked
    if ( dataLen < 4 )
    {
        // No data
        NSLog(@"no result:%d", dataLen);
        return HVC_NORMAL;
    }
    
    NSLog(@"Execute : ReceiveData:%d", dataLen);
    /* Receive result data */
    NSMutableData *recvDat;
    err = [self ReceiveData:timeOut datalen:4 data:&recvDat];
    if ( err != HVC_NORMAL )
    {
        NSLog(@"err:%d", (int)err);
        return err;
    }
    unsigned char rDat[4];
    [recvDat getBytes:&rDat length:4];
    int numBody = rDat[0];
    int numHand = rDat[1];
    int numFace = rDat[2];
    dataLen -= 4;
    NSLog(@"Execute : body=%d hand=%d face=%d", numBody, numHand, numFace);
    
    /* Get Human Body Detection result */
    for ( int i = 0 ; i < numBody ; i++ )
    {
        if ( dataLen >= 8 )
        {
            NSLog(@"Execute : ReceiveData(BodyDetect):8");
            [recvDat setLength:0];
            err = [self ReceiveData:timeOut datalen:8 data:&recvDat];
            if ( err != HVC_NORMAL )
            {
                NSLog(@"err:%d", (int)err);
                return err;
            }
            unsigned char rDat[8];
            DetectionResult *dt = [[DetectionResult alloc] init];
            [recvDat getBytes:&rDat length:8];
            dt.posX = (int)( rDat[0] + ( rDat[1] << 8) );
            dt.posY = (int)( rDat[2] + ( rDat[3] << 8) );
            dt.size = (int)( rDat[4] + ( rDat[5] << 8) );
            dt.confidence = (int)( rDat[6] + ( rDat[7] << 8) );
            dataLen -= 8;
            [result setBody:dt];
        }
    }
    
    /* Get Hand Detection result */
    for ( int i = 0 ; i < numHand ; i++ )
    {
        if ( dataLen >= 8 )
        {
            NSLog(@"Execute : ReceiveData(HandDetect):8");
            [recvDat setLength:0];
            err = [self ReceiveData:timeOut datalen:8 data:&recvDat];
            if ( err != HVC_NORMAL )
            {
                NSLog(@"err:%d", (int)err);
                return err;
            }
            unsigned char rDat[8];
            DetectionResult *dt = [[DetectionResult alloc] init];
            [recvDat getBytes:&rDat length:8];
            dt.posX = (int)( rDat[0] + ( rDat[1] << 8) );
            dt.posY = (int)( rDat[2] + ( rDat[3] << 8) );
            dt.size = (int)( rDat[4] + ( rDat[5] << 8) );
            dt.confidence = (int)( rDat[6] + ( rDat[7] << 8) );
            dataLen -= 8;
            [result setHand:dt];
        }
    }
    
    /* Face-related results */
    for ( int i = 0 ; i < numFace ; i++ )
    {
        FaceResult *fd = [[FaceResult alloc] init];
        
        /* Face Detection result */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_FACE_DETECTION) )
        {
            if ( dataLen >= 8 )
            {
                NSLog(@"Execute : ReceiveData(FaceDetect):8");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:8 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[8];
                [recvDat getBytes:&rDat length:8];
                fd.posX = (int)( rDat[0] + ( rDat[1] << 8) );
                fd.posY = (int)( rDat[2] + ( rDat[3] << 8) );
                fd.size = (int)( rDat[4] + ( rDat[5] << 8) );
                fd.confidence = (int)( rDat[6] + ( rDat[7] << 8) );
                dataLen -= 8;
            }
        }
        
        /* Face direction */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_FACE_DIRECTION) )
        {
            if ( dataLen >= 8 )
            {
                NSLog(@"Execute : ReceiveData(FaceDirection):8");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:8 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[8];
                [recvDat getBytes:&rDat length:8];
                fd.dir.yaw = (short)( rDat[0] + ( rDat[1] << 8) );
                fd.dir.pitch = (short)( rDat[2] + ( rDat[3] << 8) );
                fd.dir.roll = (short)( rDat[4] + ( rDat[5] << 8) );
                fd.dir.confidence = (short)( rDat[6] + ( rDat[7] << 8) );
                dataLen -= 8;
            }
        }
        
        /* Age */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_AGE_ESTIMATION) )
        {
            if ( dataLen >= 3 )
            {
                NSLog(@"Execute : ReceiveData(AgeEstimation):3");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:3 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[3];
                [recvDat getBytes:&rDat length:3];
                fd.age.age = (char)rDat[0];
                fd.age.confidence = (short)( rDat[1] + ( rDat[2] << 8) );
                dataLen -= 3;
            }
        }
        
        /* Gender */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_GENDER_ESTIMATION) )
        {
            if ( dataLen >= 3 )
            {
                NSLog(@"Execute : ReceiveData(GenderEstimation):3");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:3 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[3];
                [recvDat getBytes:&rDat length:3];
                fd.gen.gender = (char)rDat[0];
                fd.gen.confidence = (short)( rDat[1] + ( rDat[2] << 8) );
                dataLen -= 3;
            }
        }
        
        /* Gaze */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_GAZE_ESTIMATION) )
        {
            if ( dataLen >= 2 )
            {
                NSLog(@"Execute : ReceiveData(GazeEstimation):2");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:2 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[2];
                [recvDat getBytes:&rDat length:2];
                fd.gaze.gazeLR = (char)rDat[0];
                fd.gaze.gazeUD = (char)rDat[1];
                dataLen -= 2;
            }
        }
        
        /* Blink */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_BLINK_ESTIMATION) )
        {
            if ( dataLen >= 4 )
            {
                NSLog(@"Execute : ReceiveData(BlinkEstimation):4");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:4 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[4];
                [recvDat getBytes:&rDat length:4];
                fd.blink.ratioL = (short)( rDat[0] + ( rDat[1] << 8) );
                fd.blink.ratioR = (short)( rDat[2] + ( rDat[3] << 8) );
                dataLen -= 4;
            }
        }
        
        /* Expression */
        if ( 0 != ( result.executedFunc & HVC_ACTIV_EXPRESSION_ESTIMATION) )
        {
            if ( dataLen >= 3 )
            {
                NSLog(@"Execute : ReceiveData(ExpressionEstimate):3");
                [recvDat setLength:0];
                err = [self ReceiveData:timeOut datalen:3 data:&recvDat];
                if ( err != HVC_NORMAL )
                {
                    NSLog(@"err:%d", (int)err);
                    return err;
                }
                unsigned char rDat[3];
                [recvDat getBytes:&rDat length:3];
                fd.exp.expression = (char)rDat[0];
                fd.exp.score = (char)rDat[1];
                fd.exp.degree = (char)rDat[2];
                dataLen -= 3;
            }
        }
        [result setFace:fd];
    }
    
    return HVC_NORMAL;
}

@end
