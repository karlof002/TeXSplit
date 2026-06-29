import XCTest
@testable import TeXSplit

final class TeXPackageInstallerTests: XCTestCase {
    func testUpdatesTlmgrAndRetriesInstallWhenTlmgrIsOutdated() async throws {
        let recorder = PackageCommandRecorder()
        let installer = TeXPackageInstaller(
            fileExists: { $0 == "/Library/TeX/texbin/tlmgr" },
            appleScriptExecutor: { command in
                try await recorder.execute(command: command)
            }
        )

        let output = try await installer.install(packageName: "enumitem")
        let commands = await recorder.recordedCommands()

        XCTAssertEqual(commands, [
            "/Library/TeX/texbin/tlmgr install enumitem",
            "/Library/TeX/texbin/tlmgr update --self",
            "/Library/TeX/texbin/tlmgr install enumitem"
        ])
        XCTAssertTrue(output.contains("TeX Live Manager wurde aktualisiert."))
    }

    func testRejectsUnsafePackageName() async {
        let installer = TeXPackageInstaller(
            fileExists: { _ in true },
            appleScriptExecutor: { _ in "ok" }
        )

        do {
            _ = try await installer.install(packageName: "enumitem;rm")
            XCTFail("Expected invalidPackageName")
        } catch let error as TeXPackageInstallerError {
            XCTAssertEqual(error, .invalidPackageName)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

actor PackageCommandRecorder {
    private(set) var commands: [String] = []

    func execute(command: String) async throws -> String {
        commands.append(command)
        if commands.count == 1 {
            throw TeXPackageInstallerError.installationFailed("""
            tlmgr itself needs to be updated.
            Please do this via either
              tlmgr update --self
            """)
        }
        return "ok"
    }

    func recordedCommands() -> [String] {
        commands
    }
}
