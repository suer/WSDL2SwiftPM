import Foundation
import PackagePlugin

@main
struct WSDL2SwiftPMPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let tool = try context.tool(named: "WSDL2SwiftPMCLI").path
        let outputDir = context.pluginWorkDirectory

        let configPaths: [Path] = [target.directory, context.package.directory]
            .map { $0.appending("wsdl2swift.json") }

        if let configPath = configPaths.first(where: { FileManager.default.fileExists(atPath: $0.string) }) {
            let variables: [String: String] = [
                "PROJECT_DIR": context.package.directory.string,
                "TARGET_NAME": target.name,
                "PRODUCT_MODULE_NAME": target.moduleName,
                "DERIVED_SOURCES_DIR": outputDir.string,
            ]
            return makeCommandsFromConfig(configPath: configPath, outputDir: outputDir, tool: tool, variables: variables)
        }

        let inputFiles = wsdlFiles(in: URL(fileURLWithPath: target.directory.string))
        return makeCommands(inputFiles: inputFiles, outputDir: outputDir, tool: tool, publicMemberwiseInit: true)
    }
}

private struct WSDLPluginConfig: Codable {
    var inputs: [String]?
    var outputDir: String?
    var publicMemberwiseInit: Bool?
}

private func parseConfig(from path: Path) -> WSDLPluginConfig? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path.string)) else { return nil }
    return try? JSONDecoder().decode(WSDLPluginConfig.self, from: data)
}

private func expandVariables(_ string: String, variables: [String: String]) -> String {
    var result = string
    for (key, value) in variables {
        result = result.replacingOccurrences(of: "${\(key)}", with: value)
    }
    return result
}

private func makeCommandsFromConfig(configPath: Path, outputDir: Path, tool: Path, variables: [String: String]) -> [Command] {
    guard let config = parseConfig(from: configPath) else { return [] }

    let configDir = URL(fileURLWithPath: configPath.string).deletingLastPathComponent()

    let inputFiles: [URL]
    if let configInputs = config.inputs {
        inputFiles = configInputs
            .map { configDir.appendingPathComponent(expandVariables($0, variables: variables)) }
            .sorted { $0.path < $1.path }
    } else {
        inputFiles = wsdlFiles(in: configDir)
    }

    let resolvedOutputDir: Path
    if let outputDirStr = config.outputDir {
        resolvedOutputDir = Path(expandVariables(outputDirStr, variables: variables))
    } else {
        resolvedOutputDir = outputDir
    }

    return makeCommands(inputFiles: inputFiles, outputDir: resolvedOutputDir, tool: tool, publicMemberwiseInit: config.publicMemberwiseInit ?? true)
}

private func wsdlFiles(in directory: URL) -> [URL] {
    return ((try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
    )) ?? [])
    .filter { ["wsdl", "xsd"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.path < $1.path }
}

private func serviceNames(from files: [URL]) -> [String] {
    return files
        .flatMap { url -> [String] in
            guard
                let data = try? Data(contentsOf: url),
                let doc = try? XMLDocument(data: data),
                let root = doc.rootElement(),
                root.localName == "definitions"
            else { return [] }

            return root.children?
                .compactMap { $0 as? XMLElement }
                .filter { $0.localName == "service" }
                .compactMap { $0.attribute(forName: "name")?.stringValue }
                ?? []
        }
}

private func makeCommands(inputFiles: [URL], outputDir: Path, tool: Path, publicMemberwiseInit: Bool) -> [Command] {
    guard !inputFiles.isEmpty else { return [] }

    let names = serviceNames(from: inputFiles)
    guard !names.isEmpty else { return [] }

    let outputFiles = names.map { outputDir.appending("WSDL+\($0).swift") }

    var arguments = ["--out", outputDir.appending("WSDL.swift").string]
    if publicMemberwiseInit {
        arguments.append("--public-memberwise-init")
    }
    arguments += inputFiles.map(\.path)

    return [
        .buildCommand(
            displayName: "Generate Swift from WSDL",
            executable: tool,
            arguments: arguments,
            inputFiles: inputFiles.map { Path($0.path) },
            outputFiles: outputFiles
        )
    ]
}
