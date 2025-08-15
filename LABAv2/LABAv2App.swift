import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import UIKit

// MARK: - AppDelegate (Firebase init only)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private let pendingPushStorageKey = "laba.pendingPush.userInfo"
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase
        FirebaseApp.configure()
        
        // Delegati notifiche & FCM
        UNUserNotificationCenter.current().delegate = self
        
        // Se l'app viene aperta toccando una notifica (da terminata), persiste il payload
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let data = try? JSONSerialization.data(withJSONObject: remote, options: []) {
            UserDefaults.standard.set(data, forKey: pendingPushStorageKey)
        }
        
        Messaging.messaging().isAutoInitEnabled = true
        Messaging.messaging().delegate = self
        
        // Spostata l'iscrizione al topic "tutti" dopo l'ottenimento del token FCM (vedi messaging(_:didReceiveRegistrationToken:))
        
        
        return true
    }
    
    // App in foreground: mostra banner/audio e inoltra il payload all’inbox
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        NotificationCenter.default.post(name: .labaDidReceiveRemoteNotification,
                                        object: nil,
                                        userInfo: userInfo)
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
            UserDefaults.standard.set(data, forKey: pendingPushStorageKey)
        }
        completionHandler([.banner, .list, .sound, .badge])
    }

    // Tap su notifica (anche da freddo)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: .labaDidReceiveRemoteNotification,
                                        object: nil,
                                        userInfo: userInfo)
        if let data = try? JSONSerialization.data(withJSONObject: userInfo, options: []) {
            UserDefaults.standard.set(data, forKey: pendingPushStorageKey)
        }
        completionHandler()
    }
    
    // Ricevi/aggiorna token FCM
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📲 FCM Token (delegate):", fcmToken ?? "nil")
        if let _ = fcmToken {
            Messaging.messaging().subscribe(toTopic: "tutti") { error in
                if let error = error {
                    print("❌ Topic subscribe error (on token):", error.localizedDescription)
                } else {
                    print("✅ Iscritto al topic 'tutti' (on token)")
                }
            }
        }
    }

    // Passa il token APNs a Firebase e ritenta il fetch del token FCM
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1) Salva il token APNs in Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        // 2) Log utile per debug
        let apnsHex = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📩 APNs Token:", apnsHex)

        // 3) Re-fetch del token FCM ora che l'APNs è disponibile
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ FCM token error (post-APNs):", error.localizedDescription)
            } else if let token = token {
                print("📲 FCM Token (post-APNs):", token)
                // (Facoltativo) ritenta l'iscrizione al topic globale
                Messaging.messaging().subscribe(toTopic: "tutti") { err in
                    if let err = err {
                        print("❌ Topic subscribe error (post-APNs):", err.localizedDescription)
                    } else {
                        print("✅ Conferma iscrizione topic 'tutti' (post-APNs)")
                    }
                }
            }
        }
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Errore registrazione APNs:", error.localizedDescription)
    }
}

// MARK: - Main App
@main
struct LABAv2App: App {
    // registra l'AppDelegate per l'inizializzazione Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
