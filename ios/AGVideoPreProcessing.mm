//
//  AGVideoPreProcessing.m
//  OpenVideoCall
//
//  Created by Alex Zheng on 7/28/16.
//  Copyright © 2016 Agora.io All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGVideoPreProcessing.h"
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import <AgoraRtcKit/IAgoraRtcEngine.h>
#import <AgoraRtcKit/IAgoraMediaEngine.h>
//#import <AgoraRtcEngineKit/AgoraRtcEngineKit.h>
//#import <AgoraRtcEngineKit/IAgoraRtcEngine.h>
//#import <AgoraRtcEngineKit/IAgoraMediaEngine.h>
#import <string.h>
#import <CoreVideo/CVPixelBuffer.h>

static NSNumber *isRelease = @0;

class AgoraAudioFrameObserver : public agora::media::IAudioFrameObserver
{
public:
    virtual bool onRecordAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    }
    virtual bool onPlaybackAudioFrame(AudioFrame& audioFrame) override
    {
        return true;
    }
    virtual bool onPlaybackAudioFrameBeforeMixing(unsigned int uid, AudioFrame& audioFrame) override
    {
        return true;
    }
    
};

NSTimeInterval _lastTime;
NSUInteger _count;

CFDictionaryRef empty; // empty value for attr value.
CFMutableDictionaryRef attrs;

class AgoraVideoFrameObserver : public agora::media::IVideoFrameObserver
{
public:
    
    virtual bool onCaptureVideoFrame(VideoFrame& videoFrame) override
    {
        @synchronized (isRelease) {
            if ([isRelease boolValue]) {
                return true;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            return;
        });

        /* 横竖屏时更新sdk内置UI 坐标 */
        VideoFrame frame;
        
        frame.type = (VIDEO_FRAME_TYPE)videoFrame.type;
        
        frame.width = videoFrame.width;
        
        frame.height = videoFrame.height;
        
        frame.yBuffer = videoFrame.yBuffer;
        
        frame.uBuffer = videoFrame.uBuffer;
        
        frame.vBuffer = videoFrame.vBuffer;
        
        frame.yStride = videoFrame.yStride;
        
        frame.uStride = videoFrame.uStride;
        
        frame.vStride = videoFrame.vStride;
        
        //todo --- tillusory start3 ---
        // 根据YUV创建PixelBuffer
        CVPixelBufferRef pixelBuffer;
        NSDictionary *pixelBufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionary], kCVPixelBufferIOSurfacePropertiesKey, nil];
        CVPixelBufferCreate(NULL, frame.width, frame.height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        unsigned char* yByte = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        int yLength = videoFrame.width * videoFrame.height;
        memcpy(yByte, videoFrame.yBuffer, yLength);
    
        unsigned char* uvByte = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        
        int i = 0;
        int uLength = yLength / 4;
        for (int j = 0; j < uLength; i += 2, j++) {
            uvByte[i] = ((unsigned char *) videoFrame.uBuffer)[j];//u
            uvByte[i + 1] = ((unsigned char *) videoFrame.vBuffer)[j];//v
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//        bool isMirror = YES; // 根据摄像头前置或后置设定，前置为True，后置为False
        //todo --- tillusory start4 ---
        bool isMirror = YES;
        //todo --- tillusory end4 ---
        
        UIDeviceOrientation iDeviceOrientation = [[UIDevice currentDevice] orientation];
        TiRotationEnum rotation;
        switch (iDeviceOrientation) {
            case UIDeviceOrientationPortrait:
                rotation = CLOCKWISE_90;
                break;
            case UIDeviceOrientationLandscapeLeft:
                rotation = isMirror ? CLOCKWISE_90 : CLOCKWISE_270;
                break;
            case UIDeviceOrientationLandscapeRight:
                rotation = isMirror ? CLOCKWISE_270 : CLOCKWISE_90;
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                rotation = CLOCKWISE_180;
                break;
            default:
                rotation = CLOCKWISE_0;
                break;
        }
        
        int iWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
        int iHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
        unsigned char *pixels = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
        
        if (pixels != nil) {
            [[TiSDKManager shareManager] renderPixels:pixels Format:NV12 Width:iWidth Height:iHeight Rotation:CLOCKWISE_90 Mirror:!isMirror];
        }
        
        unsigned char* yRenderByte = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        for (i = 0; i < yLength; i++) {
            ((unsigned char *)videoFrame.yBuffer)[i] = yRenderByte[i];
        }
        unsigned char* uvRenderByte = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        i = 0;
        for (int j = 0; j < uLength; i += 2, j++) {
            ((unsigned char *)videoFrame.uBuffer)[j] = uvRenderByte[i];
            ((unsigned char *)videoFrame.vBuffer)[j] = uvRenderByte[i + 1];
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CFRelease(pixelBuffer);

       //todo --- tillusory end3 ---
        
        return true;
    }
    
    virtual bool onRenderVideoFrame(unsigned int uid, VideoFrame& videoFrame) override
    {
        return true;
    }
};

@interface AGVideoPreProcessing()

@end

static AgoraVideoFrameObserver s_videoFrameObserver;
static UIViewController *viewController;

@implementation AGVideoPreProcessing
{

}

+ (int) registerVideoPreprocessing: (AgoraRtcEngineKit*) kit
{
    if (!kit) {
        return -1;
    }
    isRelease = @0;
    NSLog(@"%@ ==-=-=-=--=--=",isRelease);
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
//    mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine)
    {
        //mediaEngine->registerAudioFrameObserver(&s_audioFrameObserver);
        mediaEngine->registerVideoFrameObserver(&s_videoFrameObserver);
        
        empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
        attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
    }
//    isRelease = NO;
    return 0;
}


+ (int) deregisterVideoPreprocessing: (AgoraRtcEngineKit*) kit
{
    if (!kit) {
        return -1;
    }
    isRelease = @1;
    NSLog(@"%@ +++++++++++++",isRelease);
    //    NSInteger count2 = CFGetRetainCount(empty);
    //    for (NSInteger i = 0; i < count2 -1; i++) {
    //        CFRelease(empty);
    //    }
    
    //    NSLog(@"（CF）attrs:%ld,empty:%ld",count1);
    agora::rtc::IRtcEngine* rtc_engine = (agora::rtc::IRtcEngine*)kit.getNativeHandle;
    agora::util::AutoPtr<agora::media::IMediaEngine> mediaEngine;
//    mediaEngine.queryInterface(rtc_engine, agora::rtc::AGORA_IID_MEDIA_ENGINE);
    mediaEngine.queryInterface(rtc_engine, agora::AGORA_IID_MEDIA_ENGINE);
    if (mediaEngine)
    {
        //mediaEngine->registerAudioFrameObserver(NULL);
        mediaEngine->registerVideoFrameObserver(NULL);
    }
    
    CFRelease(empty);
    
    NSInteger count1 = CFGetRetainCount(attrs);
    for (NSInteger i = 0; i < count1; i++) {
        CFRelease(attrs);
    }
    
    return 0;
    
}

@end
