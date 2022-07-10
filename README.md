##Previous steps

###Install town

1. Install [https://www.gnu.org/software/stow/](stow)
2. Open terminal and execute stow command. (use n to preview result)

```sh
   stow --adopt -nv xterm
```

###Setting salesforce apex lsp

1. Download [https://github.com/forcedotcom/salesforcedx-vscode/blob/develop/packages/salesforcedx-vscode-apex/out/apex-jorje-lsp.jar](apex-jorje-lsp.jar)
2. Copy apex-jorje-lsp.jar in ~/.config/lsp-apex/
3. Setting file apex.lua

```sh
nvim ~/.config/nvim/lua/lsp-config/apex.lua
```

4. Set java url in cmd path(before "-cp" setting)

###Prettier cat and git diff

1. install bat at [https://github.com/sharkdp/bat#installation](https://github.com/sharkdp/bat#installation)
2. install delta at [https://dandavison.github.io/delta/installation.html](https://dandavison.github.io/delta/installation.html)

###Setting plugins zsh
Install fzf, fzf-tab, zsh-syntax-highlighting from [https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins](git)
