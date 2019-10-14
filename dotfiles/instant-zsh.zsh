# Make zsh start INSTANTLY with this one weird trick.
#
#         https://asciinema.org/a/274255
#
#                   HOW TO USE
#
# 1. Add this at the top of your ~/.zshrc.
#
#   source ~/instant-zsh.zsh
#   instant-zsh-pre '%n@%m %~%# '
#
# Adjust the argument of instant-zsh-pre to be similar to your real prompt.
# For example, if you are using Powerlevel10k with lean style, this works well:
#
#   instant-zsh-pre "%B%39F${${(V)${(%):-%~}//\%/%%}//\//%b%31F/%B%39F}%b%f"$'\n'"%76F❯%f "
#
# If you override PROMPT_EOL_MARK in your zsh config files, move the definition
# above the instant-zsh-pre call.
#
# 2. Add this at the bottom of your ~/.zshrc.
#
#   instant-zsh-post
#
# 3. Optional: Compile instant-zsh.zsh for faster loading.
#
#   zcompile ~/instant-zsh.zsh
#
#                  HOW IT WORKS
#
# This doesn't actually make your zsh start instantly, hence the reference to the
# "one weird trick" advertisement. It does, however, make it feel like zsh is loading
# faster. Or, put it another way, your original zsh wasn't so slow to load, but you
# thought it was slow. Now you see that it was pretty fast all along.
#
# Here's how it work. To make your zsh "start instantly" all you need to do is print
# your prompt immediately when zsh starts, before doing anything else. At the top of
# ~/.zshrc is a good place for this. If your prompt takes a long time to initialize,
# print something that looks close enough. Then, while the rest of ~/.zshrc is evaluated
# and precmd hooks are run, all keyboard input simply gets buffered. Once initialization
# is complete, clear the screen and allow the real prompt be printed where the "loading"
# prompt was before. With the real prompt in place, all buffered keyboard input is
# processed by zle.
#
# It's a bit gimmicky but it does reduce the perceived ZSH startup latency by a lot.
# To make it more interesting, add `sleep 1` at the bottom of zsh and try opening a new
# tab in your terminal. It's still instant!

# Usage: instant-zsh-pre loading-prompt
#
# Prints the specified prompt after percent expansion (but not single word shell
# expansions). The prompt is replaced inplace once the real prompt is initialized.
#
# For best results, set loading-prompt to something that looks similar
# (or, ideally, identical) to the real prompt.
#
# Must be called at the very top of ~/.zshrc. Must be paired with instant-zsh-post.
#
# If you want to override PROMPT_EOL_MARK, do it before calling instant-zsh-pre.
function instant-zsh-pre() {
  zmodload zsh/terminfo

  # Do nothing if terminal is lacking required capabilities.
  (( ${+terminfo[cuu]} && ${+terminfo[ed]} && ${+terminfo[sc]} && ${+terminfo[rc]} )) || return 0

  unsetopt localoptions prompt_cr prompt_sp

  () {
    emulate -L zsh

    # Emulate prompt_cr and prompt_sp.
    local eol_mark=${PROMPT_EOL_MARK-"%B%S%#%s%b"}
    local -i fill=COLUMNS

    () {
      local COLUMNS=1024
      local -i x y=$#1 m
      if (( y )); then
        while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
          echo $y
          x=y
          (( y *= 2 ));
        done
        local xy
        while (( y > x + 1 )); do
          m=$(( x + (y - x) / 2 ))
          typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
        done
      fi
      (( fill -= x ))
    } $eol_mark

    print -r ${(%):-$eol_mark${(pl.$fill.. .)}$'\r'%b%k%f%E}$'\n\n\n\n\n\n\n\n\n'
    echoti cuu 10
    print -rn -- ${terminfo[sc]}${(%)1}

    _clear-loading-prompt() {
      unsetopt localoptions
      setopt prompt_cr prompt_sp
      () {
        emulate -L zsh
        # Clear the loading prompt. The real prompt is about to get printed.
        print -rn -- $terminfo[rc]$terminfo[sgr0]$terminfo[ed]
        unfunction _clear-loading-prompt
        precmd_functions=(${(@)precmd_functions:#_clear-loading-prompt})
      }
    }
    precmd_functions=($precmd_functions _clear-loading-prompt)
  } "$@"
}

# Must be called at the very bottom of ~/.zshrc. Must be paired with
# instant-zsh-pre.
function instant-zsh-post() {
  emulate -L zsh
  if (( ${+precmd_functions} && ${+precmd_functions[(I)_clear-loading-prompt]} )); then
    # Move _clear-loading-prompt to the end so that the loading prompt doesn't get
    # erased too soon. This assumes that the real prompt is set during the first
    # `precmd` or even earlier.
    precmd_functions=(${(@)precmd_functions:#_clear-loading-prompt} _clear-loading-prompt)
  fi
}
