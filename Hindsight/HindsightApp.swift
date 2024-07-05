import SwiftUI
import UserNotifications

@main
struct HindsightApp: App {
    var _frontApp: FrontAppObserver;
    
    init() {
        _frontApp = FrontAppObserver();
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(_frontApp.recvNotification(_:)), name: NSWorkspace.didHideApplicationNotification, object: nil);

        
        let center = UNUserNotificationCenter.current()

        Task {
            do {
                try await center.requestAuthorization(options: [.alert, .sound, .badge])
                scheduleNotificationTimer(time: 20 * 60)
            } catch {
                print("Error info: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

func scheduleNotificationTimer(time: TimeInterval) {
    Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
        notificationTimerElapsed()
    })
}

func notificationTimerElapsed() {
    // TODO: it would be great to detect if I'm actually in a zoom meeting
    let runningZoomApps = NSWorkspace.shared.runningApplications.filter { app in app.localizedName!.contains("zoom.us")
    }
    let isAnyZoomOpen = !runningZoomApps.isEmpty
    let isAnyZoomActive = !runningZoomApps.filter { app in app.isActive }.isEmpty
    // Don't interrupt me while in a meeting - wait a minute and try again
    if isAnyZoomActive {
        scheduleNotificationTimer(time: 60)
    } else {
        Task {
            await sendNotification(playSound: !isAnyZoomOpen)
        }
    }
}

func sendNotification(playSound: Bool) async {
    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    content.title = "Timer done!"
    content.body = "It's time to stretch and rest your eyes"
    if playSound {
        content.sound = UNNotificationSound.criticalSoundNamed(.init("StarTrekAlert"))
    }
    let request = UNNotificationRequest(identifier: "test", content: content, trigger: nil)
    do {
        try await center.add(request)
    } catch {
        print("Error info: \(error)")
    }
    scheduleNotificationTimer(time: 20 * 60)
}

class FrontAppObserver {
    @objc func recvNotification(_ notification: NSNotification) {
        print("notif");
    }
}

