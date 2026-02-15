#!/bin/sh

mkdir -p bin

echo "Vajra 2.0 Compilation System"
echo "============================"
echo "1. Development Build (Fast, with debug info)"
echo "2. Production Build (Optimized, Maximum Performance)"
echo "3. Production Build for Windows (Optimized, Maximum Performance)"
echo
printf "Select build type (1/2/3): "
read choice

if [ "$choice" = "1" ]; then
    echo
    echo "=== Development Build ==="
    if ! v -g main.v -o bin/vajra2; then
        echo
        echo "=== Build Failed! ==="
        exit 1
    fi
    echo
    echo "Compilation successful! Executable: bin/vajra2"
    exit 0

elif [ "$choice" = "2" ]; then
    echo
    echo "=== Production Build (Optimized) ==="
    if ! v -prod -gc none \
        -cc gcc \
        -cflags "-O3 -march=native -flto -fomit-frame-pointer" \
        main.v -o bin/vajra2; then
        echo
        echo "=== Build Failed! ==="
        exit 1
    fi
    echo
    echo "Compilation successful! Executable: bin/vajra2"
    echo
    echo "Testing UCI protocol..."
    printf "uci\nisready\nposition startpos\ngo depth 7\nquit\n" | ./bin/vajra2
    echo
    exit 0

elif [ "$choice" = "3" ]; then
    echo
    echo "=== Production Build for Windows (Optimized) ==="

    if ! command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
        echo "Missing mingw compiler. Install gcc-mingw-w64-x86-64"
        exit 1
    fi

    if ! v -enable-globals -os windows \
        -cc x86_64-w64-mingw32-gcc \
        -cflags "-O3 -march=x86-64-v3 -flto -mbmi2 -mpopcnt -mlzcnt -mavx2 -mfma -fomit-frame-pointer -funroll-loops" \
        -ldflags "-flto -s" \
        -prod ./main.v -o bin/vajra2_windows.exe; then
        echo
        echo "=== Build Failed! ==="
        exit 1
    fi

    echo
    echo "Compilation successful! Executable: bin/vajra2_windows.exe"
    exit 0

else
    echo "Invalid choice. Please run again and select 1, 2, or 3."
    exit 1
fi
