import re
import json
from pathlib import Path

# ============================================================
# HEALTHHOME SAFE LOCALIZATION TOOL
# ============================================================

ROOT = Path(".")
LIB = ROOT / "lib"
L10N = LIB / "l10n"

EN_FILE = L10N / "en.json"
HI_FILE = L10N / "hi.json"
GU_FILE = L10N / "gu.json"

REPORT_FILE = ROOT / "localization_report.json"

# Files/folders that should NEVER be automatically localized
EXCLUDED_DIRS = {
    "services",
    "models",
    "controllers",
    "utils",
    "generated",
    "l10n",
}

# ============================================================
# LOAD EXISTING JSON
# ============================================================

def load_json(path):
    if path.exists():
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"ERROR reading {path}: {e}")
            return {}

    return {}


en = load_json(EN_FILE)
hi = load_json(HI_FILE)
gu = load_json(GU_FILE)

# ============================================================
# KEY GENERATION
# ============================================================

def make_key(text):
    text = text.strip()

    # Remove interpolation
    clean = re.sub(r"\$\{[^}]+\}", "", text)
    clean = re.sub(r"\$[A-Za-z_]\w*", "", clean)

    # Remove punctuation
    clean = re.sub(r"[^A-Za-z0-9]+", " ", clean)

    words = clean.strip().split()

    if not words:
        return None

    key = words[0].lower()

    for word in words[1:]:
        if word:
            key += word[0].upper() + word[1:].lower()

    # Don't allow a key beginning with number
    if key and key[0].isdigit():
        key = "text" + key

    return key


def unique_key(base, existing):
    if not base:
        return None

    if base not in existing:
        return base

    number = 2

    while f"{base}{number}" in existing:
        number += 1

    return f"{base}{number}"


# ============================================================
# STRINGS WE SHOULD NOT TRANSLATE
# ============================================================

def should_ignore(text):

    text = text.strip()

    if not text:
        return True

    # Already localization key
    if text.startswith("'") or text.startswith('"'):
        pass

    # URLs
    if text.startswith("http://") or text.startswith("https://"):
        return True

    # Email
    if "@" in text and "." in text:
        return True

    # File paths
    if "/" in text and (
        ".png" in text
        or ".jpg" in text
        or ".jpeg" in text
        or ".pdf" in text
        or ".json" in text
    ):
        return True

    # Dart variables / interpolation-only strings
    if re.fullmatch(r"[\$\{\}\w\.\-_:]+", text):
        return True

    # Pure numbers
    if re.fullmatch(r"[\d\s.,:+\-/%]+", text):
        return True

    # Color / IDs / technical values
    if text.startswith("#"):
        return True

    # Debug / technical messages
    technical_words = [
        "FCM TOKEN",
        "ONESIGNAL",
        "TOKEN =",
        "ID =",
        "API",
        "HTTP",
        "JSON",
        "MongoDB",
        "Firebase",
        "Cloudinary",
        "Razorpay",
        "TDLIB",
        "TDLib",
    ]

    for word in technical_words:
        if word.lower() in text.lower():
            return True

    # Very short technical strings
    if len(text) <= 1:
        return True

    return False


# ============================================================
# USER-VISIBLE CONTEXTS
# ============================================================

CONTEXT_PATTERNS = [
    r"\bText\s*\(",
    r"\bTextSpan\s*\(",
    r"\bhintText\s*:",
    r"\blabelText\s*:",
    r"\bhelperText\s*:",
    r"\berrorText\s*:",
    r"\btitle\s*:",
    r"\bsubtitle\s*:",
    r"\btooltip\s*:",
    r"\bsemanticLabel\s*:",
    r"\bmessage\s*:",
    r"\bSnackBar\s*\(",
    r"\bAlertDialog\s*\(",
    r"\bSimpleDialog\s*\(",
    r"\bshowDialog\s*\(",
    r"\bDropdownMenuItem\s*<",
    r"\bBottomNavigationBarItem\s*\(",
]


# ============================================================
# EXTRACT SINGLE-LINE USER VISIBLE STRINGS
# ============================================================

def extract_strings(line):

    results = []

    if not any(re.search(pattern, line) for pattern in CONTEXT_PATTERNS):
        return results

    # Ignore lines that are clearly comments
    stripped = line.strip()

    if stripped.startswith("//"):
        return results

    # Match "English text"
    matches = re.finditer(
        r'(?<![\w])(["\'])([^"\']{2,})(\1)',
        line
    )

    for match in matches:

        text = match.group(2).strip()

        if should_ignore(text):
            continue

        # Ignore obvious Dart expressions
        if "$" in text:
            # Keep strings with interpolation if they contain visible words
            visible = re.sub(
                r"\$\{[^}]+\}|\$[A-Za-z_]\w*",
                "",
                text
            ).strip()

            if not visible:
                continue

        results.append({
            "text": text,
            "start": match.start(2),
            "end": match.end(2),
        })

    return results


# ============================================================
# FIND ALL DART FILES
# ============================================================

dart_files = []

for path in LIB.rglob("*.dart"):

    relative_parts = path.relative_to(LIB).parts

    if any(part in EXCLUDED_DIRS for part in relative_parts):
        continue

    dart_files.append(path)


print("=" * 70)
print("HEALTHHOME SAFE LOCALIZATION")
print("=" * 70)
print(f"Dart files found: {len(dart_files)}")
print()


# ============================================================
# COLLECT STRINGS
# ============================================================

found = {}
skipped = []

for path in dart_files:

    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        continue

    lines = content.splitlines()

    for line_number, line in enumerate(lines, start=1):

        strings = extract_strings(line)

        for item in strings:

            text = item["text"]

            if text in found:
                found[text]["files"].append(
                    f"{path.as_posix()}:{line_number}"
                )
                continue

            found[text] = {
                "text": text,
                "file": path.as_posix(),
                "line": line_number,
                "files": [
                    f"{path.as_posix()}:{line_number}"
                ],
            }


print(f"Potential UI strings found: {len(found)}")
print()


# ============================================================
# CREATE KEYS
# ============================================================

key_map = {}

all_keys = set(en.keys())

for text, info in found.items():

    # If same English text already exists in JSON,
    # try to reuse existing key.
    existing_key = None

    for key, value in en.items():
        if str(value).strip() == text.strip():
            existing_key = key
            break

    if existing_key:
        key = existing_key
    else:
        base = make_key(text)

        if not base:
            continue

        key = unique_key(base, all_keys)
        all_keys.add(key)

    key_map[text] = key


# ============================================================
# ADD ENGLISH
# ============================================================

new_english = 0

for text, key in key_map.items():

    if key not in en:

        en[key] = text
        new_english += 1


# ============================================================
# TRANSLATION TABLE
#
# Important:
# Existing Hindi/Gujarati translations are preserved.
# New entries initially use English so the app never shows
# missing keys. A translation report is generated separately.
# ============================================================

new_hindi = 0
new_gujarati = 0

for text, key in key_map.items():

    if key not in hi:
        hi[key] = text
        new_hindi += 1

    if key not in gu:
        gu[key] = text
        new_gujarati += 1


# ============================================================
# SAVE JSON
# ============================================================

L10N.mkdir(parents=True, exist_ok=True)

with open(EN_FILE, "w", encoding="utf-8") as f:
    json.dump(en, f, ensure_ascii=False, indent=2)

with open(HI_FILE, "w", encoding="utf-8") as f:
    json.dump(hi, f, ensure_ascii=False, indent=2)

with open(GU_FILE, "w", encoding="utf-8") as f:
    json.dump(gu, f, ensure_ascii=False, indent=2)


# ============================================================
# CREATE REPORT
# ============================================================

report = {
    "total_dart_files": len(dart_files),
    "potential_ui_strings": len(found),
    "new_english_keys": new_english,
    "new_hindi_keys": new_hindi,
    "new_gujarati_keys": new_gujarati,
    "strings": []
}

for text, info in found.items():

    report["strings"].append({
        "text": text,
        "key": key_map.get(text),
        "file": info["file"],
        "line": info["line"],
        "all_occurrences": info["files"],
    })


with open(REPORT_FILE, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)


# ============================================================
# PRINT SUMMARY
# ============================================================

print("=" * 70)
print("SCAN COMPLETE")
print("=" * 70)

print(f"Dart files scanned       : {len(dart_files)}")
print(f"UI strings found         : {len(found)}")
print(f"New English keys         : {new_english}")
print(f"New Hindi keys           : {new_hindi}")
print(f"New Gujarati keys        : {new_gujarati}")

print()
print("Created:")
print("  lib/l10n/en.json")
print("  lib/l10n/hi.json")
print("  lib/l10n/gu.json")
print("  localization_report.json")

print()
print("IMPORTANT:")
print("This first pass ONLY builds the translation dictionary.")
print("It does NOT automatically modify Dart source files.")
print()
print("This is intentional.")
print("We will convert Dart files only after checking the generated")
print("translation report so the working app is not broken.")
print("=" * 70)