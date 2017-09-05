
import strutils, sequtils
import os

let cpprefdir = "site/reference"

var s = ""
for kind, path in walkDir(cpprefdir):
  if kind == pcDir:
    s &= path.splitPath().tail & "\n"
writeFile("includes.txt", s)
