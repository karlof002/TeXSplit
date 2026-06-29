# TeXSplit

TeXSplit ist ein nativer LaTeX-Editor fuer macOS. Die App kombiniert einen schnellen `NSTextView`-Codeeditor mit Zeilennummern, Syntax-Highlighting, Tabs und einer PDFKit-Vorschau fuer kompiliertes LaTeX.

## Was die App macht

- `.tex`-Dateien oeffnen, bearbeiten, speichern und speichern unter
- Mehrere Dokumente in Tabs verwalten
- LaTeX manuell oder automatisch kompilieren
- PDF-Vorschau direkt neben dem Editor anzeigen
- Compiler-Ausgabe und erkannte LaTeX-Fehler anzeigen
- Editor-Themes wie System, Xcode Light, Xcode Dark und Solarized Dark nutzen
- Zeilen- und Spaltenposition in der Statusleiste anzeigen

## Status

TeXSplit ist eine lokale macOS-Entwickler-App. Der Editor, Tabs, Syntax-Highlighting, Theme-Wechsel, Dateioperationen, PDF-Vorschau und automatische Kompilierung sind implementiert. Fuer die LaTeX-Kompilierung wird ein vorhandenes MacTeX/BasicTeX verwendet oder optional eine vorbereitete TeXLive-Runtime im App-Bundle.

## Voraussetzungen

- macOS 14 oder neuer
- Xcode 15 oder neuer
- Fuer lokale Entwicklerbuilds: MacTeX oder BasicTeX, falls keine Runtime im Bundle liegt

TeXSplit sucht zuerst im App-Bundle nach einem eingebetteten Compiler:

```text
TeXSplit.app/Contents/Resources/TeXLive/bin/universal-darwin/pdflatex
TeXSplit.app/Contents/Resources/TeXLive/2026basic/bin/universal-darwin/pdflatex
TeXSplit.app/Contents/Resources/TeXLive/2026/bin/universal-darwin/pdflatex
```

Wenn dort kein Compiler liegt, sucht die App fuer Entwicklerbuilds nach:

```sh
/Library/TeX/texbin/pdflatex
```

Danach wird `pdflatex` ueber `/usr/bin/env pdflatex` versucht, wenn eine lokale Installation im Suchpfad liegt.

## Starten

1. `TeXSplit.xcodeproj` in Xcode oeffnen.
2. Scheme `TeXSplit` auswaehlen.
3. Run druecken.

Alternativ:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./script/build_and_run.sh
```

## Tests

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project TeXSplit.xcodeproj -scheme TeXSplit -derivedDataPath DerivedData -destination 'platform=macOS,arch=arm64'
```

## Projektstruktur

- `TeXSplit/App`: App-Einstieg und native Menuebefehle
- `TeXSplit/Models`: Dokument-, Theme-, Tab- und Statusmodelle
- `TeXSplit/ViewModels`: Editor- und Workspace-Logik
- `TeXSplit/Views`: SwiftUI-Oberflaeche, AppKit-Editor und PDFKit-Vorschau
- `TeXSplit/Services`: Dateioperationen, Compilerstart, Fehlerparser, Syntax-Highlighting und Themes
- `TeXSplitTests`: Unit-Tests fuer Editor, Compiler, Parser, Tabs und Einstellungen

## TeXLive-Runtime

Der grosse TeXLive-Runtime-Ordner wird bewusst nicht ins Repository committed. Im Repository bleibt nur `TeXSplit/Resources/TeXLive/README.md`. Fuer lokale Tests oder Distributionsbuilds kann die Runtime separat vorbereitet werden:

```sh
./script/embed_basictex_runtime.sh
```

Das Skript laedt BasicTeX/TeXLive, extrahiert die Runtime und legt sie lokal unter `TeXSplit/Resources/TeXLive` ab. Dieser Ordner ist in `.gitignore` ausgeschlossen.

## Architektur

Die App ist in SwiftUI gebaut und nutzt AppKit gezielt dort, wo macOS-Editorverhalten wichtig ist. Der Codeeditor basiert auf `NSTextView`, damit Auswahl, Copy/Cut/Paste, Undo/Redo, Cursorbewegung, Zeilennummern und Syntax-Highlighting nativ funktionieren.

## Bekannte Einschraenkungen

- Keine Projektordner-Verwaltung fuer groessere Multi-File-LaTeX-Projekte
- Noch keine BibTeX/Biber-Pipeline
- Noch keine Forward/Inverse Search zwischen PDF und Quelle
