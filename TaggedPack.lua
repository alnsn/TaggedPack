-- TaggedPack module.
local _M = {}

-- XXX impement string.pack format string parsing and
-- 
--[[
local have_ffi,ffi = pcall(require, "ffi")

local function is_big_endian()
	local src = ffi.new("uint32_t[1]", 255)
	local dst = ffi.new("uint8_t[4]")
	ffi.copy(dst, src, 4)
	return dst[3] ~= 0
end

-- XXX Plain Lua doesn't detect big endian.
local big = have_ffi and is_big_endian()
]]--

-- Split one chunk of TaggedPack definition and return two values:
-- (1) string.pack format string and (2) an array of field names.
-- For instance, split_def_chunk("i4J:foo:bar") returns "i4J", { "foo", "bar" }.
local function split_def_chunk(chunk)
	local fields = {}
	local colon = chunk:find(":")
	local packstr = colon and chunk:sub(1, colon - 1) or chunk
	for s in chunk:sub(#packstr + 1):gmatch("[^:%s]+") do
		table.insert(fields, s)
	end
	return packstr,fields
end

local function parse(def)
	local packstr = ""
	local fields = {}

	for _,chunk in ipairs(def) do
		local new_packstr, new_fields = split_def_chunk(chunk)
		packstr = packstr .. new_packstr
		for j=1,#new_fields do
			table.insert(fields, new_fields[j])
		end
	end

	return packstr, fields
end

function _M.define(def)
	def = type(def) == "table" and def or { def }
	local packstr, fields = parse(def)

	local function unpack(obj, pos, res)
		res = res or {}
		local unpacked = { packstr:unpack(obj, pos) }
		for i=1,#fields do
			res[fields[i]] = unpacked[i]
		end
		return res, unpacked[#unpacked]
	end

	return { packstr=packstr, fields=fields, unpack=unpack }
end

return _M
