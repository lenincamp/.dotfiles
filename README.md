## Previous steps

### Install town

1. Install [https://www.gnu.org/software/stow/](stow)
2. Open terminal and execute stow command. (use n to preview result)

```sh
   stow --adopt -nv xterm
```

### Setting salesforce apex lsp

1. Download [apex-jorje-lsp.jar](https://github.com/forcedotcom/salesforcedx-vscode/blob/develop/packages/salesforcedx-vscode-apex/out/apex-jorje-lsp.jar)
2. Copy apex-jorje-lsp.jar in ~/.lsp/
3. Install sfdx
```sh
npm install -g sfdx-cli
```

### Prettier cat and git diff

1. install bat at [install](https://github.com/sharkdp/bat#installation)
2. install delta at [install](https://dandavison.github.io/delta/installation.html)

### Setting plugins zsh

Install fzf, fzf-tab, zsh-syntax-highlighting from [git](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)

### Install manual lsp

```sh
npm install -g typescript-language-server eslint_d  emmet-ls tailwindcss-language-server
brew install tree-sitter
brew install prettierd
```
