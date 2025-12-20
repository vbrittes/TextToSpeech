//
//  SpeakLongPressButton.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 17/12/25.
//

import SwiftUI

struct SpeakLongPressButton: View {
    var size: CGFloat = 84
    var title: String = ""
    var onHoldChange: @Sendable (Bool) -> Void

    @State private var isDown = false
    
    var body: some View {
        Button {
            // no action for tap
        } label: {
            ZStack {
                Circle()
                    .fill(isDown ? .cyan : .blue)
                    .frame(width: size, height: size)
                    .scaleEffect(isDown ? 1.05 : 1.0)
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.5), value: 0.5)

                Text(title)
                    .foregroundStyle(.white)
                    .font(.headline.bold())
            }
            .padding(6)
            .contentShape(Circle())
            .accessibilityAddTraits(.isButton)
        }
        .buttonStyle(PressableButtonStyle { isDown in
            self.isDown = isDown
            onHoldChange(isDown)
        })
        
    }
}

struct PressableButtonStyle: ButtonStyle {
    var onPressChanged: (Bool) -> Void = { _ in }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                onPressChanged(pressed)
            }
    }
}
