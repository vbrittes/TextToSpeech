//
//  SpeakLongPressButton.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 17/12/25.
//

import SwiftUI

/// A circular, press-and-hold button that reports press state changes.
///
/// Displays a circular button that animates when pressed and invokes the `onHoldChange`
/// callback with the current pressed state. Useful for push-to-talk or long-press
/// interactions where UI should react while the button is held down.
///
/// - Parameters:
///   - size: The diameter of the circular button in points. Defaults to `84`.
///   - title: The text displayed at the center of the button. Defaults to an empty string.
///   - onHoldChange: A closure invoked with `true` when the button is pressed and `false`
///     when released. The closure is `@Sendable` so it can be used across concurrency domains.
struct SpeakLongPressButton: View {
    var size: CGFloat = 84
    var title: String = ""

    @Binding var isDown: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isDown ? .red : .blue)
                .frame(width: size, height: size)
                .scaleEffect(isDown ? 1.05 : 1.0)
            Text(title)
                .foregroundStyle(.white)
                .font(.headline.bold())
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    if drag.translation == .zero && !isDown{
                        isDown = true
                    }
                }
                .onEnded { _ in
                    if isDown {
                        isDown = false
                    }
                }
        )
    }
}

