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
# If the cursor is not at the top-left corner, does nothing.
# Otherwise prints the specified prompt after percent expansion
# (but not single word shell expansions). The prompt is replaced
# inplace once the real prompt is initialized.
#
# For best results, set loading-prompt to something that looks similar
# (or, ideally, identical) to the real prompt.
#
# Must be called at the very top of ~/.zshrc. Must be paired with
# instant-zsh-post.
function instant-zsh-pre() {
  local prompt=$1
  zmodload zsh/terminfo

  # Do nothing if terminal is lacking required capabilities.
  (( $+terminfo[u7] && $+terminfo[home] && $+terminfo[ed] )) || return 0

  # Do nothing if the cursor is not in the top-left corner.
  local cursor
  IFS= read -s -d R cursor\?$terminfo[u7] <$TTY              || return 0
  [[ $cursor == $'\e[1;1' ]]                                 || return 0

  # Print the loading prompt. It'll be replaced by the real prompt later.
  unsetopt prompt_cr prompt_sp
  print -rn -- $terminfo[clear]${(%)prompt}

  _clear-loading-prompt() {
    # Clear the loading prompt. The real prompt is about to get printed.
    print -rn -- $terminfo[home]${(%):-"%b%k%f"}$terminfo[ed]
    setopt prompt_cr prompt_sp
    unfunction _clear-loading-prompt
    precmd_functions=(${(@)precmd_functions:#_clear-loading-prompt})
  }
  precmd_functions=($precmd_functions _clear-loading-prompt)
}

# Must be called at the very bottom of ~/.zshrc. Must be paired with
# instant-zsh-pre.
function instant-zsh-post() {
  if (( $+precmd_functions && $+precmd_functions[(I)_clear-loading-prompt] )); then
    # Move _clear-loading-prompt to the end so that the loading prompt doesn't get
    # erased too soon. This assumes that the real prompt is set during the first
    # `precmd` or even earlier.
    precmd_functions=(${(@)precmd_functions:#_clear-loading-prompt} _clear-loading-prompt)
  fi
}