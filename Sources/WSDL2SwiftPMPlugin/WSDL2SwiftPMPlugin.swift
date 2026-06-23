import Foundation
import PackagePlugin

@main
struct WSDL2SwiftPMPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }

        let inputFiles = wsdlFiles(in: URL(fileURLWithPath: target.directory.string))
        return try makeCommands(
            inputFiles: inputFiles,
            outputDir: context.pluginWorkDirectory,
            tool: context.tool(named: "WSDL2SwiftPMCLI").path
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension WSDL2SwiftPMPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let inputFiles = target.inputFiles
            .filter { ["wsdl", "xsd", "xml"].contains($0.path.extension?.lowercased() ?? "") }
            .map { URL(fileURLWithPath: $0.path.string) }
            .sorted { $0.path < $1.path }
        return try makeCommands(
            inputFiles: inputFiles,
            outputDir: context.pluginWorkDirectory,
            tool: context.tool(named: "WSDL2SwiftPMCLI").path
        )
    }
}
#endif

private func wsdlFiles(in directory: URL) -> [URL] {
    return ((try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
    )) ?? [])
    .filter { ["wsdl", "xsd", "xml"].contains($0.pathExtension.lowercased()) }
    .sorted { $0.path < $1.path }
}

private func serviceNames(from files: [URL]) -> [String] {
    return files
        .filter { ["wsdl", "xml"].contains($0.pathExtension.lowercased()) }
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

private func makeCommands(inputFiles: [URL], outputDir: Path, tool: Path) throws -> [Command] {
    guard !inputFiles.isEmpty else { return [] }

    let names = serviceNames(from: inputFiles)
    guard !names.isEmpty else { return [] }

    let outputFiles = names.map { outputDir.appending("WSDL+\($0).swift") }

    return [
        .buildCommand(
            displayName: "Generate Swift from WSDL",
            executable: tool,
            arguments: ["--out", outputDir.appending("WSDL.swift").string]
                + inputFiles.map(\.path),
            inputFiles: inputFiles.map { Path($0.path) },
            outputFiles: outputFiles
        )
    ]
}
