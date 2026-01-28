//
//  ContentView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var navManager = NavigationManager.shared
    @State private var selectedTab: TabStyle = .Home
    @Namespace private var nameSpace

    var body: some View {
        NavigationStack(path: self.$navManager.path) {
            ZStack(alignment: .bottom) {
                TabView(selection: self.$selectedTab) {
                    HomeView(namespace: self.nameSpace)
                        .tag(TabStyle.Home)
                        .tabItem {
                            self.tabItemView(style: .Home, selected: self.selectedTab == .Home)
                        }

                    AILabView(namespace: self.nameSpace)
                        .tag(TabStyle.AILab)
                        .tabItem {
                            self.tabItemView(style: .AILab, selected: self.selectedTab == .AILab)
                        }

                    ARHomeView(namespace: self.nameSpace)
                        .tag(TabStyle.ARHome)
                        .tabItem {
                            self.tabItemView(style: .ARHome, selected: self.selectedTab == .ARHome)
                        }
                }
            }.modifier(NavigationDestinationImage(namespace: self.nameSpace))
        }
        .onAppear {
            self.navManager.push(.createAI)
        }
    }

    private func tabItemView(style: TabStyle, selected: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: style.imageName)
                .resizable()

            Text(style.tabTitle)
                .font(.system(size: 10))
        }
        .foregroundColor(selected ? .primary : .secondary)
    }
}

enum TabStyle: Int, CaseIterable, Identifiable {
    var id: Int {
        return self.rawValue
    }

    case Home = 0
    case AILab = 1
    case ARHome = 2

    var imageName: String {
        switch self {
        case .Home: return "house"
        case .AILab: return "wand.and.stars"
        case .ARHome: return "cube.transparent"
        }
    }

    var tabTitle: LocalizedStringKey {
        switch self {
        case .Home: return LocalizedStringKey("Home")
        case .AILab: return LocalizedStringKey("AILab")
        case .ARHome: return LocalizedStringKey("AR")
        }
    }
}

#Preview {
    ContentView()
}
