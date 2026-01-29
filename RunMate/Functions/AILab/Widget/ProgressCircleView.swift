//
//  ProgressCircleView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/29.
//

import SwiftUI

struct ProgressCircleView: View {
    @Binding var progress: CGFloat
    let gradientColors = Gradient(colors: [.purple, .pink, .purple.opacity(0.5)])

    var body: some View {
        ZStack {
            Image("ai_loading").resizable().frame(width: 220, height: 220).clipShape(Circle())

            Circle().stroke(Color.purple.opacity(0.2), lineWidth: 20)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: gradientColors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.purple.opacity(0.3), radius: 5)

            VStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.white).animation(.linear, value: progress)
            }
        }
        .frame(width: 250, height: 250)
    }
}
