//
//  ViewController.m
//  YUGPUImageCVPixelBufferInputDemo
//
//  Created by YuAo on 3/28/16.
//  Copyright © 2016 YuAo. All rights reserved.
//

#import "ViewController.h"
#import <YUGPUImageCVPixelBufferInput/YUGPUImageCVPixelBufferInput.h>

@import AVFoundation;

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic,strong) AVCaptureSession *captureSession;

@property (nonatomic,strong) dispatch_queue_t videoSampleBufferProcessingQueue;

@property (nonatomic,weak) GPUImageView *imageView;

@property (nonatomic,strong) YUGPUImageCVPixelBufferInput *pixelBufferInput;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoSampleBufferProcessingQueue = dispatch_queue_create("com.immomo.video-processing-demo.video-processing", DISPATCH_QUEUE_SERIAL);
    self.captureSession = [ViewController newVideoCaptureSessionWithSampleBufferDelegate:self processingQueue:self.videoSampleBufferProcessingQueue];
    
    GPUImageView *imageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [imageView setBackgroundColorRed:0 green:0 blue:0 alpha:1.0];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    GPUImageSepiaFilter *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    [sepiaFilter addTarget:self.imageView];
    
    self.pixelBufferInput = [[YUGPUImageCVPixelBufferInput alloc] init];
    [self.pixelBufferInput addTarget:sepiaFilter];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.captureSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(pixelBuffer);
    CFRetain(sampleBuffer);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.pixelBufferInput processCVPixelBuffer:pixelBuffer frameTime:currentTime];
        CFRelease(pixelBuffer);
        CFRelease(sampleBuffer);
    });
}


+ (AVCaptureSession *)newVideoCaptureSessionWithSampleBufferDelegate:(id<AVCaptureVideoDataOutputSampleBufferDelegate>)sampleBufferDelegate processingQueue:(dispatch_queue_t)processingQueue {
    
    AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
    
    captureSession.sessionPreset = ({
        NSArray *preferredSessionPresets = @[AVCaptureSessionPreset1280x720,AVCaptureSessionPreset640x480];
        
        NSString *supportedPreset = nil;
        for (NSString *preset in preferredSessionPresets) {
            BOOL allDevicesSupportPreset = YES;
            for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
                if (![device supportsAVCaptureSessionPreset:preset]) {
                    allDevicesSupportPreset = NO;
                }
            }
            if (allDevicesSupportPreset) {
                supportedPreset = preset;
                break;
            }
        }
        
        supportedPreset;
    });
    
    //get the front video capture device
    AVCaptureDevice *videoDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K == %@",NSStringFromSelector(@selector(position)),@(AVCaptureDevicePositionFront)]].firstObject;
    NSAssert(videoDevice, @"No suitable video device found.");
    
    NSError *videoInputCreationError;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&videoInputCreationError];
    NSAssert(!videoInputCreationError, @"Error creating video deivce input: %@",videoInputCreationError);
    
    [captureSession beginConfiguration];
    
    if ([captureSession canAddInput:videoInput]) {
        [captureSession addInput:videoInput];
    }
    
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoDataOutput setSampleBufferDelegate:sampleBufferDelegate queue:processingQueue];
    
    //set the output video format
    videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    
    if ([captureSession canAddOutput:videoDataOutput]) {
        [captureSession addOutput:videoDataOutput];
    }
    
    [captureSession commitConfiguration];
    
    AVCaptureConnection *videoConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    videoConnection.videoMirrored = YES;
    
    return captureSession;
}

@end
