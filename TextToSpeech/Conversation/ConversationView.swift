//
//  ConversationView.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import SwiftUI

struct ConversationView: View, HapticFeedback {
    
    @Environment(\.scenePhase) private var scenePhase
    
    let bottomAnchorID = "bottom"
    
    @StateObject var viewModel = ConversationViewModel()
    @State var isHolding = false
    
    var body: some View {
        VStack {
            messagesScroll
            
            Text(viewModel.transcript)
                .frame(maxWidth: .infinity, alignment: .leading)
                .containerRelativeFrame(.vertical) { length, _ in
                    length * 0.15
                }
                .padding(20)
                .transition(.slideDownFadeOnRemove(inXOffset: -10))
                .standardAnimation(value: viewModel.transcript)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                        .glassEffect(in: .rect(cornerRadius: 12))
                }
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: 150, height: 150)
                    .scaleEffect(viewModel.noiseLevel)
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.5), value: viewModel.noiseLevel)
                    .opacity(viewModel.noiseLevel > 1 ? 1 : 0)
                    .padding(16)
                Image(systemName: "circle.dotted")
                    .font(.system(size: 150, weight: .bold))
                    .accessibilityHidden(true)
                    .frame(width: 180, height: 180)
                    .foregroundStyle(Color.blue)
                    .symbolEffect(.rotate, options: .repeat(.continuous), isActive: viewModel.loading)
                    .symbolEffect(.breathe, options: .repeat(.continuous), isActive: viewModel.loading)
                    .scaleEffect(viewModel.loading ? 1.1 : 0.1)
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.5), value: viewModel.state)
                SpeakLongPressButton(size: 150, title: "Hold & Speak", isDown: $isHolding)
                    .disabled(viewModel.loading)
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.5), value: viewModel.state)
                    .accessibilityLabel("Hold to speak")
            }
            .padding(40)
        }
        .padding(.top, 40)
        .onChange(of: scenePhase) { _, phase in
            Task { @MainActor in
                viewModel.state = .idle
                isHolding = false
            }
        }
        .onChange(of: isHolding) { _, newValue in
            Task { @MainActor in
                if newValue {
                    hapticTap(style: .medium)
                    await viewModel.pressedSpeak()
                } else {
                    hapticTap(type: .success)
                    await viewModel.releaseSpeak()
            
                }
            }
        }
        .task {
            _ = await viewModel.requestMicPermissionAccess()
        }
    }
    
    var messagesScroll: some View {
        GeometryReader { geometry in
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 15) {
                        if let greeting = viewModel.greeting {
                            Text(greeting)
                                .font(.largeTitle)
                                .multilineTextAlignment(.center)
                                .containerRelativeFrame(.vertical)
                                .transition(.slideDownFadeOnRemove(outYOffset: 10))
                        }
                        ForEach(viewModel.messages) { m in

                            HStack(spacing: 8) {
                                if m.role == .user {
                                    Spacer()
                                }
                                
                                Text(m.content)
                                    .multilineTextAlignment(m.role == .user ? .trailing : .leading)
                                    .padding(10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(m.role != .user ? Color.gray.opacity(0.5)  : Color.cyan.opacity(0.9))
                                            .glassEffect(in: .rect(cornerRadius: 12))
                                    }
                                    .font(.body)
                                
                                if m.role != .user {
                                    let canPlay = viewModel.playbackID != m.id
                                    Button {
                                        viewModel.readAloud(message: m)
                                    } label: {
                                        Image(systemName: "play.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20, weight: .semibold))
                                            .padding(10)
                                            .background(Circle().fill(Color.gray.opacity(0.5)))
                                            .padding(10)
                                    }.disabled(!canPlay)
                                        .opacity(canPlay ? 1 : 0.4)
                                    Spacer()
                                } else if viewModel.retryList.contains(m) {
                                    Button {
                                        Task { @MainActor in
                                            await viewModel.retry(message: m)
                                        }
                                    } label: {
                                        Text("Retry")
                                            .foregroundStyle(.red)
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                }
                            }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .multilineTextAlignment(.center)
                                .font(.body)
                        }
                        
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 1)
                            .id(bottomAnchorID)
                        
                    }
                    .standardAnimation(value: viewModel.messages)
                    .onAppear {
                        if !viewModel.messages.isEmpty {
                            Task { @MainActor in
                                proxy.scrollTo(bottomAnchorID, anchor: .top)
                            }
                        }
                    }
                    .onChange(of: viewModel.messages) {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                            withAnimation {
                                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.errorMessage) { oldValue, newValue in
                        Task { @MainActor in
                            if newValue != oldValue && viewModel.errorMessage == nil {
                                hapticTap(type: .error)
                            }
                        }
                    }
                }
            }
            .transition(.slideDownFadeOnRemove(inYOffset: -20))
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.clear)
    }
    
}

extension View {
    func standardAnimation<V>(value: V) -> some View where V : Equatable {
        self.animation(.spring(response: 0.25, dampingFraction: 0.35), value: value)
    }
}

#Preview {
    ConversationView()
}
