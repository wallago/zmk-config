# List all commands
default:
    @just --list

# ── Paths & config ────────────────────────────────────────────
config_dir  := justfile_directory() + "/config"
board       := "nice_nano_v2"
shield_base := "chocofi"
displays    := "nice_view_adapter nice_view_gem"
overlay     := config_dir + "/boards/shields/chocofi/nice_view_spi_override.overlay"

# ── Setup ─────────────────────────────────────────────────────
# Initialize west workspace (first time only)
init:
    west init -l config
    west update
    west zephyr-export

 
# Update west modules (ZMK, Zephyr, etc.)
update:
    west update

# ── Build ─────────────────────────────────────────────────────
# Build the left half (with ZMK Studio enabled)
build-left:
    west build -d build/left -b {{board}} -S studio-rpc-usb-uart -s zmk/app -- \
        -DSHIELD="{{shield_base}}_left {{displays}}" \
        -DBOARD_ROOT={{config_dir}} \
        -DEXTRA_DTC_OVERLAY_FILE="{{overlay}}" \
        -DCONFIG_ZMK_STUDIO=y

# Build the right half
build-right:
    west build -d build/right -b {{board}} -s zmk/app -- \
        -DSHIELD="{{shield_base}}_right {{displays}}" \
        -DBOARD_ROOT={{config_dir}} \
        -DEXTRA_DTC_OVERLAY_FILE="{{overlay}}"

# Build both halves
build: build-left build-right
    @echo "✅ Built both halves"

# Pristine rebuild (wipes build dir first — use after config changes)
rebuild: clean build

# Clean all build artifacts
clean:
    rm -rf build/

# Watch config/ and rebuild both halves on change (needs `entr`)
watch:
    find config -type f | entr -c just build

# ── Flash ─────────────────────────────────────────────────────
# Copy UF2 to mounted bootloader (adjust mount path for your OS)
# Usage: just flash corne_left
flash SHIELD:
    @echo "Put keyboard in bootloader mode, then press enter..."
    @read
    cp build/{{SHIELD}}/zephyr/zmk.uf2 /dev/sda


# ── Analysis ──────────────────────────────────────────────────
# Flash/RAM usage breakdown for a side
size SIDE:
    west build -d build/{{SIDE}} -t rom_report
    west build -d build/{{SIDE}} -t ram_report

# ── Keymap visualization ──────────────────────────────────────
# Render keymap.svg with keymap-drawer
draw:
    keymap parse -z config/boards/shields/{{shield_base}}/{{shield_base}}.keymap > keymap.yaml
    keymap draw keymap.yaml > keymap.svg
    @echo "🎨 keymap.svg"

# ── Quality ───────────────────────────────────────────────────
# Check devicetree / keymap syntax via a dry-run build
check BOARD SHIELD:
    west build -d build/check -b {{BOARD}} -- -DSHIELD={{SHIELD}} -DZMK_CONFIG="$(pwd)/config" --dry-run

# Check for typos in docs + keymap comments
typos:
    typos

# Check links in markdown files
links:
    lychee *.md

# Code stats
stats:
    tokei

# ── Release ───────────────────────────────────────────────────
changelog:
    git cliff --unreleased

changelog-write:
    git cliff -o CHANGELOG.md

commit-check:
    committed HEAD
