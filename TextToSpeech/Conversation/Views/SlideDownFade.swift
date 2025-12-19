//
//  SlideDownFade.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 17/12/25.
//

import SwiftUI

private struct SlideDownFade: ViewModifier {
    let offset: CGPoint
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offset.x, y: offset.y)
            .opacity(opacity)
    }
}

extension AnyTransition {
    static func slideDownFadeOnRemove(inXOffset: CGFloat = 0,
                                      inYOffset: CGFloat = 0,
                                      outXOffset: CGFloat = 0,
                                      outYOffset: CGFloat = 0) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: SlideDownFade(offset: CGPoint(x: inXOffset, y: inYOffset), opacity: 0),
                identity: SlideDownFade(offset: .zero, opacity: 1)
            ),
            removal: .modifier(
                active: SlideDownFade(offset: CGPoint(x: outXOffset, y: outYOffset), opacity: 0),
                identity: SlideDownFade(offset: .zero, opacity: 1)
            )
        )
    }
}
