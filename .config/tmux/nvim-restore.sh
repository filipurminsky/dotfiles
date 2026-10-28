#!/bin/sh
# Opt into LazyVim's project/branch session restoration only for Resurrect.
exec nvim --cmd 'let g:dotfiles_restore_session = 1'
