-- starts Qalculate as a job and sends given input through stdin

-- {{{ start job
local function start(input, config, callback)
    -- get command
    local cmd = vim.tbl_flatten({ 'qalc', '-f', '-', config.cmd_args })

    -- {{{ start a job
    local jobid = vim.fn.jobstart(
        cmd,
        {
            on_stdout = callback,
            stdout_buffered = true,
            pty = config.use_pty
        }
    )
    -- }}}

    -- {{{ send input to job
    -- add EOF as last entry of contents
    input[#input+1] = config.eof

    -- send input
    vim.fn.chansend(jobid, input)
    vim.fn.chanclose(jobid, 'stdin')
    -- }}}

    -- return jobid
    return jobid
end
-- }}}

-- {{{ start job and parse output
local parser = require('qalc.parse')
local previous_job = 0

local function run(namespace, input, config)
    -- stop previous job
    vim.fn.jobstop(previous_job)

    -- parse input
    local new_input, illegal = parser.input(input)

    -- start new job
    previous_job = start(new_input, config, function(_, raw_output, _)
        -- get bufnr
        local bufnr = vim.api.nvim_get_current_buf()

        -- parse output
        local parsed = parser.results(bufnr, raw_output, new_input, illegal, config)

        -- display results
        require('qalc.display').update.all(namespace, bufnr, config, parsed)
    end)
end
-- }}}

-- return module
return { run = run }
