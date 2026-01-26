//
//  VideoItemView.swift
//  DeepClean
//
//  Created by gaozhongkui on 2026/1/5.
//  Copyright © 2026 CleanNow. All rights reserved.
//

import SwiftUI

struct VideoItemView: View {
    let item: PollinationFeedItem? = nil
    var onClickTap: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: "https://image.pollinations.ai/prompt/lantern%20crafting%2C%20farmhouse%20style%2C%20symbolic%20colors%2C%20symbolically%20rich%20light%2C%20architectural%20plane%20structured%2C%20resting%20quietly%2C%20conserved%20properly%20accurate%20reproduction%2C%20sometimes%20contemplated?width=576&height=1024&model=%66%6C%75%78%2D%72%65%61%6C%69%73%6D&nologo=true&enhance=true&safe=true&seed=24865&negative_prompt=%70%65%6F%70%6C%65%2C+%70%65%72%73%6F%6E%2C+%68%75%6D%61%6E%2C+%6D%61%6E%2C+%77%6F%6D%61%6E%2C+%67%69%72%6C%2C+%62%6F%79%2C+%63%68%69%6C%64%2C+%62%61%62%79%2C+%66%69%67%75%72%65%2C+%63%68%61%72%61%63%74%65%72%2C+%70%6F%72%74%72%61%69%74%2C+%66%61%63%65%2C+%62%6F%64%79%2C+%73%6F%6D%65%6F%6E%65%2C+%61%6E%79%6F%6E%65%2C+%66%61%63%65%2C+%66%61%63%65%73%2C+%68%65%61%64%2C+%62%6F%64%79%2C+%73%6B%69%6E%2C+%68%61%6E%64%2C+%68%61%6E%64%73%2C+%61%72%6D%2C+%61%72%6D%73%2C+%6C%65%67%2C+%6C%65%67%73%2C+%66%6F%6F%74%2C+%66%65%65%74%2C+%65%79%65%2C+%65%79%65%73%2C+%6D%6F%75%74%68%2C+%6E%6F%73%65%2C+%68%61%69%72%2C+%6E%75%64%65%2C+%6E%61%6B%65%64%2C+%6E%75%64%69%74%79%2C+%62%61%72%65%2C+%75%6E%64%72%65%73%73%65%64%2C+%75%6E%63%6C%6F%74%68%65%64%2C+%6E%73%66%77%2C+%65%78%70%6C%69%63%69%74%2C+%61%64%75%6C%74%2C+%73%65%78%75%61%6C%2C+%73%65%78%79%2C+%65%72%6F%74%69%63%2C+%70%72%6F%76%6F%63%61%74%69%76%65%2C+%62%72%65%61%73%74%2C+%62%72%65%61%73%74%73%2C+%63%68%65%73%74%2C+%69%6E%74%69%6D%61%74%65%2C+%73%65%6E%73%75%61%6C%2C+%63%72%6F%77%64%2C+%70%65%6F%70%6C%65%2C+%67%72%6F%75%70%2C+%61%75%64%69%65%6E%63%65%2C+%70%65%64%65%73%74%72%69%61%6E%2C+%74%6F%75%72%69%73%74%2C+%76%69%73%69%74%6F%72%2C+%77%6F%72%6B%65%72%2C+%66%61%72%6D%65%72%2C+%6D%6F%6E%6B%2C+%70%72%69%65%73%74%2C+%67%75%61%72%64%2C+%73%6F%6C%64%69%65%72%2C+%6D%6F%64%65%6C%2C+%68%75%6D%61%6E+%66%69%67%75%72%65%2C+%68%75%6D%61%6E+%66%6F%72%6D%2C+%68%75%6D%61%6E+%73%69%6C%68%6F%75%65%74%74%65%2C+%70%65%72%73%6F%6E+%73%69%6C%68%6F%75%65%74%74%65%2C+%73%65%6C%66%69%65%2C+%70%6F%72%74%72%61%69%74+%6D%6F%64%65%2C+%6C%6F%77+%71%75%61%6C%69%74%79%2C+%77%6F%72%73%74+%71%75%61%6C%69%74%79%2C+%62%61%64+%71%75%61%6C%69%74%79%2C+%6C%6F%77+%72%65%73%6F%6C%75%74%69%6F%6E%2C+%62%6C%75%72%72%79%2C+%62%6C%75%72%72%65%64%2C+%62%6C%75%72%2C+%6F%75%74+%6F%66+%66%6F%63%75%73%2C+%70%69%78%65%6C%61%74%65%64%2C+%61%72%74%69%66%61%63%74%73%2C+%64%69%73%74%6F%72%74%65%64%2C+%64%65%66%6F%72%6D%65%64%2C+%75%67%6C%79%2C+%62%61%64+%61%6E%61%74%6F%6D%79%2C+%62%61%64+%70%72%6F%70%6F%72%74%69%6F%6E%73%2C+%77%61%74%65%72%6D%61%72%6B%2C+%74%65%78%74%2C+%73%69%67%6E%61%74%75%72%65%2C+%75%73%65%72%6E%61%6D%65%2C+%6C%6F%67%6F")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.overlay(Image(systemName: "photo"))
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }

            Text("lantern crafting, farmhouse style, symbolic colors, symbolically rich light, architectural plane structured, resting quietly, conserved properly accurate reproduction, sometimes contemplated" ?? "No Prompt")
                .font(.system(size: 14))
                .lineLimit(2)
                .padding(6)
                .multilineTextAlignment(.leading)
                .foregroundColor(.white)
                .background(
                    Color.black.opacity(0.6).shadow(radius: 2)
                )
        }
        .background(Color(hex: "#C9DFD9"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(Rectangle())
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "#BDCCCB"), lineWidth: 0.5)
        )
        .onTapGesture {
            onClickTap?()
        }
    }
}
