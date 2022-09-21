//
//  Templates.swift
//  ImageTransition
//
//  Created by BCL Device7 on 19/7/22.
//

import Foundation

class Template{
    var name:String!
    var isPremium:Bool!
    var type:SlideShowTemplate.Type!
    
    init(name:String,isPremium:Bool,type:SlideShowTemplate.Type) {
        self.name = name
        self.isPremium = isPremium
        self.type = type
    }
    
    func getInstance(allImageUrls: [URL]) -> SlideShowTemplate {
        
        if self.type == AdoreTemplate.self {
            return AdoreTemplate(allImageUrls: allImageUrls)
        }
        return AdoreTemplate(allImageUrls: allImageUrls)
    }
    
}

struct Templates {

    static var featured = [
        //Template(name: "Over The Box", isPremium: false, type: SquareBoxPopTemplate.self),
        Template(name: "AdoreTemplate", isPremium: false, type: AdoreTemplate.self),
        //Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
    ]
    
    static func twoD(array:[Template],by:Int) -> [[Template]] {
        
        return stride(from: 0, to: array.count, by: by).map({
            var end = $0 + 2
            if end >= array.count{
                end = array.count
            }
            return Array(array[$0..<end])
        })
    }
}

