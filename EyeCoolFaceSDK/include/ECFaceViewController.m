//
//  ECFaceViewController.m
//  EyeCoolFace
//
//  Created by cocoa on 2019/1/13.
//  Copyright © 2019年 dev.keke@gmail.com. All rights reserved.
//

#import "ECFaceViewController.h"
#import "ECAudioPlayer.h"
#import "ECLiveConfig.h"
#import "ECFaceDetecter.h"
#import "ECCameraManager.h"
#import "ECCoverView.h"

@interface ECFaceViewController ()

@property (nonatomic,strong)ECCoverView *coverUI;           //UI界面
@property (nonatomic,strong)ECFaceDetecter *faceDetecter;   //人脸检测器
@property (nonatomic,strong)ECCameraManager *cameraManager; //摄像头管理
@property (nonatomic,strong)NSArray *liveTypeArr;           //检活动作
@property (nonatomic,assign)CGFloat brightness; //屏幕亮度；


@end

@implementation ECFaceViewController

+ (NSDictionary *)sdkInfo{
    return [ECFaceDetecter sdkInfo];
}

- (void)initBaseUIAndSet
{
    //UI
    self.view.backgroundColor = [UIColor whiteColor];
    CGRect fRect = self.view.frame;
    if (@available(iOS 11.0, *)) {
        CGFloat a =  [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom;
        if (a >0) {
            //fRect.origin.y += 20;
        }
    }
    
    self.coverUI = [[ECCoverView alloc]initWithFrame:fRect];
    _coverUI.delegate = self;
    _coverUI.stateLB.text = [ECLiveConfig share].willStartMsg;
    [self.view addSubview:_coverUI];
    
    //Camera
    AVCaptureDevicePosition deviPosi = AVCaptureDevicePositionFront;
    if ([ECLiveConfig share].deviceIdx == 1) {
        deviPosi = AVCaptureDevicePositionBack;
    }
    self.cameraManager = [[ECCameraManager alloc]initWithVideoOrientation:AVCaptureVideoOrientationPortrait cameraPosition:deviPosi sessionPreset:AVCaptureSessionPreset640x480];
    _cameraManager.delegate = self;
    BOOL bCamera = [_cameraManager openCamera];
    if (!bCamera) {
        return ;
    }
    [_cameraManager showPreviewOnLayer:_coverUI.liveView.layer frame:_coverUI.liveFrame];
    
    //SSAlg
    NSBundle *sdkBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:[ECLiveConfig share].sdkBundleName ofType:nil]];
    NSString *datPath = [sdkBundle pathForResource:@"model2020.dat" ofType:nil];
    NSString *licPath = [sdkBundle pathForResource:@"EyeCoolLive.lic" ofType:nil];
    self.faceDetecter = [[ECFaceDetecter alloc]initWithDat:datPath license:licPath imgWidth:480 imgHeight:640];
    _faceDetecter.delegate = self;
    
}

//关闭卸载
- (void)closePageSet{
    
    if (_faceDetecter) {
        _faceDetecter = nil;
    }
    
    if (_cameraManager) {
        [_cameraManager stopBuffer];
        [_cameraManager closeCamera];
        _cameraManager = nil;
    }
    
    _coverUI = nil;

}

//关闭按钮代理
- (void)didClickECCoverViewCloseBtn{
    [_faceDetecter stopLiveDetect];
    [self closePageSet];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.brightness = [UIScreen mainScreen].brightness;
    [UIScreen mainScreen].brightness = 0.9f;


    //init Base
    [self initBaseUIAndSet];
    
    //参数配置
    [ECAudioPlayer share].bOn = [ECLiveConfig share].isAudio;
    
    //动作处理，内部随机，如果外部不配置，则内部随意第一个为眨眼
    if ([ECLiveConfig share].liveTypeArr.count == 0) {
        NSArray *allArr = @[@(ECLivenessEYE),@(ECLivenessMOU),@(ECLivenessNOD),@(ECLivenessYAW)];
        NSArray *noEyeArr = @[@(ECLivenessMOU),@(ECLivenessNOD),@(ECLivenessYAW)];
        allArr = [self arrSortRandom:allArr];
        noEyeArr = [self arrSortRandom:noEyeArr];
        if ([ECLiveConfig share].action==1) {
            //self.liveTypeArr = @[allArr[0]];
            self.liveTypeArr = @[@(ECLivenessEYE)];
        }else if ([ECLiveConfig share].action==2) {
            self.liveTypeArr = @[@(ECLivenessEYE),noEyeArr[0]];
        }else if ([ECLiveConfig share].action==3) {
            self.liveTypeArr = @[@(ECLivenessEYE),noEyeArr[0],noEyeArr[1]];
        }else if ([ECLiveConfig share].action==4) {
            self.liveTypeArr = @[@(ECLivenessEYE),noEyeArr[0],noEyeArr[1],noEyeArr[2]];
        }else{
            self.liveTypeArr = @[@(ECLivenessEYE),noEyeArr[0]];
        }
    }else{
        //按外部配置动作
        self.liveTypeArr = [ECLiveConfig share].liveTypeArr;
    }
    
    
    //相机权限判断
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus==AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (granted==NO) {
                    //无权限
                    [self sendCameraNotAuthMessage];
                }else{
                    [self startFaceLiveCheck];
                }
            });
        }];
    }
    else if (authStatus==AVAuthorizationStatusAuthorized) {
        //有权限了
        [self startFaceLiveCheck];
    }else{
        //无权限
        [self sendCameraNotAuthMessage];
    }
    
    

    //判断授权信息，如果是测试版本增加页面提示
    NSDictionary *authInfo = [ECFaceDetecter sdkInfo];
    NSArray *licArr = [authInfo objectForKey:@"sdk_license"];
    if (licArr.count <1) {
        return;
    }
    BOOL bAuth = NO;
    NSString *licTime = @"";
    for (NSString *str in licArr) {
        if ([str containsString:@"Permanent"]) {
            bAuth = YES;
            break;
        }
        
        if ([str hasPrefix:@"LicenseTime"]) {
            licTime = [[str componentsSeparatedByString:@" "] objectAtIndex:1];
        }
        
    }
    
    if (!bAuth) {
        UILabel *tipsLB = [[UILabel alloc]initWithFrame:CGRectMake(70, self.view.bounds.size.height - 60, self.view.bounds.size.width - 140, 40)];
        tipsLB.textColor = [UIColor whiteColor];
        tipsLB.backgroundColor = [UIColor lightGrayColor];
        tipsLB.textAlignment = NSTextAlignmentCenter;
        tipsLB.clipsToBounds = YES;
        tipsLB.layer.cornerRadius = 20;
        tipsLB.text = [NSString stringWithFormat:@"测试版，到期：%@",licTime];
        tipsLB.numberOfLines = 0;
        tipsLB.font = [UIFont systemFontOfSize:15];
        [self.view addSubview:tipsLB];
        //tipsLB.hidden = YES;
    }
    
}


//开始
- (void)startFaceLiveCheck{
    [_cameraManager startBuffer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.faceDetecter startLiveDetect];
    });
}

//发送相机权限问题回调
- (void)sendCameraNotAuthMessage{

    [self closePageSet];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if ([self.delegate respondsToSelector:@selector(faceLivenessFailedWithError:liveType:)]) {
                [self.delegate faceLivenessFailedWithError:ECLivenessErrorCameraNotAuth liveType:0];
            }
            
        }];
    });
 
}

#pragma mark 检测器代理
//成功回调
- (void)ECFaceLiveCheckSuccessGetImage:(NSArray *)imgArr{
    
    [UIScreen mainScreen].brightness = self.brightness;

    __weak typeof(self) weakSelf = self;
    [self closePageSet];
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(faceLivenessSuccessWithImg:liveArr:)]) {
            [self.delegate faceLivenessSuccessWithImg:imgArr liveArr:weakSelf.liveTypeArr];
        }
    }];
    

}

//检测错误
- (void)ECFaceDetecterWithError:(ECDetectError )aErr liveType:(ECLiveType)alive{
    NSString *msg;
    //NSLog(@"%d %d",aErr,alive);
    switch (aErr) {
        case ECDetectErrorDuckDatNotExist:
            msg = @"模型文件不存在";
            break;
        case ECDetectErrorDuckLicNotExist:
            msg = @"授权文件不存在";
            break;
        case ECDetectErrorDuckExpiration:
            msg = @"时间版，授权过期";
            break;
        case ECDetectErrorDuckNotMatch:
            msg = @"包名绑定不一致";
            break;
        case ECDetectErrorDuckInitOther:
            msg = @"算法初始化错误";
            break;
        case ECDetectErrorLiveCheckCancel:
            msg = @"检活取消了";
            break;
        case ECDetectErrorTimeOutNoFace:
            msg = @"超时，未检测到人脸";
            [self.coverUI.progressView setProgress:1.0f animated:NO];
            break;
        case ECDetectErrorTimeOutNoPass:
            msg = @"超时，动作未通过";
            [self.coverUI.progressView setProgress:1.0f animated:NO];
            break;
        case ECDetectErrorCurrentFaceLost:
            msg = @"丢帧检测，中突换人";
            [self.coverUI.progressView setProgress:1.0f animated:NO];
            break;
        case ECDetectErrorNotLiveFace:
            msg = @"检测到非活体";
            break;
        default:
            break;
    }

    [self closePageSet];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(faceLivenessFailedWithError:liveType:)]) {
            [self.delegate faceLivenessFailedWithError:(ECLivenessError)aErr liveType:(ECLivenessType)alive];
        }
    }];
    
    [UIScreen mainScreen].brightness = self.brightness;

    
}

//检活过程中状态回调
- (void)ECFaceLiveState:(ECLiveState)liveState liveType:(ECLiveType)alive{
    NSString *msg;
    switch (liveState) {
        case ECLiveStateFaceNormal:
            msg = @"人脸检测正常";
            self.coverUI.stateLB.text = [self liveMsgFromLiveType:alive];
            [_coverUI setFaceInUI];
            break;
        case ECLiveStateFaceLeave:
            msg = @"人脸离开";
            self.coverUI.stateLB.text = [ECLiveConfig share].pleaseFaceIn;
            [_coverUI setFaceOutUI];
            break;
        case ECLiveStateFaceShake:
            msg = @"人脸晃动";
            //[_coverUI setFaceOutUI];
            break;
        case ECLiveStateFaceFar:
            msg = @"人脸太远";
            self.coverUI.stateLB.text = [ECLiveConfig share].pleaseClosely;
            [[ECAudioPlayer share] playAudio:ECAudioClosely];
            [_coverUI setFaceOutUI];
            break;
        case ECLiveStateFaceClose:
            msg = @"人脸太近";
            self.coverUI.stateLB.text = [ECLiveConfig share].pleaseFarAwy;
            [[ECAudioPlayer share] playAudio:ECAudioFarAway];
            [_coverUI setFaceOutUI];
            break;
        case ECLiveStateNotLookCamera:
            self.coverUI.stateLB.text = [ECLiveConfig share].pleaseFocusCamera;
            [_coverUI setFaceOutUI];
            break;
        case ECLiveStateFaceHasCover:
            self.coverUI.stateLB.text = [ECLiveConfig share].pleaseNotCoverFace;
            
            break;
        case ECLiveStateFaceHackNoPass:
            self.coverUI.stateLB.text = @"检测到假体";
            [_coverUI setFaceOutUI];
            break;
        default:
            break;
    }
    //NSLog(@"状态：%d %@",liveState,msg);

}

//检测某个动作的倒计时，还剩下多长时间时间,单位秒
- (void)ECFaceCheckOneLive:(ECLiveType )alive leftTime:(int)leftTime{
    //NSLog(@"计时：%d %d",alive,leftTime);
    self.coverUI.progressView.progressLabel.text = [NSString stringWithFormat:@"%d",leftTime];
    [self.coverUI.progressView setProgress:(self.coverUI.progressView.progress+(1.0f/[ECLiveConfig share].timeOut)) animated:YES];


}

//将要开始进行某个动作检活
- (void)ECFaceLiveWillStartCheck:(ECLiveType )alive{
    //NSLog(@"将要开始检测：%d",alive);
    self.coverUI.progressView.progressLabel.text = [NSString stringWithFormat:@"%d",[ECLiveConfig share].timeOut];
    [self.coverUI.progressView setProgress:0 animated:NO];

    [self playVideoFromLiveType:alive];
    NSString *msg = [self liveMsgFromLiveType:alive];
    self.coverUI.stateLB.text = msg;
    [_coverUI setFaceInUI];
    [_coverUI playFaceAnimation:alive];

    
}


//结束某个动作检测
- (void)ECFaceLiveDidCompleteCheck:(ECLiveType )alive{
    //NSLog(@"结束检测：%d",alive);
    [[ECAudioPlayer share] playAudio:ECAudioGood];
    [_coverUI stopFaceAnimation];
}

///检活动作组合
- (NSArray *)ECFaceLiveCheckSequence{
    if ([ECLiveConfig share].onlyFocus) {
        return [NSArray array];
    }
    return self.liveTypeArr;
    
}

//检活单个动作的超时时间
- (int)ECFaceLiveOneActionTime{
    return [ECLiveConfig share].timeOut;
}

#pragma mark private api
- (void)playVideoFromLiveType:(ECLiveType )alive{
    
    switch (alive) {
        case ECLiveEYE:
            [[ECAudioPlayer share] playAudio:ECAudioBlinkEyes];
            break;
        case ECLiveMOU:
            [[ECAudioPlayer share] playAudio:ECAudioOpenMouth];
            break;
        case ECLiveYAW:
            [[ECAudioPlayer share] playAudio:ECAudioYawHead];
            break;
        case ECLiveNOD:
            [[ECAudioPlayer share] playAudio:ECAudioNodHead];
            break;
        default:
            break;
    }
}


-(NSString *)liveMsgFromLiveType:(ECLiveType )alive
{
    NSString *msg = @"";
    switch (alive) {
        case ECLiveEYE:
            msg = [ECLiveConfig share].pleaseBlinkEyes;
            break;
        case ECLiveMOU:
            msg = [ECLiveConfig share].pleaseOpenMouth;
            break;
        case ECLiveYAW:
            msg = [ECLiveConfig share].pleaseTurnHead;
            break;
        case ECLiveNOD:
            msg = [ECLiveConfig share].pleaseNodHead;
            break;
        case ECLiveLOOK:
            msg = [ECLiveConfig share].pleaseLookCamera;
            break;
        default:
            break;
    }
    return msg;
}

- (NSArray *)arrSortRandom:(NSArray *)arr{
    NSArray *sortArr = [arr sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
        int seed = arc4random_uniform(2);
        if (seed) {
            return [str1 compare:str2];
        } else {
            return [str2 compare:str1];
        }
    }];
    return sortArr;
}

#pragma mark Camera 代理

- (void)cameraDidOutputBuffer:(CMSampleBufferRef )sampleBuffer{
    if (self.faceDetecter) {
        [self.faceDetecter pushDetectBuffer:sampleBuffer videoOri:AVCaptureVideoOrientationPortrait];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault; //白色
}


- (void)dealloc
{
    _coverUI = nil;
    _faceDetecter = nil;
    _cameraManager = nil;
    _liveTypeArr = nil;
    [ECAudioPlayer destory];
    //NSLog(@"ECFaceViewController dealloc");
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
