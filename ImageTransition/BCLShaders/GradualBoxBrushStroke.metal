//
//  GradualBoxBrushStroke.metal
//  ImageTransition
//
//  Created by BCL Device7 on 13/7/22.
//

#include <metal_stdlib>
#include "BCLTransitionLib.h"

using namespace metalpetal;


constant float mt=.5;
constant float radius=.3;
constant float boxWidth=.02;
constant int start=0;
constant float base=0.;
constant float PI_Value = 3.1416;
constant float rotation=.05;

//constant float u_time;
//constant float2 u_resolution;

//constant sampler2D u_tex0;
//constant sampler2D u_tex1;


float2 gbbs_rotZ(float2 p,float a){
    float c=cos(a);
    float s=sin(a);
    return matrix_float2x2(c,-s,s,c)*p;
    
}

bool gbbs_isOnBoxBorder(float2 uv,float p,float radius,float width,float rotation){
    
    uv-=.5;
    uv=gbbs_rotZ(uv,rotation);
    uv+=.5;
    float angle=clamp(float(start),0.,3.);
    float a=0.-angle,b=1.-angle,c=2.-angle,d=3.-angle;
    
    a=a<0.?4.+a:a;
    b=b<0.?4.+b:b;
    c=c<0.?4.+c:c;
    d=d<0.?4.+d:d;
    
    float r=(.5-radius);
    float progress=(p)*4.;
    
    if(uv.x>=(r)&&uv.x<=((1.-r)*smoothstep(a,a+1.,progress))
       &&uv.y>=r&&uv.y-base<=(r+width)){
        return true;
    }else if(uv.y-base>=(r)&&uv.y<=((1.-r)*smoothstep(b,b+1.,progress))
             &&uv.x>=(1.-r-width)&&uv.x<=(1.-r)){
        return true;
    }else if(uv.x>=(1.+r-smoothstep(c,c+1.,progress))&&uv.x<=(1.-r)&&uv.y>=(1.-r-width)&&uv.y<=(1.-r)){
        return true;
    }else if(uv.y<=(1.-r)&&uv.y>=(1.+r-smoothstep(d,d+1.,progress))
             &&uv.x>=(r)&&uv.x<=(r+width)){
        return true;
    }
    
    return false;
}

bool gbbs_isInBox(float2 p,float progress,float radius,float width,float rotation){
    
    p-=.5;
    p=gbbs_rotZ(p,rotation);
    p+=.5;
    float r=(.5-radius+width);
    float X=r*rand(p);//length(p * float2(0.3));
    //X += exp(-60.0 *p.y);
    if(p.x>=X&&p.x<=(1.-X)*progress&&p.y>=r&&p.y<(1.-r))
    {
        return true;
    }
    
    return false;
    
}

bool gbbs_isInBrushStroke(float2 p,float progress,float4 texture){
    if(p.x<=progress){
        
        if(all(texture.gb > float4(.898,.8667,.8667,1.).gb)){
            return true;
        }
        
        //    if(all(greaterThan(texture.gb,float4(.898,.8667,.8667,1.).gb))){
        //      return true;
        //    }
    }
    
    return false;
}

bool gbbs_isWithinRange(float2 uv,float innerR,float outerR,float width,float rot){
    
    uv-=.5;
    uv=gbbs_rotZ(uv,rot);
    uv+=.5;
    
    float r1=(.5-innerR+width);
    float r2=(.5-outerR+width);
    
    bool X=(uv.x>=r1&&uv.x<=1.-r1)&&(uv.y>=r1&&uv.y<=1.-r1);
    bool Y=(uv.x>=r2&&uv.x<=(1.-r2))&&(uv.y>=r2&&uv.y<=(1.-r2));
    
    if(!X&&Y){
        return true;
    }
    
    return false;
}

float2 gbbs_zoom(float2 uv,float amount){
    return .5+((uv-.5)*(1.-amount));
}

fragment float4 gradualBoxBrushStroke(VertexOut vertexIn [[ stage_in ]],
                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                  texture2d<float, access::sample> brushTexture [[ texture(1) ]],
                  constant float2 & direction [[ buffer(0) ]],
                  
                  constant float & ratio [[ buffer(1) ]],
                  constant float & progress [[ buffer(2) ]],
                  sampler textureSampler [[ sampler(0) ]]){
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(brushTexture.get_width())/float(brushTexture.get_height());
    
    float r=radius;
    float4 brushColor = getToColor(uv, brushTexture, ratio, _toR);
    
    
    
    if(gbbs_isOnBoxBorder(uv,smoothstep(0.05,.4,progress),r,boxWidth,rotation)){
        float positive = step(0.5,uv.x);
        if(positive == 0. && gbbs_isInBrushStroke(uv,1.,brushColor)){
            return getFromColor(uv, fromTexture, ratio, _fromR);
        }
        return float4(1.);
    }
    
    
    if(gbbs_isInBrushStroke(uv,smoothstep(0.,.1,progress),brushColor)){
        return getFromColor(uv, fromTexture, ratio, _fromR);
    }
    
    //return mix(getFromColor(uv),float4(1.),mt);
    return mix(getFromColor(uv,fromTexture,ratio,_fromR),float4(1.0),mt);
}

fragment float4 gradualBoxZoom(VertexOut vertexIn [[ stage_in ]],
                  texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                  texture2d<float, access::sample> brushTexture [[ texture(1) ]],
                  constant float2 & direction [[ buffer(0) ]],
                  
                  constant float & ratio [[ buffer(1) ]],
                  constant float & progress [[ buffer(2) ]],
                  sampler textureSampler [[ sampler(0) ]]){
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(brushTexture.get_width())/float(brushTexture.get_height());
    
  float r = radius - 0.1  ;

  if (progress >= 0.4){
    
    float r2 = r + smoothstep(0.6,0.7,progress)/30.0;
    float r3 = r + smoothstep(0.5,0.8,progress)/10.0;

    float rot = rotation -  smoothstep(0.5,0.8,progress) /(1. / rotation);
    //outer box
    if(gbbs_isOnBoxBorder(uv,1.0,r3,boxWidth,rot)){
      return float4(1.);
    }
    
    float innerBoxWidth = boxWidth - 0.01;
    
    
   // //inner box
   // if(isOnBoxBorder(uv,1.,r2,innerBoxWidth,0.05)){
   //   return float4(1.);
   // }
    
   // //inner box
   // if(isOnBoxBorder(uv,smoothstep(0.7,0.9,progress),r2,innerBoxWidth,0.05)){
   //   return float4(1.);
   // }
    //outer box image
    if(gbbs_isWithinRange(uv,0.,r3,boxWidth,rot)){
      
      float2 pos = uv - 0.5;
      pos = gbbs_rotZ(pos,rot);
      pos += 0.5;
      
      return getFromColor(gbbs_zoom(pos, 1.0 -( 1.0 / (r3 * 2.))),fromTexture,ratio,_fromR);
    }
   //inner box image
   if (gbbs_isInBox(uv,1.0,r,boxWidth,rotation)) {
     
      float2 pos = uv - 0.5;
      pos = gbbs_rotZ(pos,rotation);
      pos += 0.5;
     
     return getFromColor(gbbs_zoom(pos, 1.0 -( 1.0 / (r * 2.))),fromTexture,ratio,_fromR);
   }
    
  }else{
    
    if(gbbs_isOnBoxBorder(uv,smoothstep(0.0,0.2,progress),r,boxWidth,rotation)){
      return float4(1.);
    }
    
    if (gbbs_isInBox(uv,smoothstep(0.2,0.4,progress),r,boxWidth,rotation)) {
      float2 pos = uv - 0.5;
      pos = gbbs_rotZ(pos,rotation);
      pos += 0.5;
      return getFromColor(gbbs_zoom(pos, 1.0 -( 1.0 / (r * 2.))),fromTexture,ratio,_fromR);
    }
  }
  
  return mix(getFromColor(uv,fromTexture,ratio,_fromR),float4(1.0),mt);
}

fragment float4 gradualDoubleBoxZoom (VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> fromTexture [[ texture(0) ]],
                             texture2d<float, access::sample> brushTexture [[ texture(1) ]],
                             constant float2 & direction [[ buffer(0) ]],
                             
                             constant float & ratio [[ buffer(1) ]],
                             constant float & progress [[ buffer(2) ]],
                             sampler textureSampler [[ sampler(0) ]]) {
  
    
    float2 uv = vertexIn.textureCoordinate;
    uv.y = 1.0 - uv.y;
    float _fromR = float(fromTexture.get_width())/float(fromTexture.get_height());
    float _toR = float(brushTexture.get_width())/float(brushTexture.get_height());
  float r = radius - 0.1  ;

  
  
  
  if (progress >= 0.4){
    
    float r2 = r + smoothstep(0.5,0.8,progress)/30.0;
    float r3 = r + smoothstep(0.5,0.8,progress)/10.0;

    
    if(gbbs_isOnBoxBorder(uv,1.0,r2,boxWidth,0.0)){
      return float4(1.);
    }
    
    
    if(gbbs_isOnBoxBorder(uv,1.0,r3,boxWidth,0.0)){
      return float4(1.);
    }
    
    if(gbbs_isWithinRange(uv,r2,r3,boxWidth,0.0)){
      return getFromColor(gbbs_zoom(uv, 1.0 -( 1.0 / (r3 * 2.))),fromTexture,ratio,_fromR);
    }
    
    if (gbbs_isInBox(uv,1.0,r2,boxWidth,0.0)) {
      return getFromColor(gbbs_zoom(uv, 1.0 -( 1.0 / (r2 * 2.))),fromTexture,ratio,_fromR);
    }
    // if(isWithinRange(uv,0.0,r3)){
    //   return getFromColor(zoom(uv, 1.0 -( 1.0 / (r3 * 2.))));
    // }
    
    
    
     
    
    // if (isInBox(uv,1.0,r3)) {
    //   return getFromColor(zoom(uv, 1.0 -( 1.0 / (r3 * 2.))));
    // }
    
  }else{
    
    if(gbbs_isOnBoxBorder(uv,smoothstep(0.0,0.2,progress),r,boxWidth,0.0)){
      return float4(1.);
    }
    
    if (gbbs_isInBox(uv,smoothstep(0.2,0.4,progress),r,boxWidth,0.0)) {
      return getFromColor(gbbs_zoom(uv, 1.0 -( 1.0 / (r * 2.))),fromTexture,ratio,_fromR);
    }
  }
  
  
  
  return mix(getFromColor(uv,fromTexture,ratio,_fromR),float4(1.),mt);
}

//void main(){
//  float2 coord=gl_FragCoord.xy/u_resolution;
//  gl_FragColor=transition(coord);
//}
