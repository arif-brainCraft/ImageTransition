//
//  BCLTransition.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/5/22.
//

import Foundation

import MetalPetal
import MTTransitions

/// The callback when transition updated
public typealias MTTransitionUpdater = (_ image: MTIImage) -> Void

/// The callback when transition completed
public typealias MTTransitionCompletion = (_ finished: Bool) -> Void
public typealias MTMovieMakerCompletion = (Result<URL?, Error>) -> Void

public class BCLTransition: NSObject, MTIUnaryFilter {
    
    public static let context = try? MTIContext(device: MTLCreateSystemDefaultDevice()!)
    
    public override init() { }

    public var inputImage: MTIImage?

    public var destImage: MTIImage?
    
    public var outputPixelFormat: MTLPixelFormat = .invalid
    
    public var progress: Float = 0.0
    
    /// The duration of the transition. 1.2 second by default.
    public var duration: TimeInterval = 1.2
    
    var completion: MTTransitionCompletion?
    
    private var updater: MTTransitionUpdater?
    private weak var driver: CADisplayLink?
    private var startTime: TimeInterval?
    
    // Subclasses must provide fragmentName
    var fragmentName: String { return "" }
    var vertexName: String { return "" }
    var vertexParameters: [simd_float4] = [simd_float4]()

    var parameters: [String: Any] = [String: Any]()
    var samplers: [String: String] { return [:] }
    
    public var outputImage: MTIImage? {
        guard let input = inputImage else {
            return inputImage
        }
        
        var images: [MTIImage] = [input]
        
        if let dest = destImage {
            images.append(dest)
        }
        
        let outputDescriptors = [ MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(cgSize: input.size), pixelFormat: outputPixelFormat)]
        for key in samplers.keys {
            if let name = samplers[key], let samplerImage = samplerImage(name: name) {
                images.append(samplerImage)
            }
        }
        
        var params = parameters
        params["ratio"] = Float(input.size.width / input.size.height)
        params["progress"] = progress
        
        
        if vertexParameters.count > 0 {
            
            let geometry = MTIVertices(__vertices: [
                MTIVertex(position: vertexParameters[0], textureCoordinate: simd_float2.zero),
                MTIVertex(position: vertexParameters[1], textureCoordinate: simd_float2.zero),
                MTIVertex(position: vertexParameters[2], textureCoordinate: simd_float2.zero),
                MTIVertex(position: vertexParameters[3], textureCoordinate: simd_float2.zero),
                MTIVertex(position: vertexParameters[4], textureCoordinate: simd_float2.zero),

            ],count:1, primitiveType: .triangleStrip)
            
            let renderCommand = MTIRenderCommand(kernel: kernel, geometry: geometry, images: images, parameters: params)
            
            let output = MTIRenderCommand.images(byPerforming: [renderCommand], outputDescriptors: outputDescriptors).first
            return output
        }else{
            let output = kernel.apply(to: images, parameters: params, outputDescriptors: outputDescriptors).first
            return output
        }
    }
    
    var kernel: MTIRenderPipelineKernel {
        
        var vertexDescriptor:MTIFunctionDescriptor!
        
        if vertexName.isEmpty {
            vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        }else{
            vertexDescriptor = MTIFunctionDescriptor(name: vertexName, libraryURL: MTIDefaultLibraryURLForBundle(Bundle(for: BCLTransition.self)))
        }
        
        
        let fragmentDescriptor = MTIFunctionDescriptor(name: fragmentName, libraryURL: MTIDefaultLibraryURLForBundle(Bundle(for: BCLTransition.self)))
    
        if vertexParameters.count > 0 {
            
            let descriptor = MTLVertexDescriptor()
            
            descriptor.attributes[0].format = .float4
            descriptor.attributes[0].bufferIndex = 0
            descriptor.attributes[0].offset = 0
            
            descriptor.attributes[1].format = .float4
            descriptor.attributes[1].bufferIndex = 0
            descriptor.attributes[1].offset = MemoryLayout<Float>.stride * 4

            descriptor.attributes[2].format = .float4
            descriptor.attributes[2].bufferIndex = 0
            descriptor.attributes[2].offset = MemoryLayout<Float>.stride * 8
            
            descriptor.attributes[3].format = .float4
            descriptor.attributes[3].bufferIndex = 0
            descriptor.attributes[3].offset = MemoryLayout<Float>.stride * 12
            
            descriptor.attributes[4].format = .float4
            descriptor.attributes[4].bufferIndex = 0
            descriptor.attributes[4].offset = MemoryLayout<Float>.stride * 16
            
            descriptor.layouts[0].stride = MemoryLayout<Float>.stride * 20

            return MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor, fragmentFunctionDescriptor: fragmentDescriptor, vertexDescriptor: descriptor, colorAttachmentCount: 1, alphaTypeHandlingRule: MTIAlphaTypeHandlingRule.passthrough)
            
        }else{
            return  MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor, fragmentFunctionDescriptor: fragmentDescriptor)

        }
        
    }
    
    public func samplerImage(name: String) -> MTIImage? {
        let bundle = Bundle(for: BCLTransition.self)
        guard let bundleUrl = bundle.url(forResource: "Assets", withExtension: "bundle"),
            let resourceBundle = Bundle(url: bundleUrl) else {
            return nil
        }
        
        if let imageUrl = resourceBundle.url(forResource: name, withExtension: nil) {
            let ciImage = CIImage(contentsOf: imageUrl)
            return MTIImage(ciImage: ciImage!, isOpaque: true)
        }
        return nil
    }
    
    public func transition(from fromImage: MTIImage, to toImage: MTIImage, updater: @escaping MTTransitionUpdater, completion: MTTransitionCompletion?) {
        self.inputImage = fromImage
        self.destImage = toImage
        self.updater = updater
        self.completion = completion
        self.startTime = nil
        let driver = CADisplayLink(target: self, selector: #selector(render(sender:)))
        driver.add(to: .main, forMode: .common)
        self.driver = driver
    }
    
    @objc private func render(sender: CADisplayLink) {
        let startTime: CFTimeInterval
        if let time = self.startTime {
            startTime = time
        } else {
            startTime = sender.timestamp
            self.startTime = startTime
        }
        
        let progress = (sender.timestamp - startTime) / duration
        if progress > 1 {
            self.progress = 1.0
            if let image = outputImage {
                self.updater?(image)
            }
            self.driver?.invalidate()
            self.driver = nil
            self.updater = nil
            self.completion?(true)
            self.completion = nil
            return
        }
        
        self.progress = Float(progress)
        if let image = outputImage {
            self.updater?(image)
        }
    }
    
    public func cancel() {
        self.completion?(false)
    }
}
