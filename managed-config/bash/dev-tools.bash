# Repo-managed bash snippet for ai-dev-setup.
# The installer copies this file to $HOME/.ai-dev-setup/bash/
# and ~/.bashrc sources it via a single include block.

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /mingw64/share/bash-completion/bash_completion ]; then
    . /mingw64/share/bash-completion/bash_completion
fi
