import SwiftUI
import UIKit

// MARK: - Reusable Components

struct ConversationBubble: View {
    let text: String
    let isLeft: Bool

    var body: some View {
        HStack {
            if !isLeft { Spacer(minLength: 60) }

            Text(text)
                .padding()
                .background(isLeft ? Color(.systemGray5) : Color.blue)
                .foregroundColor(isLeft ? .primary : .white)
                .cornerRadius(16)

            if isLeft { Spacer(minLength: 60) }
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .font(.subheadline)
        }
        .foregroundColor(.red)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct SuccessBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
            Text(message)
                .font(.subheadline)
        }
        .foregroundColor(.green)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

struct ProcessingOverlay: View {
    let message: String
    let onCancel: (() -> Void)?

    init(message: String = "Processing...", onCancel: (() -> Void)? = nil) {
        self.message = message
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text(message)
                    .foregroundColor(.white)
                    .font(.headline)

                if let onCancel {
                    Button("Cancel", action: onCancel)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray))
            )
        }
    }
}
