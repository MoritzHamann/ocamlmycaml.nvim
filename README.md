# OCaml plugin for Neovim

:warning: This is heavily under development and should be considered in alpha
state :warning:

At this point the API and commands will most likely change until I can find a
good setup. Expect backwards incompatible changes. You have been warned.

## Commands

### Dune
In order to invoke Dune directly from Neovim, use the `:Dune` command. It will map its arguments directly
to the underlying dune executable. E.g. to build the current project

```
:Dune build
```

Two things to note:

1. If the current buffer is part of a dune project, the working directory is set to the root of the project
2. The underlying process is tracked and exited once Neovim is closed

In order to stop long running dune commands (e.g. `:Dune build -w`), issue `:DuneStop` and select the
corresponding process.


## APi

### Dune
The dune functionality can also be accessed programmatically in lua.

```lua
local dune = require('ocamlmycaml.dune')

--- check if folder is part of a dune project by searching up the
--- file tree for a `dune-project` file
---@param file string
---@return string | nil
dune.find_project_folder(file)

--- returns a running dune job associated with the project root
--- or nil if no job is running
---
--- @param dune_root string dune project root folder
--- @return DuneJob|nil
dune.find_dune_job_for_project(dune_root)

--- Same as :DuneStop
dune.select_job_to_stop()

--- stops all running dune jobs invoked from :Dune
dune.stop_all_dune_jobs()

--- invoke dune programmatically (also tracks the process)
--- @param opts table
dune.dune({cmd={"exec", "bin/main.exe"})
```

### Ocamllsp
TODO: The following snippet only highlights the high-level API,
which combines ocamllsp requests and integrates them better with
Neovim. The low level API (ocamllsp requests) is not yet described.

```lua
local lsp = require('ocamlmycaml.lsp')

--- Switch between .mli (.rei) or .ml (.re) files
lsp.switchImplIntf(buffer)

--- expands ppx at the current cursor position 
--- and displays the result in a popup
--- Note: ocamllsp's `hover` functionality already does this
lsp.expand_ppx()

--- go to the next typed hole in the provided buffer (0 for current buffer)
lsp.nextHole(buffer)
```

## Telescope
At this point, the plugin provides a plugin for merlin's "search-by-type"
functionality. It can be invoked via

```
:Telescope ocamlmycaml search_by_type
```

or programmatically

```lua
local telescope = require('telescope')
telescope.extensions.ocamlmycaml.search_by_type()
```


## Configuration

```lua
local lsp = require('ocamlmycaml.lsp')
local dune = require('ocamlmycaml.dune').dune
local telescope = require('telescope')

require("ocamlmycaml").setup({
    dune = {
        auto_start = {
            -- will execute `dune build -w` when opening the
            -- first file in a dune project
            enable = true, 
            -- optional build directory for the auto-start dune process
            build_dir = "_build_lsp"
        }
    },
    mappings = {
        -- shortcut to map the keys in normal mode
        ["<leader>db"] = function() dune({cmd={"build"}}) end,
        -- extended mode for mapping in different/multiple modes
        ["<C-s>"] = {cmd = telescope.extensions.ocamlmycaml.search_by_type, mode = {"i"}},
        ["<leader>ocs"] = telescope.extensions.ocamlmycaml.search_by_type
        ["<leader>tml"] = function() lsp.switchImplIntf(0) end

    }
})
```

or with Lazy

```lua
{
    "MoritzHamann/ocamlmycaml.nvim",
    opts = {
        -- see above
    }
}
```

