//
//  CustomTransitionEffect.swift
//  ImageTransition
//
//  Created by BCL Device7 on 22/5/22.
//

import Foundation
import MTTransitions

extension BCLTransition{
    /// A convenience way to apply transtions.
    /// If you want to configure parameters, you can use following code:
    ///
    /// let transition = MTTransition.Effect.bounce.transition
    /// transition.shadowHeight = 0.02
    public enum Effect: CaseIterable, CustomStringConvertible {
        /// none transition applied
        case waterDrop
        case dreamyWindowSlice
        
        public var transition: BCLTransition {
            switch self {
            case .waterDrop: return WaterDropTransition()
            case .dreamyWindowSlice: return DreamyWindowSlice()
            
            }
        }
        
        public var description: String {
            switch self {
            case .waterDrop: return "WaterDrop"
            case .dreamyWindowSlice: return "DreamyWindowSlice"
            }
        }
    }
}
