if status is-interactive
    # Commands to run in interactive sessions can go here
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/pieterpel/anaconda3/bin/conda
    eval /home/pieterpel/anaconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/pieterpel/anaconda3/etc/fish/conf.d/conda.fish"
        . "/home/pieterpel/anaconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/pieterpel/anaconda3/bin" $PATH
    end
end
# <<< conda initialize <<<


set -x PATH $PATH /opt/nvim/
set -x EDITOR nvim
set -x TERM xterm-256color

# Add fenv to path
set fish_function_path $fish_function_path ~/plugin-foreign-env/functions

# Source Nix setup script
fenv source ~/.nix-profile/etc/profile.d/nix.sh

# Aliases

alias --save dev="pushd ~/nix/standard; nix develop --command fish; popd"
