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
    
    func initialize(allImageUrls: [URL], forExport: Bool) -> SlideShowTemplate {
        
        if self.type == SquareBoxPopTemplate.self {
            return SquareBoxPopTemplate(allImageUrls: allImageUrls, forExport: forExport)
        } else if self.type == GradualBoxTemplate.self {
            return GradualBoxTemplate(allImageUrls: allImageUrls, forExport: forExport)
        }
        return GradualBoxTemplate(allImageUrls: allImageUrls, forExport: forExport)
    }
    
}

struct Templates {

    static var featured = [
        Template(name: "Over The Box", isPremium: false, type: SquareBoxPopTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, type: GradualBoxTemplate.self),

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

