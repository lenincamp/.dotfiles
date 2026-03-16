############################ Lazy-loaded version managers ############################
# Defers heavy init (~280ms) until first use of the command

# --- pyenv (~120ms deferred) ---
if command -v pyenv &>/dev/null; then
    _init_pyenv() {
        unfunction python python3 pip pip3 pyenv 2>/dev/null
        eval "$(pyenv init -)"
    }
    python()  { _init_pyenv; python  "$@" }
    python3() { _init_pyenv; python3 "$@" }
    pip()     { _init_pyenv; pip     "$@" }
    pip3()    { _init_pyenv; pip3    "$@" }
    pyenv()   { _init_pyenv; pyenv   "$@" }
fi

# --- jenv (~160ms deferred) ---
if command -v jenv &>/dev/null; then
    _init_jenv() {
        unfunction java javac mvn gradle jenv 2>/dev/null
        eval "$(jenv init -)"
    }
    java()   { _init_jenv; java   "$@" }
    javac()  { _init_jenv; javac  "$@" }
    mvn()    { _init_jenv; mvn    "$@" }
    gradle() { _init_jenv; gradle "$@" }
    jenv()   { _init_jenv; jenv   "$@" }
fi
