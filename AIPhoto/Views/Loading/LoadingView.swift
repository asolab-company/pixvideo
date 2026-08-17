import SwiftUI

struct LoadingView: View {
    var body: some View {
        DesignCanvas { layout in
            ZStack {
                AITheme.ColorToken.background
                    .ignoresSafeArea()

                Image("app_ic_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230, height: 230)
                    .position(x: 197, y: layout.canvasHeight / 2)

                StatusBarReplica()
                    .position(x: 196.5, y: 27)

                HomeIndicatorReplica()
                    .position(x: 196.5, y: layout.homeIndicatorY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
    }
}

#Preview("Loading") {
    LoadingView()
}
