export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="lambda"

get_system_theme() {
  # macOS
  if [[ "$OSTYPE" == darwin* ]]; then
    if [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]]; then
      echo "dark"
    else
      echo "light"
    fi
    return
  fi

  # GNOME Linux
  if command -v gsettings >/dev/null; then
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    if [[ "$scheme" == "'prefer-dark'" ]]; then
      echo "dark"
    else
      echo "light"
    fi
    return
  fi

  # Default fallback
  echo "light"
}
THEME_MODE=$(get_system_theme)

# source $ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
plugins=(
        git
        zsh-vi-mode
        zoxide
        fzf
        fzf-tab
        zsh-syntax-highlighting
        zsh-autosuggestions
)
source $ZSH/oh-my-zsh.sh
source <(fzf --zsh)

######################## ALIASES ###############################
alias cat='bat --paging=never'
alias fk=thefuck
alias nv='nvim'
alias v='nvim'
alias vim='nvim'
alias gitalias='alias | grep git | fzf'

#alias git
alias fgcot='gco $(g tag | fzf)'
alias fgco='gco $(gb | fzf)'
alias fgcor='gco --track $(gbr | fzf)'

# alias general use
alias ls='eza --icons'                                                          # ls
alias l='eza -lbF --git --icons'                                                # list, size, type, git
alias ll='eza -lbGF --git --icons'                                             # long list
alias llm='eza -lbGd --git --sort=modified --icons'                            # long list, modified date sort
alias la='eza -lbhHigUmuSa --time-style=long-iso --git --color-scale --icons'  # all list
alias lx='eza -lbhHigUmuSa@ --time-style=long-iso --git --color-scale --icons' # all + extended list

# alias specialty views
alias lS='eza -1 --icons'                                                              # one column, just names
alias lt='eza --tree --level=3 --icons'                                         # tree
alias llt='eza -l --git --icons --tree '                                         # tree
alias lld='eza -lbhHFGmuSa --group-directories-first --icons'

# alias lazygit/lazydocker
alias lg=lazygit
alias ld=lazydocker
# alias tmux
alias mux="tmuxinator"

# petersen alias 
alias cenv="$WORK_PROJECT/changeenvironment.sh"
alias openApk="open $WORK_PROJECT/ar-petersen-cdp/mobile/platforms/android/app/build/outputs/apk/debug/"
if [[ $(hostname) == "Lenins-MacBook-Pro.local" ]]; then
    export DOCKER_HOST='unix:///var/folders/p9/pldrp6g96lb22zk1hyd9mtc00000gn/T/podman/podman-machine-default-api.sock'
    alias docker=podman
fi

################################# Funcions ###################################
#fuzzy docker start
function fdstart() {
	CONTAINER=`docker ps -a | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker start $CONTAINER
	fi
}

#fuzzy docker stop
function fdstop() {
	CONTAINER=`docker ps | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker stop $CONTAINER
	fi
}

#fuzzy docker exec
function fdex() {
	CONTAINER=`dclsa | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker exec -it $CONTAINER bash
	fi
}

#fuzzy docker log
function fdlog() {
	CONTAINER=`docker ps | rg -v CONTAINER | awk '-F ' ' {print $NF}' | fzf`
	if [ ! -z $CONTAINER ]
	then
		docker logs -f $CONTAINER
	fi
}

#petersen logs
function tol() {
  name=$1
  name=${name:u}
  logPath=$WORK_PROJECT/apache-tomcat-9.0.68/shared/shared_"$name"/omnichannel.log
  zed $logPath
}

function getIP() {
  ifconfig en0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | pbcopy
}

function buildApp(){
  jenv shell 17.0.10
  pyenv shell 2.7.18
  fnm use v14.21.3
  cd $WORK_PROJECT/ar-petersen-cdp/mobile
  if [ $# -eq 0 ] || [ -z "$1" -a -z "$2" ]; then
      python release.py lcampoverde --debug --no-ios --verbose
      exit 1
  fi
  if [ $1 = "--r" ]; then
        cd ../web
        yarn build
        cd ../mobile
  fi
  python release.py lcampoverde --debug $2 --verbose
  # Obtener la dirección IP de la máquina actual
  #   IP=$(ifconfig en0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')
}
## yazi file manager
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
######################################################################################

#Open adroid emulator
function openAdv() {
  $ANDROID_SDK_ROOT/emulator/emulator @Medium_Phone_API_34
}
#######################################################################################
# List specific type components using fzf
function sfl() {
    echo "Select the type to list its components..."
    local type=$(sf org list metadata-types --json | jq -r '.result.metadataObjects[].xmlName' | fzf --prompt="Type > " --height=40% --layout=reverse)
    
    if [[ -n "$type" ]]; then
        echo "Looking for components in the org to $type..."
        
        sf org list metadata -m "$type" --json | \
        jq -r '.result[]?.fullName' | \
        sort | \
        fzf --prompt="🔎 Filter components > " \
            --height=50% \
            --layout=reverse \
            --border \
            --info=inline
    fi
}


# List and retrieve/download specific type components using fzf
function sfld() {
    if ! command -v fzf &> /dev/null || ! command -v jq &> /dev/null; then
        echo "❌ Error: requires 'fzf' and 'jq'."
        return 1
    fi

    echo "🔍 Step 1: Select Metadata Type..."
    
    local mtype=$(sf org list metadata-types --json | \
        jq -r '.result.metadataObjects[].xmlName' | \
        sort | \
        fzf --prompt="📂 Type > " \
            --height=40% --layout=reverse --border --info=inline)

    if [[ -z "$mtype" ]]; then
        echo "❌ Canceled in Type Selection."
        return
    fi

    echo "⏳ Getting list of components for: \033[1;34m$mtype\033[0m ..."

    local selected_components=$(sf org list metadata -m "$mtype" --json | \
        jq -r '.result[]?.fullName' | \
        sort | \
        fzf --multi \
            --prompt="📄 Select Component(s) > " \
            --header="💡 Tip: Use TAB to select multiple, Enter to confirm" \
            --height=50% --layout=reverse --border)

    if [[ -z "$selected_components" ]]; then
        echo "❌ Cancelled in component selection."
        return
    fi

    local formatted_components=$(echo "$selected_components" | tr '\n' ',' | sed 's/,$//')

    echo ""
    echo "🎯 Retrieving: $mtype : $formatted_components"
    echo "---------------------------------------------------"

    local cmd="sf project retrieve start -m \"$mtype:$formatted_components\""
    
    echo "🚀 Executing: $cmd"
    eval $cmd
}

# diff with org
function sfnd() {
    local local_path="$1"
    
    if [[ -z "$local_path" ]]; then
        echo "❌ Error: You must provide the local file path."
        echo "Uso: sfnd force-app/main/default/classes/MyClass.cls"
        return 1
    fi
    if [[ ! -f "$local_path" ]]; then
        echo "❌ Error: Local file not found at: $local_path"
        return 1
    fi
    if ! command -v nvim &> /dev/null; then
        echo "❌ Error: 'nvim' not found. Ensure it is installed."
        return 1
    fi
    
    local mtype=""
    local mname=""
    # Path segment after 'default/' for analysis
    local path_segment=${local_path#*default/}
    local temp_dir=$(mktemp -d)
    
    trap "echo '🧹 Cleaning up temporary files...' && rm -rf '$temp_dir'" EXIT

    # === 3. Robust Inference Logic (Expanded) ===
    local basename_no_ext=$(basename "$local_path")
    local regex_result=() # Usado por el operador =~

    case $path_segment in
        # Code (Classes, Triggers, Pages)
        classes/*.cls)
            mtype="ApexClass"
            mname=$(basename "$local_path" .cls)
            ;;
        triggers/*.trigger)
            mtype="ApexTrigger"
            mname=$(basename "$local_path" .trigger)
            ;;
        pages/*.page)
            mtype="ApexPage"
            mname=$(basename "$local_path" .page)
            ;;

        # Components (LWC, Aura)
        lwc/*/*)
            mtype="LightningComponentBundle"
            mname=$(basename "$(dirname "$local_path")")
            ;;
        aura/*/*)
            mtype="AuraDefinitionBundle"
            mname=$(basename "$(dirname "$local_path")")
            ;;

        # Flows and Layouts
        flows/*.flow-meta.xml)
            mtype="Flow"
            mname=$(basename "$local_path" .flow-meta.xml)
            ;;
        layouts/*.layout-meta.xml)
            mtype="Layout"
            mname=$(basename "$local_path" .layout-meta.xml)
            ;;
            
        # Approval Process
        approvalProcesses/*.approvalProcess-meta.xml)
            mtype="ApprovalProcess"
            mname=$(basename "$local_path" .approvalProcess-meta.xml)
            ;;

        # Queues (Queue)
        queues/*.queue-meta.xml)
            mtype="Queue"
            mname=$(basename "$local_path" .queue-meta.xml)
            ;;

        # Permissions/Profiles
        permissionsets/*.permissionset-meta.xml)
            mtype="PermissionSet"
            mname=$(basename "$local_path" .permissionset-meta.xml)
            ;;
        profiles/*.profile-meta.xml)
            mtype="Profile"
            mname=$(basename "$local_path" .profile-meta.xml)
            ;;
            
        # Custom Objects (CustomObject)
        objects/*.object-meta.xml)
            mtype="CustomObject"
            mname=$(basename "$local_path" .object-meta.xml)
            ;;
        
        # Custom Fields (CustomField - Complex Logic)
        objects/*/fields/*.field-meta.xml)
            if [[ $path_segment =~ objects/([^/]+)/fields/([^/]+)\.field-meta\.xml ]]; then
                # $BASH_REMATCH[1] is the Object name (e.g.: Account)
                # $BASH_REMATCH[2] is the Field name (e.g.: MyField__c)
                local object_name="${BASH_REMATCH[1]}"
                local field_name="${BASH_REMATCH[2]}"
                mtype="CustomField"
                # Formato: ObjectAPIName.FieldAPIName (ej: Account.MyField__c)
                mname="$object_name.$field_name"
            fi
            ;;
        
        # Generic Types (CustomLabels, StaticResource, etc.)
        # Assumes the filename is the metadata name.
        labels/*.labels-meta.xml)
            mtype="CustomLabel"
            mname=$(basename "$local_path" .labels-meta.xml)
            ;;
        staticresources/*.resource-meta.xml)
            mtype="StaticResource"
            mname=$(basename "$local_path" .resource-meta.xml)
            ;;

        # FALLBACK Logic
        *)
            echo "⚠️ Metadata type not automatically recognized in: \033[1;33m$local_path\033[0m"
            # If inference fails, we ask manually before failing
            echo -n "✍️  Enter the Metadata Type (e.g.: RemoteSiteSetting): "
            read mtype
            echo -n "✍️  Enter the Full Name (e.g.: MyRemoteSite): "
            read mname
            if [[ -z "$mtype" || -z "$mname" ]]; then 
                echo "❌ Manual inference incomplete. Cancelled."
                return 1
            fi
            ;;
    esac

    if [[ -z "$mtype" || -z "$mname" ]]; then
        echo "❌ Could not infer metadata type and name. Cancelled."
        return 1
    fi

    echo "⚙️  Inferred Metadata: \033[1;32m$mtype:$mname\033[0m"
    echo "---------------------------------------------------"
    echo "⏳ Step 4: Downloading Org version to: $temp_dir"
    
    # === 4. Execute Retrieve to Temporary Folder ===
    if ! sf project retrieve start -m "$mtype:$mname" --output-dir "$temp_dir" > /dev/null; then
        echo "❌ Failed to download file from the Org. Check the name, format, or connection."
        return 1
    fi

    # === 5. Locate Remote File ===
    # We search for the file by its base name within the temporary folder
    local retrieved_path=$(find "$temp_dir" -name "$(basename "$local_path")" -print -quit)

    if [[ -z "$retrieved_path" ]]; then
        echo "❌ Error: Downloaded file not found in temporary folder ($mtype:$mname)."
        return 1
    fi

    # === 6. Execute nvimdiff ===
    echo "---------------------------------------------------"
    echo "🚀 Opening \033[1;36mnvimdiff\033[0m (Local Version vs Remote Version)..."
    
    # Execute nvim in diff mode
    nvim -d "$local_path" "$retrieved_path"
}

function sftr() {
    # Requiere fzf
    if ! command -v fzf &> /dev/null; then
        echo "❌ Error: 'fzf' is required for interactive selection."
        return 1
    fi
    
    echo "🔎 Scanning local Apex test classes..."

    # 1. Obtener la lista de clases Apex locales
    local class_names=$(find . -path '*/main/default/classes/*.cls' -print 2>/dev/null | xargs -n 1 basename | sed 's/\.cls$//')

    if [[ -z "$class_names" ]]; then
        echo "❌ No Apex classes found in the project's default folders."
        return 1
    fi

    # 2. Selección Interactiva con FZF (permite selección múltiple con TAB)
    local selected_classes=$(echo "$class_names" | sort | fzf --multi \
        --prompt="📝 Select Apex Test Class(es) or Method(s): " \
        --header="Use TAB to select multiple, type Name.Method for specific methods." \
        --height=50% --layout=reverse --border)

    if [[ -z "$selected_classes" ]]; then
        echo "❌ Test execution cancelled."
        return
    fi

    # 3. Formatear para el comando SF (Clase1,Clase2 o Clase1.Metodo1)
    # CORRECCIÓN: Reemplazamos saltos de línea por comas y eliminamos la coma final.
    local run_parameter=$(echo "$selected_classes" | tr '\n' ',' | sed 's/,$//')
    
    # 4. Ejecución de Prueba y Obtención del Log
    echo "---------------------------------------------------"
    echo "🔥 Executing tests for: \033[1;36m$run_parameter\033[0m"
    echo "---------------------------------------------------"

    # Comando de ejecución
    local test_command="sf apex run test --class-names $run_parameter --json"

    # Ejecutar y capturar el JSON del resultado
    local result_json=$(eval $test_command)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Test execution failed. Showing raw output."
        echo "$result_json"
        return $exit_code
    fi

    # Extracción de Log ID: Limpiamos caracteres de control para jq.
    local log_id=$(echo "$result_json" | tr -d '[:cntrl:]' | jq -r '.result.debugLogId')

    if [[ -n "$log_id" && "$log_id" != "null" ]]; then
        echo "✅ Tests finished successfully. Opening log: \033[1;33m$log_id\033[0m"
        echo "---------------------------------------------------"
        
        # 5. Abrir el Log (Usamos 'tail' para verlo en la terminal)
        sf apex get log --log-id "$log_id" --output-dir .
    else
        echo "⚠️ Tests completed, but could not retrieve a debug log ID."
    fi
}

function sfcov() {
    # Check dependencies
    if ! command -v fzf &> /dev/null || ! command -v jq &> /dev/null; then
        echo "❌ Error: 'fzf' and 'jq' are required for this command."
        return 1
    fi

    echo "🔎 Scanning local Apex classes for analysis..."

    # 1. Get list of all local Apex classes
    local class_names=$(find . -path '*/main/default/classes/*.cls' -print 2>/dev/null | xargs -n 1 basename | sed 's/\.cls$//')

    if [[ -z "$class_names" ]]; then
        echo "❌ No Apex classes found in the project's default folders."
        return 1
    fi

    # 2. Interactive selection with FZF (select the class to analyze)
    local selected_class=$(echo "$class_names" | sort | fzf \
        --prompt="📝 Select Apex Class to Analyze Coverage: " \
        --height=20 --layout=reverse --border)

    if [[ -z "$selected_class" ]]; then
        echo "❌ Coverage analysis cancelled."
        return
    fi
    
    # 3. Execute all tests to get comprehensive, fresh coverage data
    echo "---------------------------------------------------"
    echo "🔥 Running all local tests to generate fresh coverage data..."
    
    # We run all tests to ensure the selected class gets covered by all relevant test classes.
    local test_command="sf apex run test --code-coverage --json"
    local result_json=$(eval $test_command)
    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "❌ Test run failed. Coverage data is not reliable. Showing raw output."
        echo "$result_json"
        return $exit_code
    fi

    # 4. Use JQ to parse the result and extract coverage for the selected class
    local coverage_data=$(echo "$result_json" | jq -r ".result.coverage.coverage[] | select(.name==\"$selected_class\")")

    if [[ -z "$coverage_data" ]]; then
        echo "⚠️ Could not find coverage data for \033[1;33m$selected_class\033[0m. Ensure it's deployed and referenced by a test."
        return 1
    fi

    local covered=$(echo "$coverage_data" | jq -r '.numLinesCovered')
    local uncovered=$(echo "$coverage_data" | jq -r '.numLinesUncovered')
    local total=$((covered + uncovered))

    # Calculate percentage with basic shell arithmetic (scale to 2 decimals)
    # Note: bc is required for floating-point math in shell
    if ! command -v bc &> /dev/null; then
        echo "⚠️ Warning: 'bc' is required for percentage calculation. Showing raw numbers only."
        local percentage="N/A"
    else
        local percentage=$(echo "scale=2; ($covered / $total) * 100" | bc 2>/dev/null)
    fi

    local uncovered_lines=$(echo "$coverage_data" | jq -r '.uncoveredLines | .[]')
    
    # 5. Display the results
    echo "---------------------------------------------------"
    echo "📊 Coverage Report for \033[1;32m$selected_class\033[0m:"
    echo "---------------------------------------------------"
    echo "  Total Lines: $total"
    echo "  Covered:     $covered"
    echo "  Uncovered:   $uncovered"
    echo "  Coverage %:  \033[1;36m$percentage%\033[0m"
    echo ""

    if [[ -z "$uncovered_lines" ]]; then
        echo "🥳 \033[1;32m100% Coverage! No uncovered lines found.\033[0m"
    else
        echo "💔 \033[1;31mUNCOVERED LINES:\033[0m"
        echo "----------------------"
        # Display uncovered lines as a comma-separated list
        echo "$uncovered_lines" | tr '\n' ',' | sed 's/,$//'
        echo ""
    fi
}

###################################### Keybindings ####################################
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^O" fzf-cd-widget
unset LAST_LOGIN
#######################################################################################

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

############################ Shell integrations ###########################
eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
eval "$(pyenv init -)"
eval "$(jenv init -)"
export ZOXIDE_CMD_OVERRIDE="cd"
eval "$(zoxide init zsh)"

########################### PATH variables ################################
# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

local BTOP_CONF=$(readlink "$HOME/.config/btop/btop.conf")
local LAZYGIT_PATH="$HOME/Library/Application Support/lazygit"
if [[ "$THEME_MODE" == "dark" ]]; then
    source $ZSH/custom/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Mocha"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config.yml"
    local THEME="catppuccin_mocha"
else
    source $ZSH/custom/themes/catppuccin_latte-zsh-syntax-highlighting.zsh
    export BAT_THEME="Catppuccin Latte"
    export LG_CONFIG_FILE="$LAZYGIT_PATH/config-light.yml"
    local THEME="catppuccin_latte"
fi
sed -i '' "s/color_theme = \".*\"/color_theme = \"$THEME\"/" "$BTOP_CONF"
# zle reset-prompt


export LANG=en_US.UTF-8
export PATH="$HOME/.jenv/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
#petersen
export WORK_PROJECT="$HOME/workspace/projects/petersen"
export PATH="$WORK_PROJECT/instantclient/:$PATH"
#EZA
export EZA_CONFIG_DIR=$HOME/.config/eza
export EDITOR="nvim"
export VISUAL=$EDITOR

#bat theme - https://github.com/catppuccin/bat
# export BAT_THEME="Catppuccin Mocha"

######### fzf #######
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS="--layout=reverse --no-height --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 --color=selected-bg:#45475a --color=border:#313244,label:#cdd6f4"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window=up:85%:nowrap --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up'"
if [[ $FIND_IT_FASTER_ACTIVE -eq 1 ]]; then
   FZF_DEFAULT_OPTS='--no-height --layout=reverse --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down,ctrl-k:preview-up,ctrl-j:preview-down,ctrl-n:down,ctrl-p:up''
fi
export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
zstyle ':fzf-tab:*' popup-min-size 80 12
#############################
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export ANDROID_HOME=$HOME/workspace/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
export ANDROID_SDK_ROOT=$HOME/workspace/DevTools/Android/sdk # Ruta descrita en “Android SDK Location” en el paso anterior
# export JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
# export CORDOVA_JAVA_HOME=$HOME/Library/Java/JavaVirtualMachines/azul-17.0.10/Contents/Home
export JAVA_HOME=/opt/homebrew/Cellar/openjdk/25/libexec/openjdk.jdk/Contents/Home
export CORDOVA_JAVA_HOME=/opt/homebrew/Cellar/openjdk/25/libexec/openjdk.jdk/Contents/Home

export PATH=$PATH:$ANDROID_HOME/platform-tools/
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin/ # Validar que exista la carpeta latest previamente
export PATH=$PATH:$ANDROID_HOME/build-tools
export PATH=$PATH:$ANDROID_HOME/emulator/
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
export XDG_DATA_DIRS="/opt/homebrew/share:$XDG_DATA_DIRS"
