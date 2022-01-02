//
//  AGVideoPreProcessing.h
//  OpenVideoCall
//
//  Created by Alex Zheng on 7/28/16.
//  Copyright © 2016 Agora.io All rights reserved.
//

#import <UIKit/UIKit.h>

//todo --- tillusory start0 ---
#import "TiUIManager.h"
#import <TiSDK/TiSDKInterface.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
//todo --- tillusory end0 ---

@class AgoraRtcEngineKit;

@interface AGVideoPreProcessing : NSObject

+ (void)setViewControllerDelegate:(id)viewController;
+ (int) registerVideoPreprocessing:(AgoraRtcEngineKit*) kit;
+ (int) deregisterVideoPreprocessing:(AgoraRtcEngineKit*) kit;

@end
		
