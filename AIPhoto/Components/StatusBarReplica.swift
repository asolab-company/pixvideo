import SwiftUI

struct StatusBarReplica: View {
    var body: some View {
        EmptyView()
    }
}

private struct CellularIcon: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 3, height: CGFloat(5 + index * 3))
            }
        }
        .frame(width: 20, height: 14)
    }
}

private struct BatteryIcon: View {
    var body: some View {
        HStack(spacing: 1.5) {
            RoundedRectangle(cornerRadius: 3)
                .stroke(.white.opacity(0.35), lineWidth: 1)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .padding(2)
                }
                .frame(width: 25, height: 12)
            RoundedRectangle(cornerRadius: 1)
                .fill(.white.opacity(0.5))
                .frame(width: 1.5, height: 5)
        }
    }
}

struct HomeIndicatorReplica: View {
    var body: some View {
        EmptyView()
    }
}

#Preview {
    StatusBarReplica()
        .background(.black)
}
