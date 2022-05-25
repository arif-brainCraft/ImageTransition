//
//  RandomAngularDreamy.metal
//  CustomShader
//
//  Created by BCL Device7 on 18/5/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;



constant float2 size = float2(4);
constant float pause = 0.1;
constant float dividerWidth = 0.05;
constant float4 bgcolor = float4(0.0, 0.0, 0.0, 1.0);
constant float randomness = 0.1;



 float2 offset_d(float progress, float x, float theta) {
   //float phase = progress*progress + progress + theta;
   float shifty = 0.03*progress*cos(10.0*(progress+x));
   return float2(0, shifty);
 }
 float getDelta(float2 p) {
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

 float getDividerSize() {
   float2 rectangleSize = float2(1.0 / float2(size).x, 1.0 / float2(size).y);
   return min(rectangleSize.x, rectangleSize.y) * dividerWidth;
 }

 fragment float4 randomAngularDreamyFragment(VertexOut vertexIn [[ stage_in ]],
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
     if(getDelta(p) < getDividerSize()) {
       a = 1.0 - currentProg;
     }
     return mix(bgcolor, getFromColor(p,fromTexture,ratio,_fromR), a);
   }
   else if(progress < 1.0 - pause){
     if(getDelta(p) < getDividerSize()) {
       return bgcolor;
     } else {
       float currentProg = (progress - pause) / (1.0 - pause * 2.0);
       float2 q = p;
       float2 rectanglePos = floor(float2(size) * q);
       
       float r = rand(rectanglePos) - randomness;
       float cp = smoothstep(0.0, 1.0 - r, currentProg);
     

       

       
       float4 a = getFromColor(p + offset_d(cp, p.x - cp, 0.0),fromTexture,ratio,_fromR);
       float4 b = getToColor(p + offset_d(1.0-cp, p.x - cp , 3.14),toTexture,ratio,_toR);
       
       float tempOffset = startingAngle * PI / 180.0;
       float angle = atan2( p.y - 0.5, p.x - 0.5) + tempOffset;
       float normalizedAngle = (angle + PI) / (2.0 * PI);
       
       normalizedAngle = normalizedAngle - floor(normalizedAngle);
       return mix(a,b , step(normalizedAngle, cp));

       // return mix(
       //   getFromColor(p),
       //   getToColor(p),
       //   step(normalizedAngle, cp)
       //   );
       
     }
   }
   else {
     float currentProg = (progress - 1.0 + pause) / pause;
     float a = 1.0;
     if(getDelta(p) < getDividerSize()) {
       a = currentProg;
     }
     return mix(bgcolor, getToColor(p,toTexture,ratio,_toR), a);
   }
 }
