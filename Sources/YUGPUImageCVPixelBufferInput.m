//
//  YUGPUImageCVPixelBufferInput.m
//  Pods
//
//  Created by YuAo on 3/28/16.
//
//

#import "YUGPUImageCVPixelBufferInput.h"

@interface YUGPUImageCVPixelBufferInput ()

@property (nonatomic) CVOpenGLESTextureRef textureRef;

@end

@implementation YUGPUImageCVPixelBufferInput

- (void)dealloc {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
    });
}

- (void)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    [self processCVPixelBuffer:pixelBuffer frameTime:kCMTimeIndefinite];
}

- (void)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime {
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
        
        CVOpenGLESTextureRef textureRef = NULL;
        CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                    [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache],
                                                                    pixelBuffer,
                                                                    NULL,
                                                                    GL_TEXTURE_2D,
                                                                    GL_RGBA,
                                                                    bufferWidth,
                                                                    bufferHeight,
                                                                    GL_BGRA,
                                                                    GL_UNSIGNED_BYTE,
                                                                    0,
                                                                    &textureRef);
        if (textureRef) {
            self.textureRef = textureRef;
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(CVOpenGLESTextureGetTarget(textureRef), CVOpenGLESTextureGetName(textureRef));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            outputFramebuffer = [[GPUImageFramebuffer alloc] initWithSize:CGSizeMake(bufferWidth, bufferHeight) overriddenTexture:CVOpenGLESTextureGetName(textureRef)];
        }
    });
    
    runSynchronouslyOnVideoProcessingQueue(^{
        for (id<GPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:targetTextureIndex];
        }
    });
}

@end
