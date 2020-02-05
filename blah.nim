import streams, strutils

type
    Searcher = object
        str: string
        tab: SkipTable

type 
    Log = object
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
        #if line[start..stop].toLowerAscii.contains(name):
        if search.tab.find(line, search.str, start, stop) >= 0:
            return true
        return false
    return false

proc getOffsets(arr: var array[2, uint64]): bool =
    try:
        let st = openFileStream("offsets.txt", fmRead)
        arr[0] = 42
        arr[1] = 77
        st.close()
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()
        return false
    return true

#os.sleep(5000)
echo "init"

const myr = Log(
    name : "log1",
    path : "#log1.log",
    important : @["Name3"]
)
const dfl = Log(
    name : "log2",
    path : "#log2bsd.log",
    important : @["Name1", "Name2"]
)

const logs = [myr, dfl]

#os.sleep(5000)

var arr: array[2, uint64]
discard getOffsets(arr)

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
        while st.readLine(line):
            if isImportant(line, searchers):
                discard line
        st.close()
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()

#dumpNumberOfInstances()
