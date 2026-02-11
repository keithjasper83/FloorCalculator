
import os

def clean_file(filepath, imports_to_add):
    print(f"Processing {filepath}")
    with open(filepath, 'r') as f:
        content = f.read()

    lines = content.splitlines()
    final_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Remove standard imports
        if stripped.startswith("import Foundation"):
            i += 1
            continue
        if stripped.startswith("import SwiftUI"):
            i += 1
            continue

        # Check for RoomPlan import block specifically
        # Pattern:
        # #if canImport(RoomPlan)
        # import RoomPlan
        # #endif
        if stripped == "#if canImport(RoomPlan)":
            if i+1 < len(lines) and lines[i+1].strip() == "import RoomPlan":
                 if i+2 < len(lines) and lines[i+2].strip() == "#endif":
                     # Found the block. Skip 3 lines.
                     print("Removed RoomPlan import block")
                     i += 3
                     continue

        final_lines.append(line)
        i += 1

    # Reconstruct content
    new_content = "\n".join(final_lines)

    # Add imports at the top
    header = ""
    for imp in imports_to_add:
        header += imp + "\n"

    if header:
        # Check if file starts with comment block
        if new_content.lstrip().startswith("//"):
             # It's okay to put imports before comments, or after?
             # Usually after file header comment.
             # But parsing comments is hard. Just prepend. Swift compiler doesn't care.
             new_content = header + "\n" + new_content
        else:
             new_content = header + "\n" + new_content

    with open(filepath, 'w') as f:
        f.write(new_content)
    print(f"Cleaned {filepath}")

if __name__ == "__main__":
    clean_file("FloorPlanner/Models.swift", ["import Foundation"])
    clean_file("FloorPlanner/LayoutEngine.swift", ["import Foundation"])

    room_imports = [
        "import SwiftUI",
        "#if canImport(RoomPlan)",
        "import RoomPlan",
        "#endif"
    ]
    clean_file("FloorPlanner/RoomSettingsView.swift", room_imports)
