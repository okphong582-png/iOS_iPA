import Foundation

/// Reads the template first, then preserves every existing game key.
enum GameConfigFile {
    static let configName = "localConfig.json"
    static let patchName = "Assembly-CSharp-patch.bytes"

    static func read(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "GameConfig", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "localConfig.json không phải JSON object hợp lệ."
            ])
        }
        return object
    }

    static func load(documents: URL, template: URL) throws -> [String: Any] {
        var config = try read(template)
        let target = documents.appendingPathComponent(configName)
        if FileManager.default.fileExists(atPath: target.path) {
            config.merge(try read(target)) { _, existing in existing }
        }
        return config
    }

    static func save(_ settings: [String: Any], documents: URL, template: URL) throws {
        var config = try load(documents: documents, template: template)
        config.merge(settings) { _, updated in updated }
        let data = try JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted, .sortedKeys])
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        try data.write(to: documents.appendingPathComponent(configName), options: .atomic)
    }

    static func install(_ settings: [String: Any], documents: URL, template: URL, patch: URL) throws {
        // Validate both inputs before changing the target.
        _ = try load(documents: documents, template: template)
        let patchData = try Data(contentsOf: patch)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        try patchData.write(to: documents.appendingPathComponent(patchName), options: .atomic)
        try save(settings, documents: documents, template: template)
    }

    static func isInstalled(documents: URL) -> Bool {
        [patchName, configName].allSatisfy {
            FileManager.default.fileExists(atPath: documents.appendingPathComponent($0).path)
        }
    }
}

#if !GAME_CONFIG_TESTS
enum GameConfigService {
    static func withDocuments<T>(bundleID: String, operation: (URL) throws -> T) throws -> T {
        guard ["com.dts.freefireth", "com.dts.freefiremax"].contains(bundleID),
              let path = ContainerStore.resolveAppContainerPath(bundleID: bundleID),
              ContainerStore.isApplicationContainerPath(path) else {
            throw NSError(domain: "GameConfig", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Không tìm thấy thư mục dữ liệu của \(bundleID). Kiểm tra game và quyền truy cập."
            ])
        }
        let handle = ContainerStore.grantContainerAccess(path)
        defer { if handle >= 0 { bad_query_release(handle) } }
        return try operation(URL(fileURLWithPath: path, isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true))
    }

    static func resource(_ name: String, fileExtension ext: String) throws -> URL {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            throw NSError(domain: "GameConfig", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Thiếu file \(name).\(ext) trong ứng dụng."
            ])
        }
        return url
    }
}
#endif
