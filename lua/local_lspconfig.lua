local M = {}

local function with_defaults(x, defaults)
	local ret = vim.deepcopy(x)
	for k, v in pairs(defaults) do
		if ret[k] == nil then ret[k] = v end
	end
	return ret
end

local default_options = { defaults={}, server={} }
local default_options__server = { defaults = {} }
M.options = nil
M.setup = function(options)
	if options == nil then options = {} end
	M.options = with_defaults(options, default_options)
	for k, v in pairs(M.options.server) do
		M.options.server[k] = with_defaults(v, vim.deepcopy(default_options__server))
	end
end

M.run_local_lspconfig = function(dir)
	assert(M.options ~= nil, 'called before setup')
	if dir == nil then dir = vim.fn.getcwd() end
	local cfg_file_path = vim.fn.resolve(dir..'/.nvim_lsp_cfg.json')
	local cfg_file = io.open(cfg_file_path, 'r')
	if cfg_file == nil then return end
	local cfg_file_contents = cfg_file:read('*a')
	cfg_file:close()
	local json_decode_status, json_data = pcall(vim.fn.json_decode, cfg_file_contents)
	if not json_decode_status then  -- if json decode failed, re-throw same message but with more info
		error('failed to decode json file at "'..cfg_file_path..'". - '..json_data)  -- (in case of error json_data will be the error message
	else  -- json decode succeeded, apply options from file
		-- TODO currently only check that json decode was successful, should also check that json data is structured how we expect
		local lspconfig = require'lspconfig'
		for lspname, options in pairs(json_data) do
			local full_options = options
			if M.options.server[lspname] ~= nil then
				full_options = with_defaults(options, M.options.server[lspname].defaults)
			end
			full_options = with_defaults(options, M.options.defaults)
			lspconfig[lspname].setup(full_options)
		end
	end
end

return M

