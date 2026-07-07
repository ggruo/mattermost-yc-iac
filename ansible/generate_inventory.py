#!/usr/bin/env python3
import json
import sys
from pathlib import Path



def value(outputs, name):
    return outputs[name]["value"]


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: generate_inventory.py <terraform-output-json> <inventory-path>", file=sys.stderr)
        return 2

    outputs = json.loads(Path(sys.argv[1]).read_text())
    rendered = f"""---
all:
  children:
    mattermost:
      hosts:
        mattermost-01:
          ansible_host: {value(outputs, "vm_public_ip")}
          ansible_user: {value(outputs, "ssh_username")}
          mattermost_fqdn: {value(outputs, "mattermost_fqdn")}
          postgres_host: {value(outputs, "postgres_primary_host")}
          postgres_db: {value(outputs, "postgres_db_name")}
          postgres_user: {value(outputs, "postgres_user")}
"""
    Path(sys.argv[2]).parent.mkdir(parents=True, exist_ok=True)
    Path(sys.argv[2]).write_text(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
