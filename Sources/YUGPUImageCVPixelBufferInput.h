//
//  YUGPUImageCVPixelBufferInput.h
//  Pods
//
//  Created by YuAo on 3/28/16.
//
//

#import <Foundation/Foundation.h>
#import <GPUImage/GPUImage.h>

@interface YUGPUImageCVPixelBufferInput : GPUImageOutput

- (void)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer withFrameTime:(CMTime)frameTime;

@end
