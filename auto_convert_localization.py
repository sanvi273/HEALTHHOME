import json
import os
import re

# ============================================================
# HEALTHHOME - SAFE AUTOMATIC LOCALIZATION CONVERTER
# ============================================================

REPORT_FILE = "localization_output/localization_report.json"

with open(REPORT_FILE, "r", encoding="utf-8") as f:
    report = json.load(f)

files = report.get("files", {})

changed_files = 0
changed_strings = 0


def dart_string(value):
    """Create a safe Dart single-quoted string."""
    value = value.replace("\\", "\\\\")
    value = value.replace("'", "\\'")
    return f"'{value}'"


def replace_in_line(line, original, key):
    """
    Replace only the exact detected UI string.
    Do not modify a string if it is already using .tr().
    """

    if f"'{key}'.tr()" in line or f'"{key}".tr()' in line:
        return line, False

    # Only replace quoted occurrences.
    patterns = [
        (f'"{original}"', f"'{key}'.tr()"),
        (f"'{original}'", f"'{key}'.tr()"),
    ]

    for old, new in patterns:
        if old in line:
            return line.replace(old, new), True

    return line, False


print()
print("=" * 60)
print(" HEALTHHOME AUTOMATIC LOCALIZATION CONVERTER")
print("=" * 60)
print()

for file_path, items in files.items():

    if not os.path.exists(file_path):
        print(f"⚠️ File not found: {file_path}")
        continue

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    original_lines = lines[:]
    file_changed = False

    # --------------------------------------------------------
    # Add easy_localization import if needed
    # --------------------------------------------------------

    needs_import = False

    for item in items:
        original = item["text"]

        for line in lines:
            if (
                f'"{original}"' in line
                or f"'{original}'" in line
            ):
                needs_import = True
                break

        if needs_import:
            break

    has_import = any(
        "package:easy_localization/easy_localization.dart"
        in line
        for line in lines
    )

    if needs_import and not has_import:

        # Find last import
        last_import_index = -1

        for i, line in enumerate(lines):
            if line.strip().startswith("import "):
                last_import_index = i

        if last_import_index >= 0:
            lines.insert(
                last_import_index + 1,
                "import 'package:easy_localization/easy_localization.dart';\n"
            )
        else:
            lines.insert(
                0,
                "import 'package:easy_localization/easy_localization.dart';\n"
            )

        file_changed = True

    # --------------------------------------------------------
    # Replace detected UI strings
    # --------------------------------------------------------

    for item in items:

        original = item["text"]
        key = item["key"]

        for i in range(len(lines)):

            new_line, changed = replace_in_line(
                lines[i],
                original,
                key
            )

            if changed:
                lines[i] = new_line
                changed_strings += 1
                file_changed = True

    # --------------------------------------------------------
    # Save file
    # --------------------------------------------------------

    if file_changed:

        with open(
            file_path,
            "w",
            encoding="utf-8"
        ) as f:
            f.writelines(lines)

        changed_files += 1

        print(
            f"✅ Updated: {file_path}"
        )

    else:

        print(
            f"⏭️ No changes: {file_path}"
        )


print()
print("=" * 60)
print(" CONVERSION COMPLETED")
print("=" * 60)
print()
print(f"Files changed   : {changed_files}")
print(f"Strings changed : {changed_strings}")
print()
print("Your original files are backed up in:")
print("lib_backup/")
print()