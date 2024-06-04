//
//  BeActiTabView.swift
//  BeActive
//
//  Created by Kasin Thappawan on 29/5/2567 BE.
//

import SwiftUI

struct BeActiTabView: View {
    @EnvironmentObject var manager: HealthManager
    @State var selectedTab = "Home"
    var body: some View {
        TabView(selection: $selectedTab){
            HomeView()
                .tag("Home")
                .tabItem {
                    Image(systemName: "house")
                }
                .environmentObject(manager)
            ContentView()
                .tag("Content")
                .tabItem {
                    Image(systemName: "person")
            }
        }
    }
}
struct BeActiTabView_Previews: PreviewProvider {
    static var previews: some View {
        BeActiTabView()
            .environmentObject(HealthManager())  // Provide the environment object for preview
    }
}
