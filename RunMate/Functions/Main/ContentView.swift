//
//  ContentView.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var navManager = NavigationManager.shared
    @Namespace private var nameSpace

    var body: some View {
        NavigationStack(path: self.$navManager.path) {
            ZStack(alignment: .bottom) {
                TabView(selection: self.$navManager.selectedTab) {
                    AILabView(namespace: self.nameSpace)
                        .tag(TabStyle.Create)
                        .tabItem {
                            self.tabItemView(style: .Create, selected: navManager.selectedTab == .Create)
                        }

                    ImageEncryptionView(namespace: self.nameSpace)
                        .tag(TabStyle.Vault)
                        .tabItem {
                            self.tabItemView(style: .Vault, selected: navManager.selectedTab == .Vault)
                        }

                    MeView(namespace: self.nameSpace)
                        .tag(TabStyle.ME)
                        .tabItem {
                            self.tabItemView(style: .ME, selected: navManager.selectedTab == .ME)
                        }
                }
            }.modifier(NavigationDestinationImage(namespace: self.nameSpace))
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

    case Create = 0
    case Vault = 1
    case ME = 2

    var imageName: String {
        switch self {
        case .Create: return "wand.and.stars"
        case .Vault: return "lock.shield.fill"
        case .ME: return "person"
        }
    }

    var tabTitle: LocalizedStringKey {
        switch self {
        case .Create: return LocalizedStringKey("Create")
        case .Vault: return LocalizedStringKey("Vault")
        case .ME: return LocalizedStringKey("Me")
        }
    }
}

#Preview {
    ContentView()
}
