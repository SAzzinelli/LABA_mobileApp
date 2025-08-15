import SwiftUI

/// Splash / Loading iniziale: leggera, senza Canvas, adatta a Light/Dark
struct AppLoadingView: View {
    @State private var appear = false
    var body: some View {
        ZStack {
            // Sfondo di sistema, per coerenza con il resto dell'app
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Image("logoLABA")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundStyle(Color.labaAccent)
                }

            }
            .padding(.horizontal, 24)
            .scaleEffect(appear ? 1 : 0.85)
            .opacity(appear ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    appear = true
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Caricamento")
    }
}

#Preview {
    AppLoadingView()
}
