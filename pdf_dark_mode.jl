using Images, FileIO

function invertir_todos_los_pdfs(carpeta_entrada=".", carpeta_salida="./pdfs_invertidos")
    
    #  Validación de carpetas
    if !isdir(carpeta_entrada)
        println("Error la carpeta de entrada no existe: $carpeta_entrada")
        return
    end

    # Crear carpeta de salida si no existe
    mkpath(carpeta_salida)


    # filtrar solo archivos PDF (ignorando mayúsculas/minúsculas)
    pdfs = filter(f -> endswith(lowercase(f), ".pdf"), readdir(carpeta_entrada, join=true))
    


    if isempty(pdfs)
        println("La siguiente carpeta no contiene PDFs: $carpeta_entrada")
        return
    end
    
    println("Archivos PDFs encontrados: $(length(pdfs))")
    println("="^50)
    
    for (idx, ruta_pdf) in enumerate(pdfs)
        nombre = basename(ruta_pdf)
        nombre_sin_extension = splitext(nombre)[1]
        ruta_salida = joinpath(carpeta_salida, "$(nombre_sin_extension)_invertido.pdf")
        
        println("\n[$idx/$(length(pdfs))] Procesando: $nombre")
        
        #crear una carpeta temporal para las imágenes de esta PDF
         
        carpeta_temp = joinpath(carpeta_salida, "temp_$(nombre_sin_extension)")
        mkpath(carpeta_temp)
        
        try
            # PDF a PNG
            print("Convirtiendo a imágenes...")
            # de poppler usamos pdftoppm con una resolucion de 300 dpi para buena calidad. El prefijo 'pag' hará que se nombren como pag-1.png, pag-2.png, etc.
            run(`pdftoppm -png -r 300 $ruta_pdf $carpeta_temp/pag`)
            println("listo")
            
            # Invertir colores de cada página
            paginas = sort(filter(f -> endswith(f, ".png"), readdir(carpeta_temp, join=true)))
            
            println("Invirtiendo $(length(paginas)) páginas...")
            for pag in paginas
                # Cargar la imagen
                img = load(pag)
    
                # Invertir colores (complemento)
                img_inv = complement.(img) 
                # Guardar la imagen invertida con el mismo nombre
                save(pag, img_inv)
            end
            
            # PNG a PDF
            print(" Generando PDF final...")
            
            cmd_convert = `magick convert "$(carpeta_temp)/*.png" "$ruta_salida"`
            run(cmd_convert)
            println("listo")
            
        catch e
            println("Error en $nombre: $e")
        finally
            
            if isdir(carpeta_temp)
                
                GC.gc() # forzar recolección de basura para liberar cualquier archivo bloqueado antes de intentar borrar la carpeta temporal
                # hacer una pequeña pausa para asegurarnos de que no haya archivos bloqueados antes de intentar borrar la carpeta temporal
                sleep(1) 
                # comando para remover la carpeta temporal y su contenido. Si falla, se muestra un mensaje para que el usuario lo borre manualmente.
                try
                    rm(carpeta_temp, recursive=true)
                catch e
                    println("No pude borrar la carpeta temporal automáticamente.")
                    println("Puedes borrarla manualmente después: $carpeta_temp")
                end
            end
        end
        println("Guardado en: $ruta_salida")
    end
    
    println("\n" * "="^50)
    println("¡Proceso completado!")
end

# Ejecutar
invertir_todos_los_pdfs()