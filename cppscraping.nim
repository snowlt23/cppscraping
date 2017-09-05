
import strutils, sequtils
import os
import docopt

proc genPage*(path: string): string =
  let s = readFile(path)
  let lines = s.splitLines.filter() do (x: string) -> bool: x != ""

  var fname = "**" & lines[0].replace("#").replace(" ") & "**"
  var desc = ""
  var cpp = ""

  var incpp = false
  var firstcpp = true
  var indesc = false
  for line in lines:
    if incpp and firstcpp:
      if line == "```":
        cpp &= line & "\n"
        incpp = false
        firstcpp = false
      else:
        cpp &= line & "\n"
    elif indesc:
      desc = line
      indesc = false
    else:
      if firstcpp and line == "```cpp":
        cpp &= line & "\n"
        incpp = true
      elif line == "## 概要":
        indesc = true
  return "$# $#\n$#" % [fname, desc, cpp]

proc genMd*(path: string): string =
  result = "## " & path.splitPath.tail & "\n"
  for fp in walkFiles(path / "*.md"):
    result &= genPage(fp)

let cpprefdir = "site/reference"
let doc = """
cppscraping

Usage:
  cppscraping [--single] [--pandoc] [--css=<css>]
"""

proc main() =
  let args = docopt(doc, version = "cppscraping 0.1.0")

  var mds = newSeq[tuple[name, s: string]]()
  var includes = readFile("includes.txt").splitLines().filter() do (x: string) -> bool: x != ""
  if not existsDir("dist"):
    createDir("dist")
  for p in includes:
    if not existsDir(cpprefdir / p):
      quit "couldn't find $#" % cpprefdir / p
    mds.add((p, genMd(cpprefdir / p)))

  let css = if args["--css"]: "-c " & $args["--css"] else: ""
  if args["--css"]:
    copyFile($args["--css"], "dist" / $args["--css"])
  if args["--single"]:
    let filename = "dist/cpprefjp_collect"
    writeFile(filename & ".md", mds.mapIt(it.s).join("\n"))
    if args["--pandoc"]:
      discard execShellCmd("pandoc -s $1.md $2 -o $1.html" % [filename, css])
  else:
    for md in mds:
      let filename = "dist" / md.name
      writeFile(filename & ".md", md.s)
      if args["--pandoc"]:
        discard execShellCmd("pandoc -s $1.md $2 -o $1.html" % [filename, css])

main()
