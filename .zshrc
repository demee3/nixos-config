fastfetch

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Created by newuser for 5.9
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
setopt INC_APPEND_HISTORY      # immediate saving of history
setopt SHARE_HISTORY           # share history across sessions
setopt HIST_IGNORE_DUPS        # ignore duplicate entries
setopt HIST_REDUCE_BLANKS      # remove extra blanks
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete)

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export EDITOR="subl -w"
alias scid='QT_XCB_GL_INTEGRATION=none QT_QPA_PLATFORM=xcb scide --disable-gpu'
alias ai='aichat'
alias ha='aichat -r bruh'

# Алиас для экспорта Апи токена для Гемини
export GEMINI_API_KEY="AI"
