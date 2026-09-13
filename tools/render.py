#!/usr/bin/env python3
"""Render non-secret YAML examples. No shell evaluation; missing variables fail."""
import os
import sys
from pathlib import Path
from string import Template

if len(sys.argv) != 2:
    raise SystemExit("usage: render.py TEMPLATE.yaml.example")
try:
    print(Template(Path(sys.argv[1]).read_text()).substitute(os.environ), end="")
except KeyError as error:
    raise SystemExit(f"Export missing variable: {error.args[0]}")
