import SwiftUI

struct ChatBoxShape: Shape {
    func path(in rect: CGRect) -> Path {
<<<<<<< HEAD
        var pencil = Path()

        let w = rect.width
        let h = rect.height
        let cornerRadius = min(w, h) * 0.08

        pencil.move(to: CGPoint(x: w * -0.42, y: h * -0.1))
        pencil.addLine(to: CGPoint(x: w * -0.42, y: h * -0.82))
        pencil.addQuadCurve(
            to: CGPoint(x: w * -0.24, y: h * -1.07),
            control: CGPoint(x: w * -0.43, y: h * -1.07)
        )
        pencil.addLine(to: CGPoint(x: w * 1.33 - cornerRadius, y: h * -1.07))
        pencil.addQuadCurve(
            to: CGPoint(x: w * 1.42, y: h * -0.85),
            control: CGPoint(x: w * 1.35 + cornerRadius, y: h * -1.07)
        )
        pencil.addLine(to: CGPoint(x: w * 1.42, y: h * 0.15))
        pencil.addArc(
            center: CGPoint(x: w * 1.365, y: h * 1.74),
            radius: w * 0.06,
            startAngle: .degrees(0),
            endAngle: .degrees(95),
            clockwise: false
        )
        pencil.addArc(
            center: CGPoint(x: w * 1.251, y: h * 2),
            radius: w * 0.21,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )
        pencil.addQuadCurve(
            to: CGPoint(x: w * 0.84, y: h * 2.2 - cornerRadius),
            control: CGPoint(x: w * 1.01, y: h * 2.13)
        )
        pencil.addLine(to: CGPoint(x: w * -0.344 + cornerRadius, y: h * 2.12))
        pencil.addQuadCurve(
            to: CGPoint(x: w * -0.42, y: h * 1.95),
            control: CGPoint(x: w * -0.42, y: h * 2.12)
        )
        pencil.closeSubpath()

        return pencil
    }
    
}


#Preview {
    let bgGreen = Color(red: 16/255, green: 20/255, blue: 21/255)
    ChatBoxShape()
                  .fill(bgGreen)
                  .frame(maxWidth: UIScreen.main.bounds.width * 0.4456 ,minHeight: UIScreen.main.bounds.height * 0.2,
                   maxHeight: UIScreen.main.bounds.height * 0.05)
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.2, contentMode: .fit)
                    .padding(.horizontal)
}

//
//struct ChatBoxShape: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        
//        let cornerRadius: CGFloat = 35
//        let tailWidth: CGFloat = 30
//        let tailHeight: CGFloat = 20
//
//        // Start at the top-left corner
//        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
//        
//        // Top edge
//        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
//        
//        // Top-right corner
//        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius - 5, y: rect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
//        
//        // Right edge
//        path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.maxY - tailHeight - cornerRadius - 20))
//        
////        path.addArc(
////            center: CGPoint(x: rect.maxX - cornerRadius + 25, y: rect.maxY),
////                    radius: cornerRadius,
////                    startAngle: .degrees(90),
////                    endAngle: .degrees(100),
////                    clockwise: false
////        )
//        
//        // Bottom-edge hollow area
//        path.addQuadCurve(
//            to: CGPoint(x: rect.maxX * 0.83, y: rect.maxY - cornerRadius - 20),
//                    control: CGPoint(x: rect.maxX * 0.88, y: rect.maxY - 100)
//                )
//        
//        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius - 65, y: rect.maxY - tailHeight - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 16), endAngle: Angle(degrees: 90), clockwise: false)
//
//        
//        // Bottom edge after tail
//        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - tailHeight))
//        
//        // Bottom-left corner
//        path.addArc(center: CGPoint(x: rect.minX + cornerRadius + 5, y: rect.maxY - tailHeight - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
//
//        // Left edge
//        path.addLine(to: CGPoint(x: rect.minX + 5, y: rect.minY + cornerRadius))
//        
//        // Top-left corner
//        path.addArc(center: CGPoint(x: rect.minX + cornerRadius + 5, y: rect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
//        
//        path.closeSubpath()
//        
//        return path
//    }
//}
//
//
//#Preview {
//    ChatBoxShape()
//}
=======
        var path = Path()
        
        let cornerRadius: CGFloat = 35
        let tailWidth: CGFloat = 30
        let tailHeight: CGFloat = 20

        // Start at the top-left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        
        // Top-right corner
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailHeight - cornerRadius))
        
        // Bottom-right corner before tail
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - tailHeight - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        
        // Bottom edge until the tail starts
        let tailStartX = rect.midX + tailWidth / 2
        path.addLine(to: CGPoint(x: tailStartX, y: rect.maxY - tailHeight))
        
        // The "speaking" tail
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailStartX - tailWidth, y: rect.maxY - tailHeight))

        // Bottom edge after tail
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - tailHeight))
        
        // Bottom-left corner
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - tailHeight - cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        
        // Top-left corner
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius), radius: cornerRadius, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        
        path.closeSubpath()
        
        return path
    }
}
>>>>>>> 5424a6b (Recreated the reports page with more polished UI)
