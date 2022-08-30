//
//  TransformFilterWithMirror.swift
//  ImageTransition
//
//  Created by BCL Device7 on 25/8/22.
//

import Foundation
import simd
import SceneKit
import Accelerate

class TransformFilterWithMirror:BCLTransition {

    private var orthographicM = matrix_identity_float4x4
    private var transform3D = matrix_identity_float4x4

    private var rotationM = matrix_identity_float4x4
    private var scaleM = matrix_identity_float4x4
    private var translateM = matrix_identity_float4x4
    private var angle:Float = 0;
    private var aspectRatio:Float = 0;
    private var width:Int = 0;
    private var height:Int = 0;

    private var lowLimit:Float = -15.0;
    private var highLimit:Float = 15.0;




    override init() {
        super.init()
        
        orthographicM = makeOrthographicMatrix(left: -1.0, right: 1.0, bottom: -1.0, top: 1.0, near: -1.0, far: 1.0)
        aspectRatio = 1080 / 1920;
        transform3D = matrix_identity_float4x4
    }
    
    func makeOrthographicMatrix(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> float4x4 {
      
        return float4x4(
            [ 2 / (right - left), 0, 0, 0],
            [0, 2 / (top - bottom), 0, 0],
            [0, 0, 1 / (far - near), 0],
            [(left + right) / (left - right), (top + bottom) / (bottom - top), near / (near - far), 1]
        )
      
    }
    
    func setParams() -> Void {
        self.parameters = ["transformMatrix":transform3D,
                           "low":lowLimit,
                           "high":highLimit
        ]
    }
    
    func setVertexParams() -> Void {
        self.parameters = ["rot":rotationM,
                           //"aPosition":position,
                           "orthographicM":orthographicM
        ]
    }
    
    func resetTransformation() -> Void {
        transform3D = matrix_identity_float4x4
    }

    public func setFrameSize(width:Int, height:Int) {

        aspectRatio = Float(width) / Float(height)
        //Matrix.orthoM(orthographicM,0,-1.0f,1.0f, -1.0f , 1.0f * (float) height/ (float) width,-1f,1f);
    }
    

    private var horizontalMirror = true;
    private var verticalMirror = true;

    public func setHorizontalMirror(horizontalMirror:Bool) {
        self.horizontalMirror = horizontalMirror;
    }

    public func setVerticalMirror(verticalMirror:Bool) {
        self.verticalMirror = verticalMirror;
    }

    public func setLowLimit(_ lowLimit:Float) {
        self.lowLimit = lowLimit;
    }

    public func setHighLimit(_ highLimit:Float) {
        self.highLimit = highLimit;
    }
    
    public func resetSettings(){
        setHorizontalMirror(horizontalMirror: true);
        setVerticalMirror(verticalMirror: true);
        setLowLimit(-3.0);
        setHighLimit(3.0);
    }


    public func setTransformMatrix(transformMatrix4x4:simd_float4x4) {
        self.transform3D = transformMatrix4x4;
    }

    public func setTranslateOffset(offsetX :Float,offsetY:Float) {

        translateM = matrix_identity_float4x4
        translateM.columns.1.w = -offsetX
        translateM.columns.2.x = -offsetY;
        
        transform3D = transform3D * translateM

    }

    public func setRotateInAngle(angleInDegree:Float) {

        rotationM = matrix_identity_float4x4

        let radAngle = angleInDegree * .pi / 180.0;

        rotationM.columns.0.x = Float(cos(radAngle));
        rotationM.columns.0.y = Float(sin(radAngle));
        rotationM.columns.1.x = Float( sin(radAngle) * -1.0);
        rotationM.columns.1.y = Float( cos(radAngle));

        var scaleMat = matrix_identity_float4x4
        
        scaleMat.columns.0.x = aspectRatio;

        var scaleMatInv = matrix_identity_float4x4
        
        scaleMatInv.columns.0.x = 1.0 / aspectRatio;

        rotationM = scaleMatInv * rotationM
        rotationM = rotationM * scaleMat
        transform3D = transform3D * rotationM

    }


    public func setScaleUnit(scaleX:Float, scaleY:Float) {
        scaleM = matrix_identity_float4x4;
        scaleM.columns.0.x = scaleX;
        scaleM.columns.1.y = scaleY;
        transform3D = transform3D * scaleM
    }
    
}
