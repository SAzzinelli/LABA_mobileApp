//
//  LABAv2App.swift
//  LABAv2
//
//  Created by Simone Azzinelli on 12/08/25.
//

import SwiftUI
import UserNotifications
import UIKit

@main
struct LABAv2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Errore richiesta notifiche: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Permesso notifiche negato")
            }
        }
    }
}


