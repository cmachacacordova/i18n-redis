import json
import os
import tkinter as tk
from tkinter import ttk, messagebox

# Path to vcpkg.json relative to this script
VCPKG_JSON = os.path.join(os.path.dirname(__file__), '..', 'vcpkg.json')

# List of available dependencies for demonstration purposes
AVAILABLE_DEPS = [
    "nlohmann-json",
    "redis-plus-plus",
    "fmt",
    "spdlog"
]

def load_current_dependencies():
    """Return the list of dependencies currently in vcpkg.json."""
    with open(VCPKG_JSON, 'r', encoding='utf-8') as fh:
        data = json.load(fh)
    return data.get('dependencies', [])

def save_dependencies(deps):
    """Save the given list of dependencies back to vcpkg.json."""
    with open(VCPKG_JSON, 'r', encoding='utf-8') as fh:
        data = json.load(fh)
    data['dependencies'] = deps
    with open(VCPKG_JSON, 'w', encoding='utf-8') as fh:
        json.dump(data, fh, indent=2)
    messagebox.showinfo("vcpkg.json", "Dependencies updated")

def main():
    current = set(load_current_dependencies())

    root = tk.Tk()
    root.title("Select vcpkg dependencies")

    vars = {}
    for dep in AVAILABLE_DEPS:
        var = tk.BooleanVar(value=dep in current)
        chk = ttk.Checkbutton(root, text=dep, variable=var)
        chk.pack(anchor='w')
        vars[dep] = var

    def on_save():
        selected = [d for d, var in vars.items() if var.get()]
        save_dependencies(selected)

    ttk.Button(root, text="Save", command=on_save).pack(pady=5)
    root.mainloop()

if __name__ == '__main__':
    main()
