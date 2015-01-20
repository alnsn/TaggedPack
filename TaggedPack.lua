-- TaggedPack module.
--
-- The module adds tags (or names) to types defined by string.unpack()
-- format string. In other words, instead of working with numbered
-- objects returned by string.unpack(), this module lets you work
-- with a single table which stores all objects by names (tags).
--
-- 1) to define a new tagged pack for
-- `struct hdr { uint32_t size; char type[8]; } __attribute__((packed));`
-- stored in little endian order:
--
-- local tagged_pack = require "TaggedPack"
-- local hdr_def = tagged_pack.define { "!1<", "I32:size", "c8:type" }
--
-- 2) to unpack a hdr object from a buffer:
--
-- local hdr, next_pos = hdr_def.unpack(buffer, cur_pos)
-- print(hdr.size, hdr.type)
--
-- 3) to pack a hdr object:
-- local raw = hdr_def.pack(hdr)
--
-- XXX document syntax
-- XXX Implement TaggedPack.pack()

local _M = {}

local loadstring = load or loadstring

-- Split one chunk of TaggedPack definition and return two values:
-- (1) string.unpack() format string and (2) an array of field names.
-- For instance, split_def_chunk("i4J:foo:bar") returns "i4J", { "foo", "bar" }.
local function split_def_chunk(chunk)
	local tags = {}
	local colon = chunk:find(":")
	local packstr = colon and chunk:sub(1, colon - 1) or chunk
	for s in chunk:sub(#packstr + 1):gmatch("[^:%s]+") do
		table.insert(tags, s)
	end
	return packstr, tags
end

local function parse(def)
	local packstr = ""
	local tags = {}

	for _,chunk in ipairs(def) do
		local new_packstr, new_tags = split_def_chunk(chunk)
		packstr = packstr .. new_packstr
		for j=1,#new_tags do
			table.insert(tags, new_tags[j])
		end
	end

	return packstr, tags
end

function _M.define(def)
	def = type(def) == "table" and def or { def }
	local packstr, tags = parse(def)

	local unrolled_unpack = "local res,unpacked=...;"
	for i=1,#tags do
		local tag = tags[i]
		if tag ~= "_" then
			unrolled_unpack = unrolled_unpack ..
			    string.format(";res[%q]=unpacked[%d]", tag, i)
		end
	end

	local unrolled_unpack_fn = assert(loadstring(unrolled_unpack))
	local unpack_fn = string.unpack

	local function unpack(obj, pos, res)
		res = res or {}
		local unpacked = { unpack_fn(packstr, obj, pos) }
		unrolled_unpack_fn(res, unpacked)
		return res, unpacked[#unpacked]
	end

	-- XXX local function pack()

	return { packstr=packstr, tags=tags, unpack=unpack }
end

return _M
