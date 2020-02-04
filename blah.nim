import streams, strutils, os

type 
    Log = object
        name: string
        path: string
        important: seq[string]

let names = ["ori"]

proc isImportant(line: string, names: seq[string]): bool =
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

#os.sleep(5000)
echo "init"

var logs = [
    Log(
        name : "log1",
        path : "#log1.log",
        important : @["ori"]
    ),
    Log(
        name : "log2",
        path : "#log2bsd.log",
        important : @["Name1", "justins"]
    )
]

#os.sleep(5000)

echo logs
dumpNumberOfInstances()

for log in logs:
    try:
        let st = openFileStream(log.path, fmRead)
        var line = ""
        while st.readLine(line):
            if isImportant(line, log.important):
                discard line
        st.close()
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()

dumpNumberOfInstances()
