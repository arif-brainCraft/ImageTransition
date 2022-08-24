//
//  FlareOverlay.swift
//  ImageTransition
//
//  Created by BCL Device7 on 24/8/22.
//

import Foundation
import MetalPetal
import simd

public class FlareOverlay: BCLTransition {
    
    private var oneColor = simd_float4(0.0,0.0,1.0,0.25){
        didSet{
            setParams()
        }
    }
    private var oneCenter = simd_float2(0.2,0.2){
        didSet{
            setParams()
        }
    }
    private var oneRadius:Float = 0.4{
        didSet{
            setParams()
        }
    }
    
    private var threeColor = simd_float4(0.0,1.0,0.0,0.25){
        didSet{
            setParams()
        }
    }
    private var threeCenter = simd_float2(0.6,0.2){
        didSet{
            setParams()
        }
    }
    private var threeRadius:Float = 0.6{
        didSet{
            setParams()
        }
    }
    
    private var twoColor = simd_float4(1.0,0.0,0.0,0.25){
        didSet{
            setParams()
        }
    }
    private var twoCenter = simd_float2(0.2,0.8){
        didSet{
            setParams()
        }
    }
    private var twoRadius:Float = 0.15{
        didSet{
            setParams()
        }
    }
    
    func setParams() -> Void {
        self.parameters = ["oneColor":oneColor,
                           "oneCenter":oneCenter,
                           "oneRadius":oneRadius,
                           "twoColor":twoColor,
                           "twoCenter":twoCenter,
                           "twoRadius":twoRadius,
                           "threeColor":threeColor,
                           "threeCenter":threeCenter,
                           "threeRadius":threeRadius,
        ]
    }
    
    public override init() {
        super.init()
        self.duration = 3.0;
        self.parameters = [:]
    }

    
    
    override var fragmentName: String {
        return "flareOverlay"
    }

    
    public func setOneColor( r:Float, g:Float, b:Float) {
        self.oneColor = simd_float4(r,g,b,0.25);
    }

    public func setProgress( progress:Float) {
        self.progress = progress;
        // FIXME: 2/8/22 for test
        let val = sin(2.0 * Float.pi * progress);
        
        threeCenter = simd_float2( 0.5 + val*0.1,0.4 + val*0.05);
    }

    public func setTest(){
        oneColor = simd_float4(0.05,0.05,0.05,0.05);
        twoColor = simd_float4(0.01,0.01,0.01,0.01);
        threeColor = simd_float4(0.25,0.25,0.25,0.025);
        threeCenter = simd_float2(0.5,0.4);
        threeRadius = 1.0;
    }

    public func setLCDPattern(){
        oneColor = simd_float4(0.1,0.1,0.1,0.10);
        twoColor = simd_float4(0.92,0.73,0.05,0.05);
        threeColor = simd_float4(0.5,0.5,0.5,0.25);

        oneCenter = simd_float2(getRandom(),getRandom());
        oneRadius = 0.1;

        twoCenter = simd_float2(getRandom(),getRandom());
        twoRadius = 0.2;

        threeCenter = simd_float2(getRandom()*2.0,getRandom()*2.0);
        threeRadius = 0.5;
    }
    
    func getRandom() -> Float {
        return Float.random(in: 0..<100)
    }
    
}
