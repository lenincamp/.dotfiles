local estado_original = {} -- Tabla para almacenar el estado original del texto

function _G.escapar_caracteres()
  -- Obtener la selección visual
  local start, finish = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  local bufnr = vim.fn.bufnr() -- Obtener el número del buffer actual

  -- Verificar si ya se ha escapado el texto
  if estado_original[bufnr] then
    -- Restaurar el texto original
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, estado_original[bufnr])
    estado_original[bufnr] = nil -- Eliminar el estado original almacenado
  else
    -- Guardar el estado original del texto
    estado_original[bufnr] = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)

    -- Tabla de reemplazos (carácter -> representación Unicode)
    local reemplazos = {
      ["ó"] = "\\u00F3",
      ["á"] = "\\u00E1",
      ["é"] = "\\u00E9",
      ["í"] = "\\u00ED",
      ["ú"] = "\\u00FA",
      ["Á"] = "\\u00C1",
      ["É"] = "\\u00C9",
      ["Í"] = "\\u00CD",
      ["Ó"] = "\\u00D3",
      ["Ú"] = "\\u00DA",
      ["ñ"] = "\\u00F1",
      ["Ñ"] = "\\u00D1",
    }

    -- Escapar los caracteres en cada línea
    local lines = vim.api.nvim_buf_get_lines(0, start[2] - 1, finish[2], false)
    for i, line in ipairs(lines) do
      for char, reemplazo in pairs(reemplazos) do
        line = string.gsub(line, char, reemplazo)
      end
      lines[i] = line
    end

    -- Reemplazar el texto seleccionado con el texto escapado
    vim.api.nvim_buf_set_lines(0, start[2] - 1, finish[2], false, lines)
  end
end

-- Función para encontrar el nombre de la clase
local function get_class_name()
  -- Obtener el buffer actual
  local bufnr = vim.api.nvim_get_current_buf()
  -- Guardar la posición actual del cursor
  local current_pos = vim.api.nvim_win_get_cursor(0)

  -- Buscar hacia atrás la definición de la clase
  local class_pattern = "class%s+(%w+)"
  for i = current_pos[1], 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, i - 1, i, false)[1]
    local class_name = line:match(class_pattern)
    if class_name then
      return class_name
    end
  end
  return "UnknownClass"
end

-- Función para obtener el nombre del método bajo el cursor
local function get_method_name()
  return vim.fn.expand("<cword>")
end

local java_8_home = "JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home "

function _G.run_test_method(isTest)
  local base_command = java_8_home
    .. "mvn test -Dtest=%s#%s -DfailIfNoTests=false -Djacoco.skip=true -Dmaven.javadoc.skip=true -Dmaven.site.skip=true -Dsurefire.useFile=false -DtrimStackTrace=false -Dmaven.source.skip=true -o -B -pl api -am" --commented ,backoffice
  local command = isTest and base_command .. " -Dmaven.surefire.debug" or base_command
  local maven_test_command = string.format(command, get_class_name(), get_method_name())
    .. '| grep -A 10 -B 1 "T E S T S"'
  -- Ejecutar comando en popup de tmux (tecla π)
  vim.fn.system("tmux send-keys -t scratch '" .. maven_test_command .. "' C-m")

  -- Ejecutar comando Maven en popup de tmux
  -- local full_command = string.format("tmux display-popup -w 80%% -h 60%% '%s'", maven_test_command)
  -- vim.fn.system(full_command)

  -- Abrir terminal y ejecutar comando Maven
  -- vim.cmd("split")
  -- vim.cmd("terminal")
  -- vim.fn.chansend(vim.b.terminal_job_id, maven_test_command .. "\n")

  -- Mostrar mensaje
  vim.notify("Ejecutando: " .. maven_test_command, vim.log.levels.INFO)
end

function _G.run_test_class()
  local base_command = java_8_home
    .. "mvn test -Dtest=%s -DfailIfNoTests=false -Djacoco.skip=true -Dmaven.javadoc.skip=true -Dmaven.site.skip=true  -Dsurefire.useFile=false -DtrimStackTrace=false -Dmaven.source.skip=true -o -B -pl api -am" --,backoffice is commented when in need
  local maven_test_command = string.format(base_command, get_class_name())
    .. '| grep -A 100 "T E S T S" | grep -B 100 "BUILD SUCCESS"'
  -- Ejecutar comando en popup de tmux (tecla π)
  vim.fn.system("tmux send-keys -t scratch '" .. maven_test_command .. "' C-m")

  -- Mostrar mensajete
  vim.notify("Ejecutando Test Clase: " .. maven_test_command, vim.log.levels.INFO)
end

function _G.create_java_class()
  -- Obtener la ruta completa del buffer actual
  local buffer_path = vim.fn.expand("%:p:h")

  -- Mostrar la ruta completa editable al usuario
  vim.ui.input(
    { prompt = "Ruta completa del archivo (incluyendo el nombre): ", default = buffer_path .. "/" },
    function(ruta_completa)
      if not ruta_completa or ruta_completa == "" then
        return
      end

      -- Extraer el nombre del archivo y el directorio
      local nombre_archivo = string.match(ruta_completa, "([^/]+)%.java$")
      local directorio = string.match(ruta_completa, "(.*)/[^/]+%.java$")

      if not nombre_archivo or not directorio then
        vim.notify("Ruta inválida.", vim.log.levels.ERROR)
        return
      end

      -- Convertir la ruta del directorio a un nombre de paquete
      local src_index = directorio:find("src/main/java/") or directorio:find('src/test/java/')
      if src_index then
        local package_path = directorio:sub(src_index + #"src/main/java/")
        local paquete = package_path:gsub("/", ".")
        local contenido = ""

        -- Mostrar opciones al usuario
        vim.ui.select(
          { "Clase", "Enum", "Interface", "Anotación", "Excepción" },
          { prompt = "Tipo de archivo:" },
          function(tipo)
            if not tipo then
              return
            end

            -- Crear el contenido del archivo según el tipo
            if tipo == "Clase" then
              contenido = [[
package ]] .. paquete .. [[;

public class ]] .. nombre_archivo .. [[ {
}
]]
            elseif tipo == "Enum" then
              contenido = [[
package ]] .. paquete .. [[;

public enum ]] .. nombre_archivo .. [[ {
}
]]
            elseif tipo == "Interface" then
              contenido = [[
package ]] .. paquete .. [[;

public interface ]] .. nombre_archivo .. [[ {
}
]]
            elseif tipo == "Anotación" then
              contenido = [[
package ]] .. paquete .. [[;

public @interface ]] .. nombre_archivo .. [[ {
}
]]
            elseif tipo == "Excepción" then
              contenido = [[
package ]] .. paquete .. [[;

public class ]] .. nombre_archivo .. [[ extends RuntimeException {
    public ]] .. nombre_archivo .. [[(String message) {
        super(message);
    }
}
]]
            end

            -- Crear el archivo y escribir el contenido
            local archivo = io.open(ruta_completa, "w")
            if archivo then
              archivo:write(contenido)
              archivo:close()
              vim.cmd("edit " .. ruta_completa)
            else
              vim.notify("No se pudo crear el archivo.", vim.log.levels.ERROR)
            end
          end
        )
      else
        vim.notify("La ruta no contiene 'src/main/java/'.", vim.log.levels.ERROR)
      end
    end
  )
end

-- local function load_create_java_class()
--   vim.keymap.set('n', '<leader>jc', create_java_class, { desc = "Crear archivo Java" })
-- end
--
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "java",
--   callback = load_create_java_class,
-- })

return _G
