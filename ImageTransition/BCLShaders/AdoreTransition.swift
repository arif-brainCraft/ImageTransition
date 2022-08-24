//
//  AdoreTransition.swift
//  ImageTransition
//
//  Created by BCL Device7 on 23/8/22.
//

import Foundation
import MetalPetal
import simd

public class AdoreTransition: BCLTransition {
    
    var rotation = simd_matrix(simd_float4(repeating: 0.0) , simd_float4(repeating:0.0), simd_float4(repeating:0.0), simd_float4(repeating:0.0)){
        didSet{
            setParams()
        }
    }

    private var videoRatio:Float = 1.0{
        didSet{
            setParams()
        }
    }
    private var prevTexture:Int = 0{
        didSet{
            setParams()
        }
    }
    
    
    public override init() {
        super.init()
        self.duration = 3.0
        setParams()
    }
    
    override var fragmentName: String {
        return "adoreTransition"
    }
     
    private func setParams() {
        self.parameters = ["vRatio":videoRatio,
                           "rot":rotation]
    }
    //simd_matrix(_ col0: simd_float4, _ col1: simd_float4, _ col2: simd_float4, _ col3: simd_float4)
  
    
    // 0-3 transparent love, 4-7 red love, 8 big love
    public func setRotation(value :Float,pos:(col:Int,row:Int)){
        guard pos.row >= 0 && pos.row < 4 && pos.col >= 0 && pos.col < 4 else {
            return
        }
        self.rotation[pos.col][pos.row] = value
    }
    
    public func changeRotation(value:Float){
        for i in 0..<2 {
            var column = simd_float4(repeating: 0)

            for j in 0..<4 {
                column[j] = value*((j%2 != 0) ? 1.0 : -1.0)
            }
            rotation[i] = column
        }
    }
    
    
    public func setVideoRatio( value:Float){
        self.videoRatio = value;
    }
    
    public func setPrevTexture( prevTexture:Int) {
        self.prevTexture = prevTexture;
    }
}
