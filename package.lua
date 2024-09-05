local spath =
    debug.getinfo(1,'S').source:sub(2):gsub("/+", "/"):gsub("[^/]*$","")
package.path = spath.."?.lua;"
    ..spath.."ccClass/?.lua;"
    ..spath.."fs/?.lua;"
    ..spath.."helperFunctions/?.lua;"
    ..spath.."http/?.lua;"
    ..spath.."json/?.lua;"
    ..spath.."vector/?.lua;"
    ..package.path
