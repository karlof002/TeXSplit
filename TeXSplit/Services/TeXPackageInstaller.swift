import AppKit
import Foundation

enum TeXPackageInstallerError: LocalizedError, Equatable {
    case invalidPackageName
    case tlmgrNotFound
    case installationFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPackageName:
            "Der Paketname ist ungültig und wurde nicht installiert."
        case .tlmgrNotFound:
            "TeX Live Manager wurde nicht gefunden. Bitte installiere MacTeX oder BasicTeX."
        case .installationFailed(let message):
            "LaTeX-Paket konnte nicht installiert werden: \(message)"
        }
    }
}

protocol TeXPackageInstalling: Sendable {
    func install(packageName: String) async throws -> String
}

struct TeXPackageInstaller: TeXPackageInstalling {
    private let fileExists: @Sendable (String) -> Bool
    private let appleScriptExecutor: @Sendable (String) async throws -> String

    init(
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) },
        appleScriptExecutor: @escaping @Sendable (String) async throws -> String = { command in
            try await TeXPackageInstaller.runAppleScript(command)
        }
    ) {
        self.fileExists = fileExists
        self.appleScriptExecutor = appleScriptExecutor
    }

    func install(packageName: String) async throws -> String {
        guard isValidPackageName(packageName) else {
            throw TeXPackageInstallerError.invalidPackageName
        }

        let tlmgrPath = resolveTlmgrPath()
        guard let tlmgrPath else {
            throw TeXPackageInstallerError.tlmgrNotFound
        }

        let installCommand = "\(tlmgrPath) install \(packageName)"

        do {
            return try await appleScriptExecutor(installCommand)
        } catch let error as TeXPackageInstallerError {
            guard case .installationFailed(let message) = error, requiresTlmgrSelfUpdate(message) else {
                throw error
            }

            let updateOutput = try await appleScriptExecutor("\(tlmgrPath) update --self")
            let installOutput = try await appleScriptExecutor(installCommand)
            return """
            TeX Live Manager wurde aktualisiert.
            \(updateOutput)

            Paket "\(packageName)" wurde installiert.
            \(installOutput)
            """
        }
    }

    private func resolveTlmgrPath() -> String? {
        let paths = [
            "/Library/TeX/texbin/tlmgr",
            "/usr/local/texlive/2026/bin/universal-darwin/tlmgr",
            "/usr/local/texlive/2025/bin/universal-darwin/tlmgr",
            "/usr/local/bin/tlmgr",
            "/opt/homebrew/bin/tlmgr"
        ]
        return paths.first(where: fileExists)
    }

    private func isValidPackageName(_ packageName: String) -> Bool {
        packageName.range(of: #"^[A-Za-z0-9][A-Za-z0-9_.+-]*$"#, options: .regularExpression) != nil
    }

    private func requiresTlmgrSelfUpdate(_ message: String) -> Bool {
        message.localizedCaseInsensitiveContains("tlmgr itself needs to be updated")
            || message.localizedCaseInsensitiveContains("tlmgr update --self")
    }

    private static func runAppleScript(_ command: String) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let escapedCommand = command
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            let source = #"do shell script "\#(escapedCommand)" with administrator privileges"#

            var errorInfo: NSDictionary?
            guard let script = NSAppleScript(source: source) else {
                throw TeXPackageInstallerError.installationFailed("AppleScript konnte nicht erstellt werden.")
            }

            let result = script.executeAndReturnError(&errorInfo)
            if let errorInfo {
                let message = errorInfo[NSAppleScript.errorMessage] as? String
                    ?? errorInfo.description
                throw TeXPackageInstallerError.installationFailed(message)
            }

            return result.stringValue ?? "Paket wurde installiert."
        }.value
    }
}
