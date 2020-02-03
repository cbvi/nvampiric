import streams, strutils


type 
    Log = object
        name: string
        path: string
        important: seq[string]

let names = ["ori"]

proc isImportant(line: string): bool =
    if line.len() > 10 and line[6..10] == "-!-":
        return false
    var start = line.find('<')
    if start == -1:
        return false
    var stop = line.find('>', start)
    if stop == -1:
        return false
    if stop <= start:
        return false
    for name in names:
        if line[start..stop].toLowerAscii.contains(name):
            return true
    return false

try:
    const myr = Log(
        name : "log1",
        path : "#log1.log",
        important : ["ori"][0..^1]
    )
    const dfly = Log(
        name : "log2",
        path : "#log2bsd.log",
        important : ["Name1", "justins"][0..^1]
    )

    const fefd = [myr, dfly]

    var st = openFileStream("#log1.log", fmRead)
    var line = ""
    while st.readLine(line):
        if isImportant(line):
            #echo line
            discard line
    st.close()
except IOError:
    stderr.writeLine getCurrentExceptionMsg()
