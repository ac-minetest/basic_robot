-- HOW TO DOWNLOAD WEBPAGES/FILES USING ROBOT

if not fetch then
fetch = _G.basic_robot.http_api.fetch;

-- WARNING: this is run outside pcall and can crash server if errors!
result = function(res)  -- res.data is string containing result
  if not res.succeeded then self.label("#ERROR: data couldn't be downloaded :\n" .. minetest.serialize(res) ) return end
  if res.data then self.label(res.data) end
end

fetch({url = "http://185.85.149.248/FILES/minetest/README.txt", timeout = 30}, result)
end

--[[
from https://github.com/minetest/minetest/blob/master/doc/lua_api.txt :

`HTTPRequest` definition
------------------------

Used by `HTTPApiTable.fetch` and `HTTPApiTable.fetch_async`.

    {
        url = "http://example.org",
        timeout = 10,
    --  ^ Timeout for connection in seconds. Default is 3 seconds.
        post_data = "Raw POST request data string" OR {field1 = "data1", field2 = "data2"},
    --  ^ Optional, if specified a POST request with post_data is performed.
    --  ^ Accepts both a string and a table. If a table is specified, encodes
    --  ^ table as x-www-form-urlencoded key-value pairs.
    --  ^ If post_data ist not specified, a GET request is performed instead.
        user_agent = "ExampleUserAgent",
    --  ^ Optional, if specified replaces the default minetest user agent with
    --  ^ given string.
        extra_headers = { "Accept-Language: en-us", "Accept-Charset: utf-8" },
    --  ^ Optional, if specified adds additional headers to the HTTP request.
    --  ^ You must make sure that the header strings follow HTTP specification
    --  ^ ("Key: Value").
        multipart = boolean
    --  ^ Optional, if true performs a multipart HTTP request.
    --  ^ Default is false.
}

--]]