//
//  Templates.swift
//  ImageTransition
//
//  Created by BCL Device7 on 19/7/22.
//

import Foundation

struct Template{
    var name:String
    var isPremium:Bool
    var className:AnyClass
    
}

class Templates {

    static var featured = [
        Template(name: "Over The Box", isPremium: false, className: SquareBoxPopTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
        Template(name: "Box motion", isPremium: false, className: GradualBoxTemplate.self),
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

