#!/bin/bash

# --- Configuration ---
# Force Python 3.13 to avoid the 3.14 Cython compilation errors
if command -v python3.13 >/dev/null 2>&1; then
    PYTHON_EXECUTABLE="python3.13"
elif command -v python3.12 >/dev/null 2>&1; then
    PYTHON_EXECUTABLE="python3.12"
else
    PYTHON_EXECUTABLE="python3"
fi
VENV_DIR=".venv"
# --- Helper Functions ---
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

print_info() {
    echo "[INFO] $1"
}

print_error() {
    echo "[ERROR] $1" >&2
}

prompt_user() {
    local message="$1"
    local default="${2:-y}"
    local prompt_text="$message "
    if [[ "$default" == "y" ]]; then
        prompt_text+="[Y/n]: "
    else
        prompt_text+="[y/N]: "
    fi

    while true; do
        read -p "$prompt_text" response
        response="${response:-$default}"
        if [[ "$response" =~ ^[Yy]$ ]]; then
            return 0
        elif [[ "$response" =~ ^[Nn]$ ]]; then
            return 1
        else
            echo "Please answer 'y' or 'n'."
        fi
    done
}

# --- Installation Steps ---
install_homebrew() {
    print_info "Homebrew is not installed. Attempting to install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [ $? -ne 0 ]; then
        print_error "Homebrew installation failed."
        print_error "Please visit https://brew.sh/ for manual installation instructions."
        exit 1
    fi
    print_info "Homebrew installed successfully."
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        print_info "Homebrew PATH updated for this session."
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        print_info "Homebrew PATH updated for this session."
    else
        print_error "Could not automatically add Homebrew to PATH. You may need to restart your terminal or manually configure it."
    fi
}

install_ffmpeg() {
    if ! command_exists ffmpeg; then
        print_info "FFmpeg not found. Installing FFmpeg using Homebrew..."
        if ! command_exists brew; then
            print_error "Homebrew is required to install FFmpeg but not found. Please install Homebrew first."
            if prompt_user "Do you want to try installing Homebrew now?"; then
                install_homebrew
                if ! command_exists brew; then
                    print_error "Homebrew installation failed or was not completed. Cannot proceed with FFmpeg installation."
                    return 1
                fi
            else
                print_error "FFmpeg installation skipped because Homebrew is not available. The application may not work without FFmpeg."
                return 1
            fi
        fi

        brew install ffmpeg
        if [ $? -ne 0 ]; then
            print_error "FFmpeg installation failed. Please try 'brew install ffmpeg' manually."
            exit 1
        fi
        print_info "FFmpeg installed successfully."
    else
        print_info "FFmpeg is already installed."
    fi
    return 0
}

setup_python_environment() {
    if [ ! -d "$VENV_DIR" ]; then
        print_info "Creating Python virtual environment '$VENV_DIR'..."
        "$PYTHON_EXECUTABLE" -m venv "$VENV_DIR"
        if [ $? -ne 0 ]; then
            print_error "Failed to create Python virtual environment."
            print_error "Ensure '$PYTHON_EXECUTABLE' is a valid Python 3 executable."
            exit 1
        fi
        print_info "Python virtual environment created."
    else
        print_info "Python virtual environment '$VENV_DIR' already exists."
    fi

    print_info "Activating virtual environment..."
    if [ -f "$VENV_DIR/bin/activate" ]; then
        source "$VENV_DIR/bin/activate"
        print_info "Virtual environment activated."
    else
        print_error "Virtual environment activation script not found at '$VENV_DIR/bin/activate'."
        exit 1
    fi
}

install_python_dependencies() {
    print_info "Installing required Python packages..."
    "$PYTHON_EXECUTABLE" -m pip install --upgrade pip
    if [ $? -ne 0 ]; then
        print_error "Failed to upgrade pip. Continuing with dependency installation."
    fi

    pip install faster-whisper pynput pyautogui customtkinter sounddevice numpy
    if [ $? -ne 0 ]; then
        print_error "Failed to install one or more Python dependencies."
        print_error "Please ensure Python 3 and pip are correctly installed and try installing manually:"
        print_error "pip install faster-whisper pynput pyautogui customtkinter sounddevice numpy"
        exit 1
    fi
    print_info "Python dependencies installed successfully."
}

# --- Main Script Execution ---
echo "=================================================="
echo " Speech-to-Text App Setup Script for macOS      "
echo "=================================================="
echo ""

if [[ "$(uname -s)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi
print_info "Running on macOS. Proceeding with setup..."

install_homebrew
install_ffmpeg
setup_python_environment
install_python_dependencies

echo ""
echo "=================================================="
echo " Setup Summary                                  "
echo "=================================================="
echo ""
echo " ✅ Python virtual environment '$VENV_DIR' created and activated."
echo " ✅ Required Python packages installed."
echo " ✅ FFmpeg is installed (or already present)."
echo ""
echo "Next Steps:"
echo "1. To run the application, you need to activate the virtual environment:"
echo "   source $VENV_DIR/bin/activate"
echo "2. Then, run the main Python script:"
echo "   python3 main.py"
echo ""
echo "Important Notes:"
echo " - Ensure your microphone is connected and set as the default input device."
echo " - You might need to grant microphone access to your Terminal application"
echo "   and/or the built application in macOS System Settings -> Privacy & Security."
echo ""
echo "To create a standalone macOS '.app' bundle, please refer to the PyInstaller command in the next step."
echo "=================================================="
echo ""
echo "Script finished."
