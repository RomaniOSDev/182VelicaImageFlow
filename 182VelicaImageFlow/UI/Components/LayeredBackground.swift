import SwiftUI

/// Full-screen colorful backdrop (always behind screen content).
struct LayeredBackground: View {
    var body: some View {
        ZStack {
            Color("AppBackground")

            LinearGradient(
                colors: [
                    Color("AppPrimary").opacity(0.72),
                    Color("AppBackground"),
                    Color("AppAccent").opacity(0.58),
                    Color("AppPrimary").opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color("AppPrimary").opacity(0.42))
                .frame(width: 340, height: 340)
                .blur(radius: 60)
                .offset(x: -90, y: -200)
                .allowsHitTesting(false)

            Circle()
                .fill(Color("AppAccent").opacity(0.38))
                .frame(width: 320, height: 320)
                .blur(radius: 55)
                .offset(x: 130, y: 280)
                .allowsHitTesting(false)

            Circle()
                .fill(Color("AppPrimary").opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 45)
                .offset(x: 40, y: 80)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    LayeredBackground()
}
