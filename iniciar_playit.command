#!/bin/bash
cd "$(dirname "$0")"

echo "============================================="
echo "           Iniciando Túnel Playit.gg         "
echo "============================================="

# Detener cualquier proceso anterior huérfano
killall playitd 2>/dev/null
sleep 0.5

# Iniciar el daemon en background
./playitd > /tmp/playitd.log 2>&1 &
PLAYITD_PID=$!

cleanup() {
    kill -9 $PLAYITD_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

SECRET_FILE="$HOME/Library/Application Support/playit_gg/playit.toml"

if [ ! -f "$SECRET_FILE" ]; then
    echo "Primera vez que inicias Playit."
    echo "Generando enlace para vincular..."
    echo ""
    ./playit setup
    echo ""
    echo "¡Vinculación completada!"
fi

echo "Conectando con los servidores de Playit.gg..."

# Esperar a que el daemon esté listo (hasta 6 intentos)
CONNECTED=false
for i in {1..6}; do
    if ! kill -0 $PLAYITD_PID 2>/dev/null; then
        break
    fi
    if ./playit status 2>/dev/null | grep -q "Phase: running"; then
        CONNECTED=true
        break
    fi
    sleep 1
done

if [ "$CONNECTED" = true ]; then
    echo "¡Conexión establecida!"
    echo "Abriendo consola interactiva (presiona Ctrl+C para salir)..."
    echo ""
    ./playit attach
else
    echo ""
    echo "⚠️  No se pudo conectar a Playit.gg en este momento."
    echo "Último registro de error:"
    tail -n 6 /tmp/playitd.log
    echo ""
    echo "Esto suele ocurrir por una micro-caída de los servidores de Playit o Cloudflare."
    echo "Presiona Enter para cerrar esta ventana..."
    read -r
fi
