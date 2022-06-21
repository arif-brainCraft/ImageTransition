//
//  WaterDropTransition.swift
//  ImageTransition
//
//  Created by BCL Device7 on 22/5/22.
//

import Foundation
import MTTransitions
public class WaterDropTransition: BCLTransition {
    public override init() {
        super.init()
        self.duration = 3.0;
        self.parameters = ["startingAngle": startingAngle]
    }
    public var startingAngle: Float = 90

    override var fragmentName: String {
        return "waterDropFragment"
    }

}
