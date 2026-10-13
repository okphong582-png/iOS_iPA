import SwiftUI
import UIKit
import Foundation
import NetworkExtension

// MARK: - MeoUIState (Pure GUI State Adapter - Powered by MeoLib .a Static Library)
class MeoUIState: ObservableObject {
    static let shared = MeoUIState()
    let core = MeoCore.shared()

    @Published var isAuthed: Bool = true
    @Published var authError: String? = nil
    @Published var deviceExpires: String = ""
    @Published var systemActive: Bool = true

    // Visuals & Aim Mod Options (Synchronized with libmeo.a)
    @Published var espMaster: Bool = false
    @Published var espBox: Bool = false
    @Published var espLine: Bool = false
    @Published var espName: Bool = false
    @Published var espHealth: Bool = false
    @Published var espDistance: Bool = false
    @Published var espSkeleton: Bool = false

    @Published var aimEnabled: Bool = false
    @Published var aimSystemEnabled: Bool = false
    @Published var espFov: Bool = false
    @Published var noRecoil: Bool = false
    @Published var aimTarget: Int = 0
    @Published var fovSize: Float = 60.0
    @Published var headshotRate: Float = 60.0

    var deviceId: String {
        return core.deviceId
    }

    init() {
        syncFromCore()
        isAuthed = true

        core.onTokenRefreshed = { [weak self] in
            DispatchQueue.main.async {
                self?.syncFromCore()
                self?.isAuthed = true
            }
        }
    }

    func syncFromCore() {
        core.loadConfig()
        isAuthed = true
        systemActive = core.systemActive
        deviceExpires = core.deviceExpires

        espMaster = core.espMaster
        espBox = core.espBox
        espLine = core.espLine
        espName = core.espName
        espHealth = core.espHealth
        espDistance = core.espDistance
        espSkeleton = core.espSkeleton

        aimEnabled = core.aimEnabled
        aimSystemEnabled = core.aimSystemEnabled
        espFov = core.espFov
        noRecoil = core.noRecoil
        aimTarget = core.aimTarget
        fovSize = core.fovSize
        headshotRate = core.headshotRate
    }

    func pushToCore(bundleID: String) {
        core.espMaster = espMaster
        core.espBox = espBox
        core.espLine = espLine
        core.espName = espName
        core.espHealth = espHealth
        core.espDistance = espDistance
        core.espSkeleton = espSkeleton

        core.aimEnabled = aimEnabled
        core.aimSystemEnabled = aimSystemEnabled
        core.espFov = espFov
        core.noRecoil = noRecoil
        core.aimTarget = aimTarget
        core.fovSize = fovSize
        core.headshotRate = headshotRate

        core.saveAndSyncConfig(forBundleID: bundleID)
    }

    func startHeartbeat() { core.startHeartbeat() }
    func stopHeartbeat() { core.stopHeartbeat() }
}

// MARK: - Custom Toggle Style (Black & White Minimalist)
struct SlimToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { configuration.isOn.toggle() } }) {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? Color.white : Color(white: 0.18))
                    .frame(width: 46, height: 24)
                    .overlay(
                        Capsule().stroke(Color(white: 0.35), lineWidth: 1)
                    )
                Circle()
                    .fill(configuration.isOn ? Color.black : Color(white: 0.55))
                    .frame(width: 18, height: 18)
                    .padding(3)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Alert Item Model
struct ActiveAlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let isDestructive: Bool
    let action: (() -> Void)?
}

// MARK: - Main GUI View
struct ContentView: View {
    @Environment(\.appLanguage) private var language
    @EnvironmentObject private var patchDraftCoordinator: PatchDraftCoordinator
    @EnvironmentObject private var patchStore: PatchProjectStore
    @EnvironmentObject private var repositoryStore: PackageRepositoryStore
    @ObservedObject private var state = MeoUIState.shared

    @State private var isInjecting = false
    @State private var hasInjected = false
    @State private var currentTab: String = "Function"   // "Function" | "Profile" | "DnsApp"
    @State private var gameTab: String = "ff"            // "ff" | "ffmax"
    @State private var logs: [String] = []
    @State private var isDnsInstalled = false
    @State private var isDnsActive = false
    @State private var isInstallingDns = false
    @State private var activeAlert: ActiveAlertItem?

    private var selectedBundleID: String {
        gameTab == "ff" ? "com.dts.freefireth" : "com.dts.freefiremax"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── GUI CHÍNH ──
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.white)
                        Text("MeoMeo")
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 10)

                // CONTENT AREA
                ZStack {
                    if currentTab == "Function" {
                        VStack(spacing: 0) {
                            // GAME SELECTOR
                            HStack(spacing: 0) {
                                ForEach(["ff", "ffmax"], id: \.self) { id in
                                    let label = (id == "ff") ? "Free Fire" : "Free Fire MAX"
                                    Button(action: {
                                        gameTab = id
                                        if hasInjected { state.pushToCore(bundleID: selectedBundleID) }
                                    }) {
                                        Text(label)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundColor(gameTab == id ? Color.black : Color(white: 0.65))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 36)
                                            .background(gameTab == id ? Color.white : Color.clear)
                                    }
                                }
                            }
                            .background(Color(white: 0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(white: 0.25), lineWidth: 1)
                             )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)

                            functionView
                        }
                    } else if currentTab == "Profile" {
                        profileView
                    } else {
                        dnsAppView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // BOTTOM TAB BAR
                bottomTabBar
            }
        }
        .alert(item: $activeAlert) { item in
            if item.isDestructive {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    primaryButton: .destructive(Text("Xác Nhận")) {
                        item.action?()
                    },
                    secondaryButton: .cancel(Text("Huỷ"))
                )
            } else {
                return Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("Đóng"))
                )
            }
        }
        .onAppear {
            state.syncFromCore()
            hasInjected = MeoCore.shared().isModInjected(forBundleID: selectedBundleID)
            checkDnsStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkDnsStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NEDNSSettingsConfigurationDidChange)) { _ in
            checkDnsStatus()
        }
    }

    // MARK: - Function Tab (Đen Trắng)
    var functionView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {

                // ── BẬT / TẮT DNS NHANH ─────────────────────────────────
                CardView(title: "DNS BẢO VỆ (MEOMEEXT-FF)", icon: "bolt.shield.fill") {
                    HStack(spacing: 12) {
                        Image(systemName: isDnsActive ? "shield.fill" : "shield.slash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isDnsActive ? .white : Color(white: 0.50))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isDnsActive ? "DNS: ĐANG BẬT" : "DNS: ĐANG TẮT")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isDnsActive ? .white : Color(white: 0.65))
                            Text(isDnsActive ? "Bảo vệ DoH & Chặn Telemetry đang hoạt động" : "Gạt công tắc để BẬT ngay")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(white: 0.50))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { self.isDnsActive },
                            set: { val in self.toggleDns(enabled: val) }
                        ))
                        .toggleStyle(SlimToggleStyle())
                        .labelsHidden()
                    }
                }

                // ── SILENT AIM ─────────────────────────────────────────
                CardView(title: "SILENT AIM", icon: "scope") {
                    VStack(spacing: 14) {
                        ToggleRow(label: "Silent Aim", icon: "wind", on: Binding(
                            get: { state.aimEnabled },
                            set: { val in state.aimEnabled = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))

                        if state.aimEnabled {
                            Divider().background(Color(white: 0.20))
                            ToggleRow(label: "Hiện Vòng FOV", icon: "circle.dashed", on: Binding(
                                get: { state.espFov },
                                set: { val in state.espFov = val; state.pushToCore(bundleID: selectedBundleID) }
                            ))
                            SliderRow(label: "Silent FOV", value: Binding(
                                get: { state.fovSize },
                                set: { val in state.fovSize = val; state.pushToCore(bundleID: selectedBundleID) }
                            ), range: 1...400, isPercent: false)
                            SliderRow(label: "Tỉ Lệ Headshot", value: Binding(
                                get: { state.headshotRate },
                                set: { val in state.headshotRate = val; state.pushToCore(bundleID: selectedBundleID) }
                            ), range: 0...100, isPercent: true)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vị Trí Ngắm (Target Bone)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(white: 0.65))

                                HStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { idx in
                                        let name = idx == 0 ? "Đầu (Head)" : (idx == 1 ? "Cổ (Neck)" : "Người (Body)")
                                        Button(action: {
                                            state.aimTarget = idx
                                            state.pushToCore(bundleID: selectedBundleID)
                                        }) {
                                            Text(name)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(state.aimTarget == idx ? Color.black : Color.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 36)
                                                .background(state.aimTarget == idx ? Color.white : Color(white: 0.05))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color(white: 0.25), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── AIM SYSTEM ─────────────────────────────────────────
                CardView(title: "AIM SYSTEM", icon: "target") {
                    VStack(spacing: 14) {
                        ToggleRow(label: "Hệ Thống Aimbot", icon: "flame", on: Binding(
                            get: { state.aimSystemEnabled },
                            set: { val in state.aimSystemEnabled = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))

                        if state.aimSystemEnabled {
                            Divider().background(Color(white: 0.20))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vị Trí Ngắm")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(white: 0.65))

                                HStack(spacing: 8) {
                                    ForEach(0..<3, id: \.self) { idx in
                                        let name = idx == 0 ? "Đầu (Head)" : (idx == 1 ? "Cổ (Neck)" : "Người (Body)")
                                        Button(action: {
                                            state.aimTarget = idx
                                            state.pushToCore(bundleID: selectedBundleID)
                                        }) {
                                            Text(name)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(state.aimTarget == idx ? Color.black : Color.white)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 36)
                                                .background(state.aimTarget == idx ? Color.white : Color(white: 0.05))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color(white: 0.25), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }

                            ToggleRow(label: "Giảm Giật (No Recoil)", icon: "minus.circle", on: Binding(
                                get: { state.noRecoil },
                                set: { val in state.noRecoil = val; state.pushToCore(bundleID: selectedBundleID) }
                            ))
                        }
                    }
                }

                // ── VISUALS ────────────────────────────────────────────
                CardView(title: "VISUALS (ESP)", icon: "eye") {
                    VStack(spacing: 14) {
                        ToggleRow(label: "Bật ESP Tổng", icon: "eye.fill", on: Binding(
                            get: { state.espMaster },
                            set: { val in state.espMaster = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Khung (Box)", icon: "person.crop.square", on: Binding(
                            get: { state.espBox },
                            set: { val in state.espBox = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Dây Kẻ (Line)", icon: "line.diagonal", on: Binding(
                            get: { state.espLine },
                            set: { val in state.espLine = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Tên (Name)", icon: "textformat", on: Binding(
                            get: { state.espName },
                            set: { val in state.espName = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Thanh Máu (Health)", icon: "heart.fill", on: Binding(
                            get: { state.espHealth },
                            set: { val in state.espHealth = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Khoảng Cách (Distance)", icon: "ruler", on: Binding(
                            get: { state.espDistance },
                            set: { val in state.espDistance = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                        Divider().background(Color(white: 0.20))
                        ToggleRow(label: "Hiện Khung Xương (Skeleton)", icon: "figure.walk", on: Binding(
                            get: { state.espSkeleton },
                            set: { val in state.espSkeleton = val; state.pushToCore(bundleID: selectedBundleID) }
                        ))
                    }
                }

                // ── INJECT / UNINSTALL ─────────────────────────────────
                if !hasInjected {
                    Button(action: { injectGame() }) {
                        HStack {
                            if isInjecting {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.black))
                            } else {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(Color.black)
                                Text("CÀI ĐẶT MOD VÀO GAME")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isInjecting)
                } else {
                    Button(action: { uninstallMod() }) {
                        HStack {
                            Image(systemName: "trash.fill").foregroundColor(.white)
                            Text("GỠ BỎ MOD KHỎI GAME")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(white: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(white: 0.35), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Profile Tab (Đen Trắng)
    var profileView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                CardView(title: "THÔNG TIN THIẾT BỊ", icon: "iphone") {
                    VStack(alignment: .leading, spacing: 14) {
                        // HWID Row
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MÃ THIẾT BỊ (HWID)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(white: 0.65))
                            HStack {
                                Text(state.deviceId)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color(white: 0.85))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = state.deviceId
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color(white: 0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(10)
                            .background(Color(white: 0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        // Status Row
                        HStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                            Text("TRẠNG THÁI: HOẠT ĐỘNG")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                }

                // Telegram Support Channels Card
                CardView(title: "KÊNH LIÊN HỆ & HỖ TRỢ", icon: "paperplane.fill") {
                    VStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "https://t.me/cheatmeo") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "megaphone.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Channel Telegram")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("t.me/cheatmeo")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color(white: 0.70))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color(white: 0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(white: 0.20), lineWidth: 1)
                            )
                        }

                        Button(action: {
                            if let url = URL(string: "https://t.me/truongdeptrai7") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Admin Hỗ Trợ")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("t.me/truongdeptrai7")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color(white: 0.70))
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color(white: 0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(white: 0.20), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - DNS App Tab (iOS Configuration Profile Style)
    var dnsAppView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // BẬT / TẮT DNS NHANH CARD
                CardView(title: "BẬT / TẮT DNS NHANH", icon: "bolt.shield.fill") {
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            Image(systemName: isDnsActive ? "shield.fill" : "shield.slash.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(isDnsActive ? .white : Color(white: 0.50))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(isDnsActive ? "DNS: ĐANG BẬT" : "DNS: ĐANG TẮT")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(isDnsActive ? .white : Color(white: 0.65))
                                Text(isDnsActive ? "Tự động chặn report / chống ban server Garena" : "Bấm nút hoặc gạt để BẬT ngay")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(white: 0.55))
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { self.isDnsActive },
                                set: { val in self.toggleDns(enabled: val) }
                            ))
                            .toggleStyle(SlimToggleStyle())
                            .labelsHidden()
                        }

                        // Quick 1-tap Action Buttons
                        HStack(spacing: 10) {
                            Button(action: {
                                toggleDns(enabled: true)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("BẬT DNS")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .foregroundColor(isDnsActive ? Color.black : Color.white)
                                .background(isDnsActive ? Color.white : Color(white: 0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(isDnsActive ? 0.8 : 0.2), lineWidth: 1)
                                )
                            }

                            Button(action: {
                                toggleDns(enabled: false)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("TẮT DNS")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .foregroundColor(!isDnsActive ? Color.black : Color(white: 0.85))
                                .background(!isDnsActive ? Color.white : Color(white: 0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(!isDnsActive ? 0.8 : 0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                // Header Card with Cat Icon & Status
                CardView(title: "CẤU HÌNH DNS BẢO VỆ", icon: "pawprint.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(white: 0.14))
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5)
                                    )
                                Image(systemName: "cat.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                Text("MeoMeoExt-FF DNS")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)

                                HStack(spacing: 8) {
                                    Text(isDnsActive ? "Active" : (isDnsInstalled ? "Installed" : "Not installed"))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor((isDnsActive || isDnsInstalled) ? Color.black : Color(white: 0.85))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background((isDnsActive || isDnsInstalled) ? Color.white : Color(white: 0.22))
                                        .clipShape(Capsule())

                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(isDnsActive ? Color.green : (isDnsInstalled ? Color.yellow : Color.green))
                                            .frame(width: 6, height: 6)
                                        Text(isDnsActive ? "Đang Hoạt Động" : (isDnsInstalled ? "Select in Settings" : "Ready"))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(white: 0.85))
                                    }
                                }
                            }
                            Spacer()
                        }

                        Divider().background(Color(white: 0.20))

                        Text("Selected reflects the iOS DNS preference; it does not confirm routing for every connection.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(white: 0.70))
                            .lineSpacing(3)

                        // Install DNS Button
                        Button(action: {
                            installDnsProfile()
                        }) {
                            HStack(spacing: 8) {
                                if isInstallingDns {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    Text("Đang Cài Đặt...")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                } else {
                                    Image(systemName: isDnsActive ? "checkmark.shield.fill" : (isDnsInstalled ? "arrow.clockwise.circle.fill" : "arrow.down.circle.fill"))
                                        .font(.system(size: 17, weight: .bold))
                                    Text(isDnsActive ? "MeoMeoExt-FF DNS Đang Bật" : (isDnsInstalled ? "Cài Lại MeoMeoExt-FF DNS" : "Install DNS"))
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .foregroundColor(.black)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isInstallingDns)
                    }
                }

                // Installation Instructions Card
                CardView(title: "HƯỚNG DẪN KÍCH HOẠT SAU KHI CÀI", icon: "gearshape.fill") {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 10) {
                            Text("1.")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white)
                            Text("Bấm **Install DNS** ở trên và chọn **Cho phép (Allow)** trên hộp thoại hệ thống iOS (không cần tải file).")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(white: 0.85))
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Text("2.")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.white)
                            Text("After installation, open iOS Settings > General > VPN & Device Management > DNS and select MeoMeoExt-FF DNS")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Divider().background(Color(white: 0.20))

                        Button(action: {
                            openIosSettings()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Mở Cài Đặt iOS (Open Settings)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .padding(.horizontal, 14)
                            .foregroundColor(.white)
                            .background(Color(white: 0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(white: 0.28), lineWidth: 1)
                            )
                        }
                    }
                }

                // Protection Status Card
                CardView(title: "TÍNH NĂNG BẢO MẬT & CHỐNG BAN", icon: "shield.lefthalf.filled") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Chặn Gói Tin Giám Sát (Anti-Telemetry)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Tự động lọc các request check log và report gửi về server Garena.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.60))
                            }
                            Spacer()
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Bottom Tab Bar
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            bottomTabItem(title: "Function", icon: "slider.horizontal.3", tab: "Function")
            bottomTabItem(title: "Profile", icon: "person.crop.circle.fill", tab: "Profile")
            bottomTabItem(title: "DnsApp", icon: "pawprint.fill", tab: "DnsApp")
        }
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(Color(white: 0.08).ignoresSafeArea(edges: .bottom))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.20)),
            alignment: .top
        )
    }

    private func bottomTabItem(title: String, icon: String, tab: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) {
                currentTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: currentTab == tab ? .bold : .regular))
                    .foregroundColor(currentTab == tab ? .white : Color(white: 0.45))
                Text(title)
                    .font(.system(size: 11, weight: currentTab == tab ? .bold : .medium, design: .rounded))
                    .foregroundColor(currentTab == tab ? .white : Color(white: 0.45))
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - GUI Actions (Calling MeoCore in libmeo.a)
    private func uninstallMod() {
        MeoCore.shared().uninstallModFromGame(withBundleID: selectedBundleID)
        hasInjected = false
        state.stopHeartbeat()
    }

    private func injectGame() {
        if MeoCore.isDebuggerAttached() { return }
        guard state.isAuthed else { return }
        state.pushToCore(bundleID: selectedBundleID)
        isInjecting = true
        MeoCore.shared().injectToGame(withBundleID: selectedBundleID) { success, error in
            DispatchQueue.main.async {
                self.isInjecting = false
                if success {
                    self.hasInjected = true
                    self.currentTab = "Function"
                }
            }
        }
    }

    private func checkDnsStatus() {
        NEDNSSettingsManager.shared().loadFromPreferences { error in
            DispatchQueue.main.async {
                if error == nil {
                    let manager = NEDNSSettingsManager.shared()
                    let hasSettings = (manager.dnsSettings != nil)
                    let name = manager.localizedDescription ?? ""
                    if hasSettings || name.contains("MeoMeoExt") {
                        self.isDnsInstalled = true
                        self.isDnsActive = manager.isEnabled
                    } else {
                        self.isDnsInstalled = false
                        self.isDnsActive = false
                    }
                }
            }
        }
    }

    func toggleDns(enabled: Bool) {
        let manager = NEDNSSettingsManager.shared()
        if enabled {
            installDnsProfile()
        } else {
            isInstallingDns = true
            manager.loadFromPreferences { _ in
                manager.removeFromPreferences { err in
                    DispatchQueue.main.async {
                        self.isInstallingDns = false
                        if err == nil {
                            self.isDnsActive = false
                            self.isDnsInstalled = false
                        }
                    }
                }
            }
        }
    }

    private func installDnsProfile() {
        isInstallingDns = true
        let manager = NEDNSSettingsManager.shared()
        manager.loadFromPreferences { loadError in
            manager.localizedDescription = MeoCore.dnsDisplayName()

            let dohSettings = NEDNSOverHTTPSSettings(servers: MeoCore.dnsBootstrapServers())
            if let serverURL = URL(string: MeoCore.dohServerURL()) {
                dohSettings.serverURL = serverURL
            }
            manager.dnsSettings = dohSettings

            manager.saveToPreferences { saveError in
                DispatchQueue.main.async {
                    self.isInstallingDns = false
                    if let saveError = saveError {
                        let nsErr = saveError as NSError
                        if nsErr.domain == "NEConfigurationErrorDomain" || nsErr.code == 10 || nsErr.code == 1 {
                            self.activeAlert = ActiveAlertItem(
                                title: "Cài Đặt MeoMeoExt-FF DNS",
                                message: "Hệ thống cần xác nhận hồ sơ cấu hình MeoMeoExt-FF DNS. Bạn có muốn mở để hoàn tất cài đặt không?",
                                isDestructive: false,
                                action: {
                                    if let url = URL(string: MeoCore.dnsPayloadURL()) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                            )
                        } else {
                            self.activeAlert = ActiveAlertItem(
                                title: "Thông Báo Cài Đặt DNS",
                                message: saveError.localizedDescription,
                                isDestructive: false,
                                action: nil
                            )
                        }
                    } else {
                        self.isDnsInstalled = true
                        self.isDnsActive = manager.isEnabled
                        self.activeAlert = ActiveAlertItem(
                            title: "Cài Đặt MeoMeoExt-FF DNS Thành Công",
                            message: "Đã thêm MeoMeoExt-FF DNS với icon ứng dụng vào Cài Đặt. Hãy vào Cài Đặt để chọn MeoMeoExt-FF DNS!",
                            isDestructive: false,
                            action: {
                                self.openIosSettings()
                            }
                        )
                    }
                }
            }
        }
    }

    private func openIosSettings() {
        let settingsCandidates = [
            "App-prefs:General&path=ManagedConfigurationList",
            "App-prefs:root=General&path=ManagedConfigurationList",
            "App-prefs:root=General&path=VPN",
            UIApplication.openSettingsURLString
        ]
        for candidate in settingsCandidates {
            if let url = URL(string: candidate), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return
            }
        }
        if let openSettings = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(openSettings, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Reusable UI Components (Đen Trắng)
struct CardView<Content: View>: View {
    var title: String
    var icon: String
    var content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1.0)
            }
            content
        }
        .padding(16)
        .background(Color(white: 0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(white: 0.22), lineWidth: 1)
        )
    }
}

struct ToggleRow: View {
    var label: String
    var icon: String
    @Binding var on: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(on ? .white : Color(white: 0.55))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Toggle("", isOn: $on).toggleStyle(SlimToggleStyle()).labelsHidden()
        }
    }
}

struct SliderRow: View {
    var label: String
    @Binding var value: Float
    var range: ClosedRange<Float>
    var isPercent: Bool
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(white: 0.70))
                Spacer()
                Text(isPercent ? "\(Int(value))%" : "\(Int(value))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Slider(value: $value, in: range, step: 1)
                .accentColor(.white)
        }
    }
}
