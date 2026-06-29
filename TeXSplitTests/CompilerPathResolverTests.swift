import XCTest
@testable import TeXSplit

final class CompilerPathResolverTests: XCTestCase {
    func testPrefersBundledCompilerPath() {
        let resourceURL = URL(fileURLWithPath: "/App/TeXSplit.app/Contents/Resources")
        let bundledPath = "/App/TeXSplit.app/Contents/Resources/TeXLive/2026basic/bin/universal-darwin/pdflatex"
        let resolver = CompilerPathResolver(
            fileExists: { $0 == bundledPath || $0 == "/Library/TeX/texbin/pdflatex" },
            bundledResourceURL: { resourceURL }
        )

        XCTAssertEqual(resolver.resolve().path, bundledPath)
    }

    func testPrefersMacTeXCompilerPath() {
        let resolver = CompilerPathResolver(
            fileExists: { path in path == "/Library/TeX/texbin/pdflatex" },
            bundledResourceURL: { nil }
        )

        XCTAssertEqual(resolver.resolve().path, "/Library/TeX/texbin/pdflatex")
    }

    func testFallsBackToEnvironmentLauncher() {
        let resolver = CompilerPathResolver(fileExists: { _ in false }, bundledResourceURL: { nil })

        XCTAssertEqual(resolver.resolve().path, "/usr/bin/env")
    }
}
