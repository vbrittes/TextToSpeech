//
//  HapticFeedback.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 22/12/25.
//

import UIKit

protocol HapticFeedback { }

extension HapticFeedback {
    
    func hapticTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }
    
    func hapticTap(type: UINotificationFeedbackGenerator.FeedbackType) {
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }
    
}
