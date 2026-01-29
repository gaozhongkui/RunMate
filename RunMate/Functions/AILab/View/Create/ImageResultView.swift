//
//  ImageResultView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/28.
//

import SwiftUI
import Zoomable

struct ImageResultView: View {
    var backAction: () -> Void
    var confirmAction: () -> Void

    var body: some View {
        ZStack {
            contentLayout()
            VStack {
                headerView()
                Spacer()
                bottomLayout()
            }
        }
    }

    private func headerView() -> some View {
        ZStack {
            Text("Art Ready")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            HStack {
                Button(action: {
                    backAction()
                }) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .padding(11)
                        .background(Color(hex: "#868095").opacity(0.2))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)

                Spacer()
            }.frame(height: 44)
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
        .background {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(edges: .top)
        }
    }

    private func contentLayout() -> some View {
        ZStack {
            Image("ai_loading")
                .scaledToFit()
                .zoomable()
        }
    }

    private func bottomLayout() -> some View {
        Button(action: {
            print("保留")
        }) {
            Text("Save")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color(hex: "9D50BB"), Color(hex: "6E50BB")], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(30)
                .shadow(color: Color(hex: "6E50BB").opacity(0.6), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
        }.padding(.horizontal, 16)
    }
}
