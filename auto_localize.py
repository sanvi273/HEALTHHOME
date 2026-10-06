import os
import re
import json

# ============================================================
# HEALTHHOME - AUTOMATIC LOCALIZATION SCANNER
# ============================================================

LIB_FOLDER = "lib"
OUTPUT_FOLDER = "localization_output"

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# Files/folders that should NOT be scanned
IGNORE_DIRS = {
    ".dart_tool",
    "build",
    "generated",
    "services",
}

# Strings that are obviously NOT UI text
IGNORE_PATTERNS = [
    r"^https?://",
    r"^/",
    r"^[A-Z_]+$",
    r"^[a-zA-Z0-9_./:-]+$",
    r"^[a-zA-Z]+_[a-zA-Z_]+$",
]

# Dart UI widgets where strings are commonly displayed
UI_WIDGETS = [
    "Text",
    "TextSpan",
    "Tooltip",
    "SnackBar",
    "AlertDialog",
    "showDialog",
    "showModalBottomSheet",
    "InputDecoration",
    "DropdownMenuItem",
    "BottomNavigationBarItem",
]

found_strings = {}
file_results = {}


def looks_like_ui_text(value):
    value = value.strip()

    if not value:
        return False

    # Ignore very short values
    if len(value) < 2:
        return False

    # Ignore obvious technical values
    for pattern in IGNORE_PATTERNS:
        if re.match(pattern, value):
            return False

    # Ignore numbers
    if re.fullmatch(r"[\d\s.,:+\-/%]+", value):
        return False

    # Ignore file paths
    if "/" in value or "\\" in value:
        return False

    # Ignore code-like strings
    if "==" in value or "=>" in value or "{" in value or "}" in value:
        return False

    return True


def make_key(text):
    text = text.lower().strip()

    # Remove special characters
    text = re.sub(r"[^a-zA-Z0-9\s]", "", text)

    words = text.split()

    if not words:
        return None

    key = words[0]

    for word in words[1:]:
        key += word.capitalize()

    return key


def add_string(text, file_path, line_number):
    text = text.strip()

    if not looks_like_ui_text(text):
        return

    key = make_key(text)

    if not key:
        return

    # Avoid duplicate keys
    if key not in found_strings:
        found_strings[key] = text

    if file_path not in file_results:
        file_results[file_path] = []

    item = {
        "line": line_number,
        "key": key,
        "text": text,
    }

    if item not in file_results[file_path]:
        file_results[file_path].append(item)


def scan_dart_file(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.readlines()
    except Exception:
        return

    for line_number, line in enumerate(content, start=1):

        # Skip comments
        stripped = line.strip()

        if stripped.startswith("//"):
            continue

        # ----------------------------------------------------
        # Find strings inside common UI widgets
        # ----------------------------------------------------

        for widget in UI_WIDGETS:

            pattern = rf"{widget}\s*\(\s*['\"]([^'\"]+)['\"]"

            matches = re.findall(pattern, line)

            for match in matches:
                add_string(
                    match,
                    file_path,
                    line_number
                )

        # ----------------------------------------------------
        # Find common property strings
        # Example:
        # title: "My Appointments"
        # label: "Submit"
        # hintText: "Search"
        # tooltip: "Delete"
        # ----------------------------------------------------

        property_pattern = (
            r"(title|label|hintText|helperText|"
            r"tooltip|message|errorText|"
            r"labelText|semanticLabel|"
            r"emptyMessage|subtitle)\s*:\s*"
            r"['\"]([^'\"]+)['\"]"
        )

        matches = re.findall(property_pattern, line)

        for _, match in matches:
            add_string(
                match,
                file_path,
                line_number
            )


def scan_project():

    print()
    print("=" * 60)
    print(" HEALTHHOME AUTOMATIC LOCALIZATION SCANNER")
    print("=" * 60)
    print()

    for root, dirs, files in os.walk(LIB_FOLDER):

        # Remove ignored directories
        dirs[:] = [
            d for d in dirs
            if d not in IGNORE_DIRS
        ]

        for filename in files:

            if not filename.endswith(".dart"):
                continue

            path = os.path.join(root, filename)

            scan_dart_file(path)

    print()
    print(f"Found {len(found_strings)} possible UI strings.")
    print()


def save_english():

    output = os.path.join(
        OUTPUT_FOLDER,
        "en.json"
    )

    with open(
        output,
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            found_strings,
            file,
            ensure_ascii=False,
            indent=2
        )

    print(f"Created: {output}")


def save_report():

    output = os.path.join(
        OUTPUT_FOLDER,
        "localization_report.json"
    )

    report = {
        "total_strings": len(found_strings),
        "files": file_results
    }

    with open(
        output,
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            report,
            file,
            ensure_ascii=False,
            indent=2
        )

    print(f"Created: {output}")


def print_summary():

    print()
    print("-" * 60)
    print(" FILE SUMMARY")
    print("-" * 60)

    for file_path, strings in sorted(
        file_results.items()
    ):

        print(
            f"{file_path} -> {len(strings)} strings"
        )

    print()
    print("-" * 60)
    print(" NEXT STEP")
    print("-" * 60)

    print(
        "Check localization_output/en.json before "
        "using it in your app."
    )

    print()


if __name__ == "__main__":

    scan_project()

    save_english()

    save_report()

    print_summary()