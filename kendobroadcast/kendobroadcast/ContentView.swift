import SwiftUI
import UserNotifications
import AVFoundation

// MARK: - 스케줄 구조체
struct BroadcastSchedule {
    let id: String
    let title: String
    let hour: Int
    let minute: Int
    let weekdays: [Int] // 2: 월, 3: 화, 4: 수, 5: 목, 6: 금, 7: 토
    let soundName: String
}

struct ContentView: View {
    // 🎵 오디오 플레이어 (테스트용)
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isSystemActive = false
    
    // ⏰ 정식 방송 시간표 (월~토)
    let schedules: [BroadcastSchedule] = [
        BroadcastSchedule(id: "C1_PreStart", title: "1교시 예비종", hour: 15, minute: 25, weekdays: [2,3,4,5,6,7], soundName: "start.wav"),
        BroadcastSchedule(id: "C1_End", title: "1교시 종료", hour: 16, minute: 20, weekdays: [2,3,4,5,6,7], soundName: "endloof.wav"),
        BroadcastSchedule(id: "C2_PreStart", title: "2교시 예비종", hour: 16, minute: 55, weekdays: [2,3,4,5,6,7], soundName: "start.wav"),
        BroadcastSchedule(id: "C2_End", title: "2교시 종료", hour: 17, minute: 50, weekdays: [2,3,4,5,6,7], soundName: "endloof.wav"),
        BroadcastSchedule(id: "C3_PreStart", title: "3교시 예비종", hour: 18, minute: 25, weekdays: [2,3,4,5,6,7], soundName: "start.wav"),
        BroadcastSchedule(id: "C3_End", title: "3교시 종료", hour: 19, minute: 20, weekdays: [2,3,4,5,6,7], soundName: "endloof.wav"),
        BroadcastSchedule(id: "C4_PreStart", title: "4교시 예비종", hour: 19, minute: 55, weekdays: [2,3,4,5,6,7], soundName: "start.wav"),
        BroadcastSchedule(id: "C4_End", title: "4교시 종료", hour: 20, minute: 50, weekdays: [2,3,4,5,6,7], soundName: "endloof.wav"),
        BroadcastSchedule(id: "C5_PreStart", title: "5교시 예비종", hour: 21, minute: 05, weekdays: [2,3,4,5,6,7], soundName: "start.wav"),
        BroadcastSchedule(id: "C5_End", title: "5교시 종료", hour: 22, minute: 00, weekdays: [2,3,4,5,6,7], soundName: "endloof.wav")
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("강남경기검도관 방송 시스템")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            
            // 🛠️ 테스트 버튼 영역
            VStack(spacing: 15) {
                Text("소리 테스트 (누르고 바로 화면 끄기)")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Button(action: {
                    scheduleTestNotification(soundName: "start.wav", title: "예비종 테스트")
                }) {
                    Text("예비종(팝콘) 테스트")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    scheduleTestNotification(soundName: "endloof.wav", title: "종료음 테스트")
                }) {
                    Text("종료음(본종) 테스트")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // 🚀 정식 작동 버튼
            Button(action: {
                requestPermissionAndSchedule()
            }) {
                Text(isSystemActive ? "정식 스케줄 시스템 작동 중 ✅" : "강남경기검도관 정식 방송 작동하기")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSystemActive ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .onAppear {
            // 앱 켤 때 권한 미리 묻기
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
    
    // MARK: - 5초 뒤 테스트 알림 함수
    func scheduleTestNotification(soundName: String, title: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "테스트 방송이 울립니다."
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 정식 스케줄 등록 함수
    func requestPermissionAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                setupAllSchedules()
                DispatchQueue.main.async {
                    self.isSystemActive = true
                }
            }
        }
    }
    
    func setupAllSchedules() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for schedule in schedules {
            for weekday in schedule.weekdays {
                let content = UNMutableNotificationContent()
                content.title = schedule.title
                content.body = "방송이 진행 중입니다."
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: schedule.soundName))
                
                var dateComponents = DateComponents()
                dateComponents.weekday = weekday
                dateComponents.hour = schedule.hour
                dateComponents.minute = schedule.minute
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                // 고유 ID 생성 (예: C1_PreStart_2 = 1교시 월요일 예비종)
                let uniqueID = "\(schedule.id)_\(weekday)"
                let request = UNNotificationRequest(identifier: uniqueID, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}
