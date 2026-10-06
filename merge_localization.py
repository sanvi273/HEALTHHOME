import json
import os

# ============================================================
# HEALTHHOME - MERGE LOCALIZATION FILES
# ============================================================

CURRENT_DIR = "lib/l10n"
GENERATED_DIR = "localization_output"

LANGUAGES = ["en", "hi", "gu"]


def load_json(path):
    if not os.path.exists(path):
        print(f"❌ File not found: {path}")
        return {}

    with open(path, "r", encoding="utf-8") as file:
        return json.load(file)


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as file:
        json.dump(
            data,
            file,
            ensure_ascii=False,
            indent=2
        )


print()
print("=" * 60)
print(" HEALTHHOME LOCALIZATION MERGER")
print("=" * 60)
print()

for language in LANGUAGES:

    # Existing working translations
    current_file = os.path.join(
        CURRENT_DIR,
        f"{language}.json"
    )

    # Newly generated translations
    generated_file = os.path.join(
        GENERATED_DIR,
        f"{language}.json"
    )

    print(f"Processing {language}.json ...")

    current_data = load_json(current_file)
    generated_data = load_json(generated_file)

    # Keep existing translations.
    # Add newly generated keys only if they don't already exist.
    merged_data = generated_data.copy()

    for key, value in current_data.items():

        # Existing translation has priority.
        merged_data[key] = value

    # Sort keys alphabetically for easier maintenance.
    merged_data = dict(
        sorted(merged_data.items())
    )

    save_json(
        current_file,
        merged_data
    )

    print(
        f"   Existing keys : {len(current_data)}"
    )

    print(
        f"   New keys      : {len(generated_data)}"
    )

    print(
        f"   Final keys    : {len(merged_data)}"
    )

    print(
        f"   ✅ Updated: {current_file}"
    )

    print()


print("=" * 60)
print(" MERGE COMPLETED SUCCESSFULLY")
print("=" * 60)
print()

print("Your existing translations were preserved.")
print("The new translations were added.")
print()

print("Final files:")

for language in LANGUAGES:
    print(
        f"  lib/l10n/{language}.json"
    )

print()