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

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime;

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime completion:(void (^)(void))completion;

@end
