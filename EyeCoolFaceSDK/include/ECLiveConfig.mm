//
//  ECLiveConfig.m
//  EyeCoolFace
//
//  Created by cocoa on 2019/1/11.
//  Copyright © 2019年 dev.keke@gmail.com. All rights reserved.
//

#import "ECLiveConfig.h"

static ECLiveConfig *share = nil;

@implementation ECLiveConfig

+ (instancetype)share{
    
    if (!share) {
        
        share = [[ECLiveConfig alloc] init];
        //默认值
        share.imgCompress = 85;
        share.timeOut = 15;
        share.isAudio = 1;
        share.definitionAsk = 20;
        share.action = 1;
        
        share.isLog = 1;
        share.deviceIdx = 0;
        share.shakeMax = 10;
        share.queueMax = 6;
        
        share.pupilDistMin = 70;
        share.pupilDistMax = 170;
        
        share.headLeft = -15;
        share.headRight = 15;
        share.headLow = 8;
        share.headHigh = -15;
        share.rollLeft = 15;
        share.rollRight = -15;
        share.eyeDegree = 10;
        share.mouthDegree = 30;
        
        share.mouThres = 8;
        share.yawThres = 5;
        share.pitThres = 4;
        share.eyeThres = 8;
        
        share.lostDetect = YES;
        share.lostCount = 4;
        share.onlyFocus = NO;
        
        share.willStartMsg = @"即将开始识别";
        share.pleaseFaceIn = @"请将人脸移入框内";
        share.pleaseClosely = @"请向前靠近一点";
        share.pleaseFarAwy = @"请向后远离一点";
        share.pleaseBlinkEyes = @"请眨眨眼";
        share.pleaseOpenMouth = @"请张张嘴";
        share.pleaseTurnHead = @"请转转头";
        share.pleaseNodHead = @"请上下点头";
        share.pleaseFocusCamera = @"请正脸直视摄像头";
        share.pleaseLookCamera = @"请正脸直视摄像头";
        share.pleaseNotCoverFace = @"请不要遮挡人脸";

        share.sdkBundleName = @"ECFaceSDK.bundle";
        
        //日志文件路径
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)lastObject];
        NSString *faceLog = [NSString stringWithFormat:@"%@/ecface.log",documentPath];
        share.logFile = faceLog;

    }
    return share;
}


+ (void)destory{
    share = nil;
}



- (void)dealloc
{
    _pleaseFaceIn = nil;
    _pleaseClosely = nil;
    _pleaseFarAwy = nil;
    _pleaseBlinkEyes = nil;
    _pleaseOpenMouth = nil;
    _pleaseTurnHead = nil;
    _pleaseNodHead = nil;
    _willStartMsg = nil;
    _liveTypeArr = nil;
    _logFile = nil;
    _sdkBundleName = nil;
    //NSLog(@"ECLiveConfig dealloc");
}

@end
