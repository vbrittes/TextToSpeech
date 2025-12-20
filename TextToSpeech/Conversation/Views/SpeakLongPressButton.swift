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
        ZStack {
            Circle()
                .fill(isDown ? Color.blue : .cyan)
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
        .highPriorityGesture(
            DragGesture()
                .onChanged { _ in
                    withAnimation {
                        isDown = true
                    }
                }
                .onEnded { _ in
                    withAnimation {
                        isDown = false
                    }
                }
        )
        .accessibilityAddTraits(.isButton)
        .onChange(of: isDown) { _, newValue in
            Task { @MainActor in
                onHoldChange(newValue)
            }
        }
    }
}

