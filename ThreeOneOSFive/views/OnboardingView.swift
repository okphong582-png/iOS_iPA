import SwiftUI

private enum OnboardingStep: Int, CaseIterable {
    case welcome = 0

    var next: OnboardingStep? { nil }
    var prev: OnboardingStep? { nil }
}

private enum OnboardingNavigationDirection {
    case forward
    case backward
}

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.english.rawValue
    @State private var step: OnboardingStep = .welcome
    @State private var navigationDirection: OnboardingNavigationDirection = .forward
    var onComplete: () -> Void

    private var language: AppLanguage { AppLanguage(rawValue: languageCode) ?? .english }
    private var motionAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.24)
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                pageContent
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            controls
        }
        .tint(AppTheme.accent)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "pawprint.fill")
                .foregroundColor(.white)
                .font(.system(size: 18))
            Text("MeoMeo")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    @ViewBuilder
    private var pageContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            welcomePage
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private func page(for s: OnboardingStep) -> some View {
        welcomePage
    }

    private var languagePage: some View {
        VStack(spacing: 24) {
            AppLogo(size: 72)

            VStack(spacing: 8) {
                Text(language.text("onboarding.language_title"))
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text("onboarding.language_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { option in
                    let isSelected = languageCode == option.rawValue
                    Button {
                        languageCode = option.rawValue
                    } label: {
                        HStack(spacing: 12) {
                            Text(option.displayName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                                    .font(.title3)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected ? AppTheme.accent : Color.secondary.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .animation(motionAnimation, value: languageCode)
                }
            }

            Text(language.text("onboarding.language_hint", language.displayName))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.12))
                    .frame(width: 92, height: 92)
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                Text("MeoMeo")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Free Fire VIP Mod Launcher")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(white: 0.70))
                Text("Phiên bản iOS: \(UIDevice.current.systemVersion) (\(UIDevice.current.model))")
                    .font(.caption.monospaced())
                    .foregroundColor(Color(white: 0.45))
            }

            VStack(spacing: 12) {
                welcomeFeatureRow(icon: "eye.fill", title: "ESP Người Chơi", subtitle: "Hiện Box, Khung Xương, Tên, Máu & Khoảng Cách")
                welcomeFeatureRow(icon: "scope", title: "Aimbot Chuẩn Xác", subtitle: "Tâm ngắm mượt mà, hỗ trợ Headshot")
                welcomeFeatureRow(icon: "bolt.shield.fill", title: "Bảo Mật Tối Ưu", subtitle: "Tự động đồng bộ cấu hình an toàn")
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func welcomeFeatureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(white: 0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.65))
            }
            Spacer()
        }
        .padding(14)
        .background(Color(white: 0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(white: 0.22), lineWidth: 1)
        )
    }

    private var versionsPage: some View {
        VStack(spacing: 20) {
            featureIcon(systemName: "iphone.gen2", color: AppTheme.accent)

            VStack(spacing: 8) {
                Text(language.text("onboarding.versions_title"))
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text("onboarding.versions_subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                versionRow(icon: "checkmark.circle.fill", title: "iOS 17", value: ExploitSupportPolicy.verifiedIOS17Range, color: .green)
                versionRow(icon: "checkmark.circle.fill", title: "iOS 18", value: ExploitSupportPolicy.verifiedIOS18Range, color: .green)
                versionRow(icon: "checkmark.circle.fill", title: "iOS 26", value: ExploitSupportPolicy.verifiedIOS26Range, color: .green)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("iOS 27.0").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(language.text("onboarding.beta")).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    }
                    ForEach(ExploitSupportPolicy.verifiedIOS27Builds, id: \.build) { v in
                        let betaLabel = language.text("onboarding.developer_beta", "\(v.beta)")
                            + (v.publicBeta.map {
                                " · " + language.text("onboarding.public_beta", "\($0)")
                            } ?? "")
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                Text(betaLabel)
                                Spacer()
                                Text(v.build)
                                    .font(.caption.monospaced().weight(.medium))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(betaLabel)
                                Text(v.build)
                                    .font(.caption.monospaced().weight(.medium))
                            }
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                    }
                }
                .padding(12)
                .background(
                    Color(uiColor: .secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            }

            Text(language.text("onboarding.versions_footer", AppInfo.osVersion, AppInfo.osBuild))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var installPage: some View {
        VStack(spacing: 20) {
            featureIcon(systemName: "exclamationmark.shield.fill", color: .orange)

            VStack(spacing: 8) {
                Text(language.text("onboarding.install_title"))
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(language.text("onboarding.install_message"))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                installBullet(icon: "checkmark.seal.fill", text: language.text("onboarding.install_ok"), color: .green)
                installBullet(icon: "xmark.octagon.fill", text: language.text("onboarding.install_bad"), color: .red)
                installBullet(icon: "exclamationmark.triangle.fill", text: language.text("onboarding.install_jailbreak"), color: .orange)
            }
            .padding(14)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )

            Text(language.text("onboarding.install_footer"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func featureIcon(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }

    private func versionRow(icon: String, title: String, value: String, color: Color) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).fontWeight(.semibold)
                Spacer()
                Text(value)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Text(value)
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.leading, 26)
            }
        }
        .font(.subheadline)
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func installBullet(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.body.weight(.semibold))
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                onComplete()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pawprint.fill")
                    Text("TIẾP TỤC VÀO MENU")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(Color.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 20)
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
}

enum OnboardingStore {
    static let completedVersionKey = "onboarding.completedVersion"
    static let completedFingerprintKey = "onboarding.completedFingerprint"

    static var currentVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(v) (\(b))"
    }

    /// Per-install token: executable mtime changes on every overwrite even if version stays the same.
    static var bundleToken: String {
        if let exe = Bundle.main.executablePath,
           let attrs = try? FileManager.default.attributesOfItem(atPath: exe),
           let date = attrs[.modificationDate] as? Date {
            return String(Int(date.timeIntervalSince1970))
        }
        if let attrs = try? FileManager.default.attributesOfItem(atPath: Bundle.main.bundlePath),
           let date = (attrs[.creationDate] as? Date) ?? (attrs[.modificationDate] as? Date) {
            return String(Int(date.timeIntervalSince1970))
        }
        return "0"
    }

    static var currentFingerprint: String { "\(currentVersion)#\(bundleToken)" }

    static var completedVersion: String? {
        UserDefaults.standard.string(forKey: completedVersionKey)
    }

    static var completedFingerprint: String? {
        UserDefaults.standard.string(forKey: completedFingerprintKey)
    }

    static func shouldShow() -> Bool {
#if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--skip-onboarding") { return false }
        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding") { return true }
#endif
        let fp = currentFingerprint
        if let stored = completedFingerprint, !stored.isEmpty {
            return stored != fp
        }
        // Migration: old installs only have completedVersion
        if let completed = completedVersion, !completed.isEmpty {
            if completed == currentVersion {
                // Same version, migrate silently — next overwrite will be detected via fingerprint
                UserDefaults.standard.set(fp, forKey: completedFingerprintKey)
                return false
            }
            return true
        }
        return true
    }

    static func markCompleted() {
        UserDefaults.standard.set(currentVersion, forKey: completedVersionKey)
        UserDefaults.standard.set(currentFingerprint, forKey: completedFingerprintKey)
    }
}
