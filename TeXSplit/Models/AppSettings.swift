import AppKit
import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var autoPreviewEnabledByDefault: Bool {
        didSet { defaults.set(autoPreviewEnabledByDefault, forKey: Keys.autoPreviewEnabledByDefault) }
    }
    @Published var autoCompileDelayMilliseconds: Int {
        didSet { defaults.set(autoCompileDelayMilliseconds, forKey: Keys.autoCompileDelayMilliseconds) }
    }
    @Published var restoreLastSession: Bool {
        didSet { defaults.set(restoreLastSession, forKey: Keys.restoreLastSession) }
    }
    @Published var useDefaultTemplate: Bool {
        didSet { defaults.set(useDefaultTemplate, forKey: Keys.useDefaultTemplate) }
    }
    @Published var confirmUnsavedClose: Bool {
        didSet { defaults.set(confirmUnsavedClose, forKey: Keys.confirmUnsavedClose) }
    }
    @Published var editorFontName: String {
        didSet { defaults.set(editorFontName, forKey: Keys.editorFontName) }
    }
    @Published var editorFontSize: Double {
        didSet { defaults.set(editorFontSize, forKey: Keys.editorFontSize) }
    }
    @Published var tabWidth: Int {
        didSet { defaults.set(tabWidth, forKey: Keys.tabWidth) }
    }
    @Published var showsLineNumbers: Bool {
        didSet { defaults.set(showsLineNumbers, forKey: Keys.showsLineNumbers) }
    }
    @Published var highlightsCurrentLine: Bool {
        didSet { defaults.set(highlightsCurrentLine, forKey: Keys.highlightsCurrentLine) }
    }
    @Published var wrapsLines: Bool {
        didSet { defaults.set(wrapsLines, forKey: Keys.wrapsLines) }
    }
    @Published var syntaxHighlightingEnabled: Bool {
        didSet { defaults.set(syntaxHighlightingEnabled, forKey: Keys.syntaxHighlightingEnabled) }
    }
    @Published var autoCloseBrackets: Bool {
        didSet { defaults.set(autoCloseBrackets, forKey: Keys.autoCloseBrackets) }
    }
    @Published var spellCheckingEnabled: Bool {
        didSet { defaults.set(spellCheckingEnabled, forKey: Keys.spellCheckingEnabled) }
    }
    @Published var insertsSpacesForTabs: Bool {
        didSet { defaults.set(insertsSpacesForTabs, forKey: Keys.insertsSpacesForTabs) }
    }
    @Published var appAppearance: AppAppearance {
        didSet { defaults.set(appAppearance.rawValue, forKey: Keys.appAppearance) }
    }
    @Published var editorThemeID: EditorTheme.ID {
        didSet { defaults.set(editorThemeID.rawValue, forKey: Keys.editorThemeID) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.autoPreviewEnabledByDefault: true,
            Keys.autoCompileDelayMilliseconds: 600,
            Keys.restoreLastSession: true,
            Keys.useDefaultTemplate: true,
            Keys.confirmUnsavedClose: true,
            Keys.editorFontName: "Menlo",
            Keys.editorFontSize: 14.0,
            Keys.tabWidth: 4,
            Keys.showsLineNumbers: true,
            Keys.highlightsCurrentLine: true,
            Keys.wrapsLines: false,
            Keys.syntaxHighlightingEnabled: true,
            Keys.autoCloseBrackets: false,
            Keys.spellCheckingEnabled: false,
            Keys.insertsSpacesForTabs: true,
            Keys.appAppearance: AppAppearance.system.rawValue,
            Keys.editorThemeID: EditorTheme.ID.system.rawValue
        ])

        autoPreviewEnabledByDefault = defaults.bool(forKey: Keys.autoPreviewEnabledByDefault)
        autoCompileDelayMilliseconds = defaults.integer(forKey: Keys.autoCompileDelayMilliseconds)
        restoreLastSession = defaults.bool(forKey: Keys.restoreLastSession)
        useDefaultTemplate = defaults.bool(forKey: Keys.useDefaultTemplate)
        confirmUnsavedClose = defaults.bool(forKey: Keys.confirmUnsavedClose)
        editorFontName = defaults.string(forKey: Keys.editorFontName) ?? "Menlo"
        editorFontSize = defaults.double(forKey: Keys.editorFontSize)
        tabWidth = defaults.integer(forKey: Keys.tabWidth)
        showsLineNumbers = defaults.bool(forKey: Keys.showsLineNumbers)
        highlightsCurrentLine = defaults.bool(forKey: Keys.highlightsCurrentLine)
        wrapsLines = defaults.bool(forKey: Keys.wrapsLines)
        syntaxHighlightingEnabled = defaults.bool(forKey: Keys.syntaxHighlightingEnabled)
        autoCloseBrackets = defaults.bool(forKey: Keys.autoCloseBrackets)
        spellCheckingEnabled = defaults.bool(forKey: Keys.spellCheckingEnabled)
        insertsSpacesForTabs = defaults.bool(forKey: Keys.insertsSpacesForTabs)
        appAppearance = AppAppearance(rawValue: defaults.string(forKey: Keys.appAppearance) ?? "") ?? .system
        editorThemeID = EditorTheme.ID(rawValue: defaults.string(forKey: Keys.editorThemeID) ?? "") ?? .system
    }

    var autoCompileDelayNanoseconds: UInt64 {
        UInt64(autoCompileDelayMilliseconds) * 1_000_000
    }

    var editorFont: NSFont {
        NSFont(name: editorFontName, size: editorFontSize) ?? .monospacedSystemFont(ofSize: editorFontSize, weight: .regular)
    }

    var selectedTheme: EditorTheme {
        EditorThemeProvider.theme(for: editorThemeID, appearance: NSApplication.shared.effectiveAppearance)
    }

    var preferredColorScheme: NSAppearance.Name? {
        switch appAppearance {
        case .system: nil
        case .light: .aqua
        case .dark: .darkAqua
        }
    }

    enum Keys {
        static let autoPreviewEnabledByDefault = "autoPreviewEnabledByDefault"
        static let autoCompileDelayMilliseconds = "autoCompileDelayMilliseconds"
        static let restoreLastSession = "restoreLastSession"
        static let useDefaultTemplate = "useDefaultTemplate"
        static let confirmUnsavedClose = "confirmUnsavedClose"
        static let editorFontName = "editorFontName"
        static let editorFontSize = "editorFontSize"
        static let tabWidth = "tabWidth"
        static let showsLineNumbers = "showsLineNumbers"
        static let highlightsCurrentLine = "highlightsCurrentLine"
        static let wrapsLines = "wrapsLines"
        static let syntaxHighlightingEnabled = "syntaxHighlightingEnabled"
        static let autoCloseBrackets = "autoCloseBrackets"
        static let spellCheckingEnabled = "spellCheckingEnabled"
        static let insertsSpacesForTabs = "insertsSpacesForTabs"
        static let appAppearance = "appAppearance"
        static let editorThemeID = "editorThemeID"
    }
}
