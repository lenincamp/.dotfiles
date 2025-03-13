## Previous steps

### Install tuckr

1. Install [https://github.com/RaphGL/tuckr](tuckr)

### Prettier cat and git diff
1. install bat at [install](https://github.com/sharkdp/bat#installation)
2. install delta at [install](https://dandavison.github.io/delta/installation.html)

### Setting plugins zsh
Install fzf, fzf-tab, zsh-syntax-highlighting from [git](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)

### Install tools
* **exa:** colorls
* **z:** save index in cd
* **tmux:** terminal multiplexer
* **aerospace:** macos tiling window manager
* **ghostty:** terminal emulator
* **jdtls:** for neovim java lsp
* **lazygit:** terminal git ui
* **lazydocker:** terminal docker gui
* **speedtest-cli:** internet speedtest
* **tldr:** command detail information
* **thefuck:** fix commands
* **ncdu:** storage cleaner
* **btop:** ui admin process
* **jadx:** java decompiler
* **clean-me:** uninstall apps and clean macos
* **daisydisk:** disk space admin
* **kanata:** remap keys macos
* **ttyper:** practice typing in console
* **zbar:** migrate 2nd factor qr from authenticator to keepass(keepassXC)
* **neofetch:** system info
* **axel:** download acelerator
* **yazi**: terminal file manager
* **mdfind**:alternative to locate (from spotlight / in system) 
* **locate**: index db of system files


> #### example of use zbar
> https://github.com/mchehab/zbar - read qr-code from google authenticator 
> zbarimg --raw ~/SCR-20250215-pfdn.png

> #### example of use axel
> axel -n 8 -a https://url

> #### example of use ffmpeg
> ffmpeg -i input.mp4 input.avi 

```sh
##unix tools
brew install --cask font-maple-mono font-maple-mono-nf
brew install exa z tmux ghostty jdtls lazygit lazydocker speedtest-cli tldr thefuck ncdu btop jadx ttyper zbar neofetch axel ffmpeg kanata
## locate => index db to find files in system

## yazi & dependencies
brew install yazi ffmpegthumbnailer sevenzip jq poppler fd ripgrep fzf zoxide imagemagick font-symbols-only-nerd-font
## install theme for yazi
ya pack -a yazi-rs/flavors:catppuccin-mocha

##macos tools
brew install clean-me daisydisk aerospace
```
