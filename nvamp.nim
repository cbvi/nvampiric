import streams, strutils

const offsetFile = ".nivampiric"

type Counts = array[2, int]

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

proc getOffsets(buf: var Counts): void =
    try:
        let st = openFileStream(offsetFile, fmRead)
        st.read(buf)
        st.close()
    except IOError:
        stderr.writeLine getCurrentExceptionMsg()
        stderr.writeLine "0 offsets will be used"

when isMainModule:
    const logs = [
        Log(
            id   : 0,
            name : "log2",
            path : "log2.log",
            important : @["Name1", "Name2"]
        ),
        Log(
            id   : 1,
            name : "log1",
            path : "log1.log",
            important : @["Name3"]
        )
    ]

    var offs: Counts
    getOffsets(offs)

    var counts: Counts

    var line = newStringOfCap(256)
    for log in logs:
        var searchers = newSeqOfCap[Searcher](log.important.len())
        for name in log.important:
            var tab: SkipTable
            initSkipTable(tab, name)
            searchers.add(Searcher(str : name, tab : tab))
        try:
            let st = openFileStream(log.path, fmRead)
            st.setPosition(offs[log.id])
            if not st.atEnd():
                stdout.writeLine "==== ", log.name, " ===="
            while st.readLine(line):
                if isImportant(line, searchers):
                    stdout.writeLine line
            let count = st.getPosition()
            st.close()
            if count > offs[log.id]:
                stdout.write "\n\n"
            counts[log.id] = count
        except IOError:
            stderr.writeLine getCurrentExceptionMsg()
            quit(QuitFailure)

    let diag = newFileStream(stdout)

    try:
        let st = openFileStream(offsetFile, fmWrite)
        st.write(counts)
        st.flush()
        st.close()
    except IOError:
        stderr.write "Could not write new offsets:"
        stderr.writeLine getCurrentExceptionMsg()
        quit(QuitFailure)

    for log in logs:
        diag.write log.name, ":\t"
        if offs[log.id] != counts[log.id]:
            diag.writeLine "new offset ", counts[log.id]
        else:
            diag.writeLine "no changes, retaining ", counts[log.id]

    diag.flush()
