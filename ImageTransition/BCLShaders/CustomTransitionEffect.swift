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
        case angular
        case burn
        case randomAngularDreamy
        case randomWindowBlind
        case randomDownSwipe
        case doomScreenTransition
        case whiteMinimalBgFilter
        case directionalSlide
        case gradualBox
        case gradualBoxBrushStroke
        case gradualBoxZoom
        case gradualDoubleBoxZoom
        case adoreTransition
        case flareOverlay
        public var transition: BCLTransition {
            switch self {
            case .waterDrop: return WaterDropTransition()
            case .dreamyWindowSlice: return DreamyWindowSlice()
            case .angular: return AngularTransition()
            case .burn: return BurnTransition()
            case . randomAngularDreamy: return RandomAngularDreamy()
            case .randomWindowBlind: return RandomWindowBlind()
            case .randomDownSwipe: return RandomDownSwipe()
            case .doomScreenTransition: return DoomScreenTransition()
            case .whiteMinimalBgFilter: return WhiteMinimalBgFilter()
            case .directionalSlide: return DirectionalSlide()
            case .gradualBox: return GradualBoxBrush()
            case .gradualBoxBrushStroke: return GradualBoxBrushStroke()
            case .gradualBoxZoom: return GradualBoxZoom()
            case .gradualDoubleBoxZoom: return GradualDoubleBoxZoom()
            case .adoreTransition: return AdoreTransition()
            case .flareOverlay: return FlareOverlay()
            }
        }
        
        public var description: String {
            switch self {
            case .waterDrop: return "WaterDrop"
            case .dreamyWindowSlice: return "DreamyWindowSlice"
            case .angular: return "Angular"
            case .burn: return "Burn"
            case .randomAngularDreamy: return "randomAngularDreamy"
            case .randomWindowBlind: return "RandomWindowBlind"
            case .randomDownSwipe: return "RandomDownSwipe"
            case .doomScreenTransition: return "DoomScreenTransition"
            case .whiteMinimalBgFilter: return "WhiteMinimalBgFilter"
            case .directionalSlide: return "DirectionalSlide"
            case .gradualBox: return "GradualBoxBrush"
            case .gradualBoxBrushStroke: return "gradualBoxBrushStroke"
            case .gradualBoxZoom: return "gradualBoxZoom"
            case .gradualDoubleBoxZoom: return "GradualDoubleBoxZoom"
            case .adoreTransition: return "AdoreTransition"
            case .flareOverlay: return "flare overlay"
            }
        }
    }
}
