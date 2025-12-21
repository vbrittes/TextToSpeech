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

/// A lightweight button style that forwards press state changes.
///
/// Wraps a button's label and emits changes to `configuration.isPressed` via the
/// `onPressChanged` callback, enabling external state updates or side effects when the
/// button is pressed or released.
///
/// - Parameter onPressChanged: A closure invoked with the current pressed state (`true`
///   when pressed, `false` when released). Defaults to a no-op closure.
struct PressableButtonStyle: ButtonStyle {
    var onPressChanged: (Bool) -> Void = { _ in }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                onPressChanged(pressed)
            }
    }
}

