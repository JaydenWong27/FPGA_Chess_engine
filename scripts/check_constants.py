import re
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
from model import constants

def parse_python_constants():
  return {name: value for name, value in vars(constants).items()
          if name.isupper() and not name.startswith("_")
          and name not in ("VALUE", "CASTLE_KEEP")}

def parse_sv_parameters(filepath):
  params = {}
  
  pattern = re.compile(r"localparam\s+[^=;]*?(\w+)\s*=\s*([^;]+);", re.IGNORECASE)
  with open(filepath, "r", encoding="utf-8") as f:
    for line in f:
      line = line.split("//")[0]
      match = pattern.search(line)
      if match:
        params[match.group(1)] = sv_to_int(match.group(2))
  return params

def sv_to_int(text):
  text = text.replace("_", "").strip()
  if "'" not in text:              # plain decimal, like 32000
    return int(text)
  width, rest = text.split("'")    # "8'hA5" → "8" and "hA5"
  base = {"b": 2, "h": 16, "d": 10}[rest[0].lower()]
  return int(rest[1:], base) & ((1 << int(width)) - 1)   # trim to the width

py_consts = parse_python_constants()
sv_consts = parse_sv_parameters(ROOT / "rtl" / "common" / "chess_pkg.sv")

def show(value):
  return hex(value) if isinstance(value, int) else value

problems = 0
for source, found in (("model/constants.py", py_consts), ("chess_pkg.sv", sv_consts)):
  if not found:
    print(f"[EMPTY] no constants found in {source}")
    problems += 1

for key in sorted(set(py_consts) | set(sv_consts)):
  val_py = py_consts.get(key)
  val_sv = sv_consts.get(key)
  if val_py != val_sv:
    problems += 1
    print(f"[MISMATCH] {key} -> Python: {show(val_py)} | SV: {show(val_sv)}")

print(f"{len(sv_consts)} in package, {len(py_consts)} in Python, {problems} problem(s)")
sys.exit(1 if problems else 0)
