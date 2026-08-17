import SwiftUI

struct PrimaryGradientButton: View {
    let title: String
    var showsBorder = true
    var isEnabled = true
    var action: () -> Void = {}

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            Text(title)
                .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.45))
                .frame(maxWidth: .infinity, minHeight: AITheme.Layout.buttonHeight)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .background(AITheme.primaryGradient.opacity(isEnabled ? 1 : 0.32), in: Capsule())
        .overlay {
            if showsBorder {
                Capsule()
                    .stroke(AITheme.primaryGradient.opacity(isEnabled ? 1 : 0.32), lineWidth: 2)
            }
        }
        .disabled(!isEnabled)
        .frame(height: AITheme.Layout.buttonHeight)
    }
}

#Preview {
    PrimaryGradientButton(title: "Continue")
        .padding()
        .background(.black)
}
