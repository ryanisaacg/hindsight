import SwiftUI
import UserNotifications
import AVFoundation

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
    DispatchQueue.main.async {
        Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
            notificationTimerElapsed()
        })
    }
}

func notificationTimerElapsed() {
    // Don't interrupt me while in a meeting - wait a minute and try again
    if isAnyCameraOn() {
        scheduleNotificationTimer(time: 60)
    } else {
        Task {
            await sendNotification(playSound: true)
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
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
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

func isAnyCameraOn() -> Bool {
    let deviceDescoverySession = AVCaptureDevice.DiscoverySession.init(
                                    deviceTypes: [.builtInWideAngleCamera,
                                                  .externalUnknown],
                                    mediaType: AVMediaType.video,
                                    position: AVCaptureDevice.Position.unspecified)
        
    for device in deviceDescoverySession.devices {
        if Camera(captureDevice: device).isOn() {
            return true;
        }
    }
    
    return false;
}
