#!/usr/bin/env python3
"""JSON is valid YAML; encoding values prevents inventory injection."""
import json
import sys
from pathlib import Path


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: generate_inventory.py OUTPUT.json INVENTORY.yml")
    outputs = json.loads(Path(sys.argv[1]).read_text())
    host = {
        "ansible_host": outputs["vm_public_ip"]["value"],
        "ansible_user": "ubuntu",
        "app_fqdn": outputs["fqdn"]["value"],
        "postgres_host": outputs["postgres_host"]["value"],
    }
    target = Path(sys.argv[2])
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({"all": {"hosts": {"notes-vm": host}}}, indent=2) + "\n")


if __name__ == "__main__":
    main()
