import streams, strutils, os

{.push raises: [].}

type
    Counts = array[2, int]

    Searcher = object
        str: string
        tab: SkipTable

    Log = object
        id: int
        name: string
        path: string
        important: seq[string]

func getEmoteName(line: string, off: int): (int, int) =
    let start = off + 2
    let stop = line.find(' ', start)
    if stop == -1:
        return (-1, -1)
    return (start, stop - 1)

func isImportant(line: string, searchers: seq[Searcher]): bool =
    # finding: HH:MM -!-
    if line.len() <= 10:
        return false
    elif line.find("-!-", 6, 10) == 6:
        return false
    # finding < NAME>

    var start, stop : int
    if line[7] == '*':
        (start, stop) = getEmoteName(line, 7)
    else:
        start = line.find('<')
        if start == -1:
            return false
        stop = line.find('>')
    if stop == -1:
        return false
    if stop <= start:
        return false
    for search in searchers:
        if find(search.tab, line, search.str, start, stop) >= 0:
            return true
    return false

proc getOffsets(file: string): Counts =
    try:
        let st = openFileStream(file, fmRead)
        defer: st.close()
        st.read(result)
    except OSError, IOError:
        try:
            stderr.writeLine getCurrentExceptionMsg()
            stderr.writeLine "0 offsets will be used"
        except:
            discard
    except:
        try:
            stderr.writeLine getCurrentExceptionMsg()
        except:
            discard

when isMainModule:
    const offsetFile = ".nivampiric"
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

    let offs = getOffsets(offsetFile)

    var counts: Counts

    var line = newStringOfCap(512)
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
        stderr.writeLine "Could not write new offsets: " &
            getCurrentExceptionMsg() & ": " & osErrorMsg(osLastError())
        quit(QuitFailure)

    for log in logs:
        diag.write log.name, ":\t"
        if offs[log.id] != counts[log.id]:
            diag.writeLine "new offset ", counts[log.id]
        else:
            diag.writeLine "no changes, retaining ", counts[log.id]

    diag.flush()
