//
//  ConversationView.swift
//  TextToSpeech
//
//  Created by Victor Brittes on 13/12/25.
//

import SwiftUI

struct ConversationView: View {
    
    let bottomAnchorID = "bottom"
    
    @StateObject var viewModel = ConversationViewModel()
    
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
                    .animation(.bouncy(duration: 0.5, extraBounce: 0.5), value: 0.5)
                    .padding(30)
                SpeakLongPressButton(size: 150, title: "Speak") { value in
                    Task { @MainActor in
                        await (value ? viewModel.pressedSpeak() : viewModel.releaseSpeak())
                    }
                }
            }
            .padding(40)
        }
        .padding(.top, 40)
        .task {
            await viewModel.requestMicPermissionAccess()
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
                                            .fill(m.role != .user ? Color.gray.opacity(0.5) : Color.cyan.opacity(0.9))
                                                    .glassEffect(in: .rect(cornerRadius: 12))
                                    }
                                    .font(.body)
                                
                                if m.role != .user {
                                    Spacer()
                                }
                            }
                            
                            if m == viewModel.messages.last {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .frame(height: 1)
                                    .id(bottomAnchorID)
                            }
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .multilineTextAlignment(.center)
                                .font(.body)
                        }
                        
                    }
                    .standardAnimation(value: viewModel.messages)
                    .onAppear {
                        if !viewModel.messages.isEmpty {
                            Task { @MainActor in
                                proxy.scrollTo(bottomAnchorID, anchor: .top)
                            }
                        }
                    }
                    .onChange(of: viewModel.messages) { a, b in
                        Task { @MainActor in
                            withAnimation {
                                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
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
