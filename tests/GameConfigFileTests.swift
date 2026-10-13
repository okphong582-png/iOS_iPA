import Foundation
import CoreFoundation

@main
struct GameConfigFileTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let documents = root.appendingPathComponent("Documents")
        let template = URL(fileURLWithPath: "ThreeOneOSFive/localConfig.json")
        let patch = URL(fileURLWithPath: "ThreeOneOSFive/Assembly-CSharp-patch.bytes")
        try GameConfigFile.install([:], documents: documents, template: template, patch: patch)
        precondition(GameConfigFile.isInstalled(documents: documents))
        let expectedPatch = try Data(contentsOf: patch)
        let installedPatch = try Data(contentsOf: documents.appendingPathComponent(GameConfigFile.patchName))
        precondition(expectedPatch == installedPatch)
        let baseline = try GameConfigFile.read(template)
        var existing = baseline
        existing["token"] = "preserved-token"
        existing["sig"] = "preserved-signature"
        existing["future_setting"] = ["value": 123]
        let target = documents.appendingPathComponent(GameConfigFile.configName)
        try JSONSerialization.data(withJSONObject: existing).write(to: target)
        let keys = ["AimSystemEnabled", "EspTracer", "NoRecoil", "EspLine", "testCodePatch",
            "EspSkeleton", "EspBox", "EspMaster", "EspName", "EspDistance", "EspFov", "EspHealth",
            "system_active", "AimEnabled"]
        for key in keys {
            for enabled in [true, false] {
                try GameConfigFile.save([key: enabled], documents: documents, template: template)
                let result = try GameConfigFile.read(target)
                let number = result[key] as! NSNumber
                precondition(CFGetTypeID(number) == CFBooleanGetTypeID())
                precondition(number.boolValue == enabled)
                precondition(result["token"] as? String == "preserved-token")
                precondition(result["sig"] as? String == "preserved-signature")
                precondition((result["future_setting"] as? [String: Int])?["value"] == 123)
                for serverKey in baseline.keys.filter({ $0.hasPrefix("server_") }) {
                    precondition(result[serverKey] as? Bool == true)
                }
            }
        }
        try GameConfigFile.save(["AimTarget": 2, "FovSize": 100, "HeadshotRate": 75], documents: documents, template: template)
        let numeric = try GameConfigFile.read(target)
        precondition((numeric["AimTarget"] as? NSNumber)?.intValue == 2)
        precondition((numeric["FovSize"] as? NSNumber)?.intValue == 100)
        precondition((numeric["HeadshotRate"] as? NSNumber)?.intValue == 75)
        // Installing again preserves existing settings rather than resetting them.
        try GameConfigFile.install([:], documents: documents, template: template, patch: patch)
        let reinstalled = try GameConfigFile.read(target)
        precondition(reinstalled["token"] as? String == "preserved-token")
        let broken = Data("{broken".utf8)
        try broken.write(to: target)
        do {
            try GameConfigFile.save(["EspBox": true], documents: documents, template: template)
            fatalError("Malformed config must not be overwritten")
        } catch {
            let unchanged = try Data(contentsOf: target)
            precondition(unchanged == broken)
        }
        print("GameConfigFile tests passed")
    }
}
