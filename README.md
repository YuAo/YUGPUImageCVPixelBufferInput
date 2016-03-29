# YUGPUImageCVPixelBufferInput

CVPixelBuffer input for [GPUImage](https://github.com/BradLarson/GPUImage), iOS

Feed `CVPixelBufferRef` to `GPUImage`'s filter chain.

Useful when you do not want to use `GPUImageVideoCamera`, or you'd like to process the camera output before it is passed to `GPUImage`'s filter chain.

Only `kCVPixelFormatType_32BGRA` is supported currently.
