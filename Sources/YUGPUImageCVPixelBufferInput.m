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

@property (nonatomic, strong) dispatch_semaphore_t frameRenderingSemaphore;

@end

@implementation YUGPUImageCVPixelBufferInput

- (instancetype)init {
    if (self = [super init]) {
        self.frameRenderingSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
    });
}

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    return [self processCVPixelBuffer:pixelBuffer frameTime:kCMTimeIndefinite];
}

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime {
    return [self processCVPixelBuffer:pixelBuffer frameTime:frameTime completion:nil];
}

- (BOOL)processCVPixelBuffer:(CVPixelBufferRef)pixelBuffer frameTime:(CMTime)frameTime completion:(void (^)(void))completion {
    if (dispatch_semaphore_wait(self.frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
        return NO;
    }
    
    NSAssert(CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA, @"%@: only kCVPixelFormatType_32BGRA is supported currently.",self);
    
    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    CFRetain(pixelBuffer);
    
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        if (self.textureRef) {
            CFRelease(self.textureRef);
        }
        
        CVOpenGLESTextureRef textureRef = NULL;
        CVReturn result = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                       [[GPUImageContext sharedImageProcessingContext] coreVideoTextureCache],
                                                                       pixelBuffer,
                                                                       NULL,
                                                                       GL_TEXTURE_2D,
                                                                       GL_RGBA,
                                                                       (GLsizei)bufferWidth,
                                                                       (GLsizei)bufferHeight,
                                                                       GL_BGRA,
                                                                       GL_UNSIGNED_BYTE,
                                                                       0,
                                                                       &textureRef);
        
        NSAssert(result == kCVReturnSuccess, @"CVOpenGLESTextureCacheCreateTextureFromImage error: %@",@(result));

        if (result == kCVReturnSuccess && textureRef) {
            self.textureRef = textureRef;
            
            glActiveTexture(GL_TEXTURE4);
            glBindTexture(CVOpenGLESTextureGetTarget(textureRef), CVOpenGLESTextureGetName(textureRef));
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            
            outputFramebuffer = [[GPUImageFramebuffer alloc] initWithSize:CGSizeMake(bufferWidth, bufferHeight) overriddenTexture:CVOpenGLESTextureGetName(textureRef)];
            
            for (id<GPUImageInput> currentTarget in targets) {
                if ([currentTarget enabled]) {
                    NSInteger indexOfObject = [targets indexOfObject:currentTarget];
                    NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
                    if (currentTarget != self.targetToIgnoreForUpdates) {
                        [currentTarget setInputSize:CGSizeMake(bufferWidth, bufferHeight) atIndex:targetTextureIndex];
                        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
                        [currentTarget newFrameReadyAtTime:frameTime atIndex:targetTextureIndex];
                    } else {
                        [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
                    }
                }
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
        CFRelease(pixelBuffer);
        
        dispatch_semaphore_signal(self.frameRenderingSemaphore);
    });
    
    return YES;
}

@end
