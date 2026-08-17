import SwiftUI

struct PageDots: View {
    let activeIndex: Int
    let count: Int

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? AITheme.ColorToken.primaryMiddle : Color.white.opacity(0.36))
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 48, height: 8)
    }
}

#Preview {
    PageDots(activeIndex: 0, count: 3)
        .padding()
        .background(.black)
}
