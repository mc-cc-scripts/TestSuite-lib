local http = {}

    local httpSocket = require("socket.http")

    http.get = function(...)
        local response = httpSocket.request(...)
        if response == "404:Not Found" then
            return nil
        end
        return {
            readAll = function()
                return response
            end,
            close = function()
            end
        }
    end

return http