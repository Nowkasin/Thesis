//
//  BeActiveApp.swift
//  BeActive
//
//  Created by Kasin Thappawan on 29/5/2567 BE.
//

import SwiftUI

@main
struct BeActiveApp: App {
    @StateObject var manager = HealthManager()
    var body: some Scene {
        WindowGroup {
            BeActiTabView()
                .environmentObject(manager)
        }
    }
}
