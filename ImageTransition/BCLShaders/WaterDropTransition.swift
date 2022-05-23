//
//  WaterDropTransition.swift
//  ImageTransition
//
//  Created by BCL Device7 on 22/5/22.
//

import Foundation
import MTTransitions
public class WaterDropTransition: BCLTransition {
    
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "waterDropFragment"
    }

    override var parameters: [String: Any] {
        return [
            "startingAngle": startingAngle
        ]
    }
}
