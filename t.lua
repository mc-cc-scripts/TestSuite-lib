local co = coroutine.create(function (a,b)
        local t = coroutine.yield("a")
        print("t", t)
        end)
print(coroutine.resume(co, "b"))
print(coroutine.resume(co, "b"))

