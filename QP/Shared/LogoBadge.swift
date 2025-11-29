import SwiftUI

struct LogoBadge: View {
    var size: CGFloat = 96
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(QPTheme.textPrimary.opacity(0.8), lineWidth: size * 0.07)
            ForEach(0..<6) { index in
                LogoSegment(startAngle: Angle(degrees: Double(index) * 60 - 90), endAngle: Angle(degrees: Double(index + 1) * 60 - 90))
                    .fill(index % 2 == 0 ? QPTheme.textPrimary.opacity(0.2) : QPTheme.textPrimary.opacity(0.05))
                    .overlay(
                        LogoSegment(startAngle: Angle(degrees: Double(index) * 60 - 90), endAngle: Angle(degrees: Double(index + 1) * 60 - 90))
                            .stroke(index == 0 ? QPTheme.accent : QPTheme.textPrimary.opacity(0.15), lineWidth: size * 0.01)
                    )
            }
            Text("QP")
                .font(.system(size: size * 0.35, weight: .heavy, design: .rounded))
                .foregroundColor(QPTheme.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

struct LogoSegment: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct LogoBadgeBackground: View {
    var body: some View {
        LogoBadge(size: 300)
            .foregroundColor(QPTheme.textPrimary.opacity(0.02))
            .blur(radius: 1)
    }
}
