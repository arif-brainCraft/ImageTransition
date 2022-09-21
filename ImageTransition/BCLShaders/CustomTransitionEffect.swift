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

        case adoreTransition
        case flareOverlay
        public var transition: BCLTransition {
            switch self {
            case .adoreTransition: return AdoreTransition()
            case .flareOverlay: return FlareOverlay()
            }
        }
        
        public var description: String {
            switch self {
            case .adoreTransition: return "AdoreTransition"
            case .flareOverlay: return "flare overlay"
            }
        }
    }
}
