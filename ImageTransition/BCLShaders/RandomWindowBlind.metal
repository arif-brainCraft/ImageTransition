//
//  RandomWindowBlind.metal
//  ImageTransition
//
//  Created by BCL Device7 on 24/5/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;


constant float2 size = float2(4);
constant float pause = 0.1;
constant float dividerWidth = 0.05;
constant float4 bgcolor = float4(0.0, 0.0, 0.0, 1.0);
constant float randomness = 0.1;


 float2 offset_rwb(float progress, float x, float theta) {
   //float phase = progress*progress + progress + theta;
   float shifty = 0.03*progress*cos(10.0*(progress+x));
   return float2(0, shifty);
 }
 float delta_rwb(float2 p) {
   float2 rectanglePos = floor(float2(size) * p);
   float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
   float top = rectangleSize.y * (rectanglePos.y + 1.0);
   float bottom = rectangleSize.y * rectanglePos.y;
   float left = rectangleSize.x * rectanglePos.x;
   float right = rectangleSize.x * (rectanglePos.x + 1.0);
   float minX = min(abs(p.x - left), abs(p.x - right));
   float minY = min(abs(p.y - top), abs(p.y - bottom));
   return min(minX, minY);
 }

 float dividerSize_rwb() {
   float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
   return min(rectangleSize.x, rectangleSize.y) * dividerWidth;
 }

 fragment float4 randomWindowBlindFragment(VertexOut vertexIn [[ stage_in ]],
                   texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                   texture2d<float, access::sample> toTexture [[ texture(1) ]],
                   constant float & startingAngle [[ buffer(0) ]],
                   constant float & ratio [[ buffer(1) ]],
                   constant float & progress [[ buffer(2) ]],
                   sampler textureSampler [[ sampler(0) ]]) {
     
     float2 p = vertexIn.textureCoordinate;
     p.y = 1.0 - p.y;
     float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
     float _toR = float(toTexture.get_width())/float(toTexture.get_height());
     
     
   if(progress < pause) {
     float currentProg = progress / pause;
     float a = 1.0;
     if(delta_rwb(p) < dividerSize_rwb()) {
       a = 1.0 - currentProg;
     }
     return mix(bgcolor, getFromColor(p,fromTexture,ratio,_fromR), a);
   }
   else if(progress < 1.0 - pause){
       
       if(delta_rwb(p) < dividerSize_rwb()) {
           return bgcolor;
       } else {
           
           float currentProg = (progress - pause) / (1.0 - pause * 2.0);
           float2 q = p;
           float2 rectanglePos = floor(float2(size) * q);
           
           float r = rand(rectanglePos) - randomness;
           float cp = smoothstep(0.0, 1.0 - r, currentProg);
           
           
           float4 a = getFromColor(p + offset_rwb(cp, p.x - cp, 0.0),fromTexture,ratio,_fromR);
           float4 b = getToColor(p + offset_rwb(1.0-cp, p.x - cp , 3.14),toTexture,ratio,_toR);
           
           
           float t = cp;
           
           if (mod(floor(p.y*150.*cp),2.)==0.){
               t*=2.-.5;
           }
           
           float4 c = mix(
                        a,
                          getToColor(p,toTexture,ratio,_toR),
                        mix(t, cp, smoothstep(0.8, 1.0, progress))
                        );
           
           return mix(c,getToColor(p,toTexture,ratio,_toR), cp);
           
       }
       

     }
   else {
     float currentProg = (progress - 1.0 + pause) / pause;
     float a = 1.0;
     if(delta_rwb(p) < dividerSize_rwb()) {
       a = currentProg;
     }
     return mix(bgcolor, getToColor(p,toTexture,ratio,_toR), a);
   }
 }
