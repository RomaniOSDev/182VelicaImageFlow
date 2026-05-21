import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("AppBackground"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppGradients.primaryButton)
                    .shadow(
                        color: Color("AppPrimary").opacity(configuration.isPressed ? 0.15 : 0.35),
                        radius: configuration.isPressed ? 4 : 10,
                        y: configuration.isPressed ? 2 : 5
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color("AppTextPrimary").opacity(0.12), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { FeedbackManager.tapLight() }
            }
    }
}

struct SurfaceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppTextPrimary"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background {
                DepthCardBackground(cornerRadius: 12, level: .standard)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { pressed in
                if pressed { FeedbackManager.tapLight() }
            }
    }
}
