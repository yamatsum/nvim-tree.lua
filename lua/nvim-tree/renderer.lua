local config = require'nvim-tree.config'
local utils = require'nvim-tree.utils'

local api = vim.api

local lines = {}
local hl = {}
local index = 0
local namespace_id = api.nvim_create_namespace('NvimTreeHighlights')

local icon_state = config.get_icon_state()

local get_folder_icon = function() return "" end
local function get_trailing_length()
  return vim.g.nvim_tree_add_trailing and 1 or 0
end

local set_folder_hl = function(line, depth, git_icon_len, _, hl_group)
  table.insert(hl, {hl_group, line, depth+git_icon_len+get_trailing_length(), -1})
end

if icon_state.show_folder_icon then
  get_folder_icon = function(open, is_symlink, has_children)
    local n = ""
    if is_symlink and open then
      n = icon_state.icons.folder_icons.symlink_open
    elseif is_symlink then
      n = icon_state.icons.folder_icons.symlink
    elseif open then
      if has_children then
        n = icon_state.icons.folder_icons.open
      else
        n = icon_state.icons.folder_icons.empty_open
      end
    else
      if has_children then
        n = icon_state.icons.folder_icons.default
      else
        n = icon_state.icons.folder_icons.empty
      end
    end
    return n.." "
  end
  set_folder_hl = function(line, depth, icon_len, name_len, hl_group)
    table.insert(hl, {hl_group, line, depth+icon_len, depth+icon_len+name_len+get_trailing_length()})
    table.insert(hl, {'NvimTreeFolderIcon', line, depth, depth+icon_len})
  end
end

local get_file_icon = function() return icon_state.icons.default end
if icon_state.show_file_icon then
  local web_devicons = require'nvim-web-devicons'

  get_file_icon = function(fname, extension, line, depth)
    local icon, hl_group = web_devicons.get_icon(fname, extension)

    if icon then
      if hl_group then
        table.insert(hl, { hl_group, line, depth, depth + #icon + 1 })
      end
      return icon.." "
    else
      return #icon_state.icons.default > 0 and icon_state.icons.default.." " or ""
    end
  end

end

local get_symlink_icon = function() return icon_state.icons.symlink end
if icon_state.show_file_icon then
  get_symlink_icon = function()
    return #icon_state.icons.symlink > 0 and icon_state.icons.symlink.." " or ""
  end
end

local get_special_icon = function() return icon_state.icons.default end
if icon_state.show_file_icon then
  get_special_icon = function()
    return #icon_state.icons.default > 0 and icon_state.icons.default.." " or ""
  end
end

local get_git_icons = function() return "" end
local get_git_hl = function() return end

if vim.g.nvim_tree_git_hl == 1 then
  local git_hl = {
    ["M "] = { { hl = "NvimTreeFileStaged" } },
    [" M"] = { { hl = "NvimTreeFileDirty" } },
    ["MM"] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileDirty" }
    },
    ["A "] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileNew" }
    },
    ["AD"] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileDeleted" }
    },
    ["AM"] = {
      { hl = "NvimTreeFileStaged" },
      { hl = "NvimTreeFileNew" },
      { hl = "NvimTreeFileDirty" }
    },
    ["??"] = { { hl = "NvimTreeFileNew" } },
    ["R "] = { { hl = "NvimTreeFileRenamed" } },
    ["UU"] = { { hl = "NvimTreeFileMerge" } },
    [" D"] = { { hl = "NvimTreeFileDeleted" } },
    ["D "] = {
      { hl = "NvimTreeFileDeleted" },
      { hl = "NvimTreeFileStaged" }
    },
    [" A"] = { { hl = "none" } },
    ["RM"] = { { hl = "NvimTreeFileRenamed" } },
    dirty = { { hl = "NvimTreeFileDirty" } },
  }
  get_git_hl = function(node)
    local git_status = node.git_status
    if not git_status then return end

    local icons = git_hl[git_status]

    if icons == nil then
      utils.echo_warning('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
      icons = git_hl.dirty
    end

    -- TODO: how would we determine hl color when multiple git status are active ?
    return icons[1].hl
    -- return icons[#icons].hl
  end
end

if icon_state.show_git_icon then
  local git_icon_state = {
    ["M "] = { { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" } },
    [" M"] = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
    ["MM"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
    },
    ["A "] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" }
    },
    [" A"] = {
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
    },
    ["AM"] = {
      { icon = icon_state.icons.git_icons.staged, hl = "NvimTreeGitStaged" },
      { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitNew" },
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" }
    },
    ["??"] = { { icon = icon_state.icons.git_icons.untracked, hl = "NvimTreeGitDirty" } },
    ["R "] = { { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" } },
    ["RM"] = {
      { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" },
      { icon = icon_state.icons.git_icons.renamed, hl = "NvimTreeGitRenamed" },
    },
    ["UU"] = { { icon = icon_state.icons.git_icons.unmerged, hl = "NvimTreeGitMerge" } },
    [" D"] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    ["D "] = { { icon = icon_state.icons.git_icons.deleted, hl = "NvimTreeGitDeleted" } },
    dirty = { { icon = icon_state.icons.git_icons.unstaged, hl = "NvimTreeGitDirty" } },
  }

  get_git_icons = function(node, line, depth, icon_len)
    local git_status = node.git_status
    if not git_status then return "" end

    local icon = ""
    local icons = git_icon_state[git_status]
    if not icons then
      if vim.g.nvim_tree_git_hl ~= 1 then
        utils.echo_warning('Unrecognized git state "'..git_status..'". Please open up an issue on https://github.com/kyazdani42/nvim-tree.lua/issues with this message.')
      end
      icons = git_icon_state.dirty
    end
    for _, v in ipairs(icons) do
      table.insert(hl, { v.hl, line, depth+icon_len+#icon, depth+icon_len+#icon+#v.icon })
      icon = icon..v.icon.." "
    end

    return icon
  end
end

local get_padding = function(depth)
  return string.rep(' ', depth)
end

if vim.g.nvim_tree_indent_markers == 1 then
  get_padding = function(depth, idx, tree, _, markers)
    local padding = ""
    if depth ~= 0 then
      local rdepth = depth/2
      markers[rdepth] = idx ~= #tree.entries
      for i=1,rdepth do
        if idx == #tree.entries and i == rdepth then
          padding = padding..'└ '
        elseif markers[i] then
          padding = padding..'│ '
        else
          padding = padding..'  '
        end
      end
    end
    return padding
  end
end

local picture = {
  jpg = true,
  jpeg = true,
  png = true,
  gif = true,
}

local special = {
  ["Cargo.toml"] = true,
  Makefile = true,
  ["README.md"] = true,
  ["readme.md"] = true,
}

local root_folder_modifier = vim.g.nvim_tree_root_folder_modifier or ':~'

local function update_draw_data(tree, depth, markers)
  if tree.cwd and tree.cwd ~= '/' then
    local root_name = utils.path_join({
      utils.path_remove_trailing(vim.fn.fnamemodify(tree.cwd, root_folder_modifier)),
      ".."
    })
    table.insert(lines, root_name)
    table.insert(hl, {'NvimTreeRootFolder', index, 0, string.len(root_name)})
    index = 1
  end

  for idx, node in ipairs(tree.entries) do
    local padding = get_padding(depth, idx, tree, node, markers)
    local offset = string.len(padding)
    if depth > 0 then
      table.insert(hl, { 'NvimTreeIndentMarker', index, 0, offset })
    end

    local git_hl = get_git_hl(node)

    if node.entries then
      local has_children = #node.entries ~= 0 or node.has_children
      local icon = get_folder_icon(node.open, node.link_to ~= nil, has_children)
      local git_icon = get_git_icons(node, index, offset, #icon+1) or ""
      -- INFO: this is mandatory in order to keep gui attributes (bold/italics)
      local folder_hl = "NvimTreeFolderName"
      if not has_children then folder_hl = "NvimTreeEmptyFolderName" end
      set_folder_hl(index, offset, #icon, #node.name+#git_icon, folder_hl)
      if git_hl then
        set_folder_hl(index, offset, #icon, #node.name+#git_icon, git_hl)
      end
      index = index + 1
      if node.open then
        table.insert(lines, padding..icon..git_icon..node.name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
        update_draw_data(node, depth + 2, markers)
      else
        table.insert(lines, padding..icon..git_icon..node.name..(vim.g.nvim_tree_add_trailing == 1 and '/' or ''))
      end
    elseif node.link_to then
      local icon = get_symlink_icon()
      local link_hl = git_hl or 'NvimTreeSymlink'
      table.insert(hl, { link_hl, index, offset, -1 })
      table.insert(lines, padding..icon..node.name.." ➛ "..node.link_to)
      index = index + 1

    else
      local icon
      local git_icons
      if special[node.name] then
        icon = get_special_icon()
        git_icons = get_git_icons(node, index, offset, 0)
        table.insert(hl, {'NvimTreeSpecialFile', index, offset+#git_icons, -1})
      else
        icon = get_file_icon(node.name, node.extension, index, offset)
        git_icons = get_git_icons(node, index, offset, #icon)
      end
      table.insert(lines, padding..icon..git_icons..node.name)

      if node.executable then
        table.insert(hl, {'NvimTreeExecFile', index, offset+#icon+#git_icons, -1 })
      elseif picture[node.extension] then
        table.insert(hl, {'NvimTreeImageFile', index, offset+#icon+#git_icons, -1 })
      end

      if git_hl then
        table.insert(hl, {git_hl, index, offset+#icon+#git_icons, -1 })
      end
      index = index + 1
    end
  end
end

local M = {}

local function is_bufnr_valid(bufnr)
  return vim.fn.bufexists(bufnr) == 1 and vim.fn.bufloaded(bufnr) == 1
end

function M.draw(tree, reload)
  if not is_bufnr_valid(tree.bufnr) then return end
  api.nvim_buf_set_option(tree.bufnr, 'modifiable', true)
  local cursor = api.nvim_win_get_cursor(tree.winnr())
  if reload then
    index = 0
    lines = {}
    hl = {}
    update_draw_data(tree, 0, {})
  end

  api.nvim_buf_set_lines(tree.bufnr, 0, -1, false, lines)
  M.render_hl(tree.bufnr)
  if #lines >= cursor[1] then
    api.nvim_win_set_cursor(tree.winnr(), cursor)
  end
  api.nvim_buf_set_option(tree.bufnr, 'modifiable', false)
  api.nvim_win_set_option(tree.winnr(), 'wrap', false)
end

function M.render_hl(bufnr)
  if not is_bufnr_valid(bufnr) then return end
  api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
  for _, data in ipairs(hl) do
    api.nvim_buf_add_highlight(bufnr, namespace_id, data[1], data[2], data[3], data[4])
  end
end

return M
