import streams, strutils

type
    Searcher = object
        str: string
        tab: SkipTable

type 
    Log = object
        id: int
        name: string
        path: string
        important: seq[string]

func isImportant(line: string, searchers: seq[Searcher]): bool =
    # finding: HH:MM -!-
    if line.len() > 10 and line.find("-!-", 6, 10) == 6:
        return false
    let start = line.find('<')
    if start == -1:
        return false
    let stop = line.find('>', start)
    if stop == -1:
        return false
    if stop <= start:
        return false
    for search in searchers:
        if search.tab.find(line, search.str, start, stop) >= 0:
            return true
        return false
    return false

proc getOffsets(buf: var array[2, uint64]): void =
    try:
        let st = openFileStream("offsets.txt", fmRead)
        st.read(buf)
        st.close()
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()
        stderr.writeLine "0 offsets will be used"

#os.sleep(5000)
echo "init"

const logs = [
    Log(
        id   : 0,
        name : "log2",
        path : "#log2bsd.log",
        important : @["Name1", "Name2"]
    ),
    Log(
        id   : 1,
        name : "log1",
        path : "#log1.log",
        important : @["Name3"]
    )
]

#os.sleep(5000)

var offs: array[2, uint64]
getOffsets(offs)

var counts: array[2, uint64]
    
#dumpNumberOfInstances()

var line = newStringOfCap(256)
for log in logs:
    var searchers = newSeqOfCap[Searcher](log.important.len())
    for name in log.important:
        var tab: SkipTable
        initSkipTable(tab, name)
        searchers.add(Searcher(str : name, tab : tab))
    try:
        let st = openFileStream(log.path, fmRead)
        var count : uint64 = offs[log.id]
        for _ in 1..offs[log.id]:
            discard st.readLine(line)
        while st.readLine(line):
            count += 1
            if isImportant(line, searchers):
                stdout.writeLine line
        st.close()
        counts[log.id] = count
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()

let diag = newFileStream(stdout)

try:
    let st = openFileStream("offsets.txt", fmWrite)
    st.write(counts)
    st.flush()
    st.close()
except IOError:
    diag.write "Could not write new offsets:"
    diag.writeLine getCurrentExceptionMsg()

for log in logs:
    diag.write log.name, ": "
    if offs[log.id] != counts[log.id]:
        diag.writeLine "new offset ", offs[log.id]
    else:
        diag.writeLine "no changes, retaining ", offs[log.id]

diag.flush()

#dumpNumberOfInstances()
