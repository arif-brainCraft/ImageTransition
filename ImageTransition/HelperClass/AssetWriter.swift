//
//  AssetWriter.swift
//  ImageTransition
//
//  Created by BCL Device7 on 19/7/22.
//

import AVFoundation
import CoreMedia
import CoreImage
import MetalPetal

class AssetWriter{
    
    var writer:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    var pixelBufferAdaptor:AVAssetWriterInputPixelBufferAdaptor!
    var pixelBufferPool:CVPixelBufferPool!
    var outputSize:CGSize!
    
    init(output:CGSize) {
        self.outputSize = output
        setup()
    }
    
    func setup(){
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let path = documentDirectory.appendingPathComponent("slideshow.mp4").path
        let tempURL = URL(fileURLWithPath: path)
        
        //let tempURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("slideshow.mp4"))
        
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        writer = try? AVAssetWriter(outputURL: tempURL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outputSize.width,
            AVVideoHeightKey: outputSize.height
        ]
        writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let attributes = sourceBufferAttributes(outputSize: outputSize)
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput,
                                                                  sourcePixelBufferAttributes: attributes)
        writer?.add(writerInput)
        
        guard let success = writer?.startWriting(), success == true else {
            fatalError("Can not start writing")
        }
        
        self.pixelBufferPool = pixelBufferAdaptor?.pixelBufferPool
        
        guard self.pixelBufferPool != nil else {
            fatalError("AVAssetWriterInputPixelBufferAdaptor pixelBufferPool empty")
        }
        
    }
    
    func addBufferToPool(frame:CIImage,presentTime:CMTime) -> Void {
        guard let pool = self.pixelBufferPool,let adapter = pixelBufferAdaptor else {
            return
        }
        
        while !self.writerInput.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.01)
        }
        autoreleasepool {
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
            
            if let buffer = pixelBuffer{
                let mtiFrame = MTIImage(ciImage: frame)
                try? BCLTransition.context?.render(mtiFrame, to: buffer)
                adapter.append(buffer, withPresentationTime: presentTime)
                print(".", separator: " ", terminator: " ")
                
            }
        }
        
    }
    
    private func sourceBufferAttributes(outputSize: CGSize) -> [String: Any] {
        let attributes: [String: Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA,
            (kCVPixelBufferWidthKey as String): outputSize.width,
            (kCVPixelBufferHeightKey as String): outputSize.height
        ]
        return attributes
    }
    

    func startSession() -> Void {
        writer?.startSession(atSourceTime: .zero)
    }
    
    func finishWriting(completion:@escaping MTMovieMakerCompletion) -> Void {
        writerInput?.markAsFinished()
        
        writer?.finishWriting {
            DispatchQueue.main.async {
                if let error = self.writer?.error {
                    print("video written failed \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("video written succesfully")
                    completion(.success(self.writer.outputURL))
                }
            }
        }
    }
    
}
