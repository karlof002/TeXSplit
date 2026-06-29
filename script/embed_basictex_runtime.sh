#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${ROOT_DIR}/.texsplit-runtime-build"
PKG_URL="${BASICTEX_PKG_URL:-https://mirror.ctan.org/systems/mac/mactex/BasicTeX.pkg}"
PKG_PATH="${WORK_DIR}/BasicTeX.pkg"
EXPANDED_DIR="${WORK_DIR}/expanded"
PAYLOAD_ROOT="${WORK_DIR}/payload"
DEST_DIR="${ROOT_DIR}/TeXSplit/Resources/TeXLive"

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}" "${DEST_DIR}"

echo "Downloading BasicTeX runtime..."
/usr/bin/curl --fail --location --progress-bar "${PKG_URL}" --output "${PKG_PATH}"

echo "Expanding package..."
/usr/sbin/pkgutil --expand-full "${PKG_PATH}" "${EXPANDED_DIR}"

SOURCE_DIR="$(/usr/bin/find "${EXPANDED_DIR}" -path '*/usr/local/texlive/*basic/bin/universal-darwin/pdflatex' -print -quit | /usr/bin/sed 's#/bin/universal-darwin/pdflatex##')"

if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then
  echo "Could not find a BasicTeX runtime in the expanded package." >&2
  exit 1
fi

RUNTIME_NAME="$(/usr/bin/basename "${SOURCE_DIR}")"
TARGET_DIR="${DEST_DIR}/${RUNTIME_NAME}"

echo "Embedding ${RUNTIME_NAME} into ${DEST_DIR}..."
rm -rf "${TARGET_DIR}"
/bin/cp -R "${SOURCE_DIR}" "${TARGET_DIR}"

PDFLATEX="${TARGET_DIR}/bin/universal-darwin/pdflatex"
if [[ ! -x "${PDFLATEX}" ]]; then
  /bin/chmod +x "${PDFLATEX}" || true
fi

echo "Embedded compiler:"
"${PDFLATEX}" --version | /usr/bin/head -n 1

rm -rf "${WORK_DIR}"
echo "Done. Rebuild TeXSplit in Xcode."
