import customtkinter
import threading
import pyautogui
import sounddevice as sd
import numpy as np
import queue
import faster_whisper
from pynput import keyboard
import os

# --- Configuration ---
MODEL_SIZE = "base"     # "base" is a good balance of speed and accuracy
DEVICE = "cpu"          # Use CPU for Intel Mac Mini stability
QUANTIZATION = "int8"
HOTKEY_KEY = keyboard.Key.ctrl_l
SAMPLE_RATE = 16000

# --- Global Variables ---
is_recording = False
audio_queue = queue.Queue()
stt_model = None
app = None
status_label = None
audio_stream = None
hotkey_listener = None

# --- Core Logic ---

def audio_callback(indata, frames, time_info, status):
    """Collects audio only when is_recording is True."""
    if is_recording:
        audio_queue.put(indata.copy())

def update_status(text, color="white"):
    """Updates the GUI status label safely."""
    if status_label:
        status_label.configure(text=text, text_color=color)
        if app:
            app.update_idletasks()

def transcribe_and_type():
    """Processes the full audio buffer after key release and types it."""
    global stt_model
    update_status("PROCESSING...", "orange")
    
    audio_chunks = []
    while not audio_queue.empty():
        audio_chunks.append(audio_queue.get())
    
    if not audio_chunks:
        update_status("READY", "green")
        return

    try:
        # Combine all audio from the press-and-hold session
        audio_data = np.concatenate(audio_chunks, axis=0).flatten()
        
        # Transcribe the whole segment
        segments, _ = stt_model.transcribe(audio_data, language="en")
        full_text = "".join([s.text for s in segments]).strip()
        
        if full_text:
            print(f"Typed: {full_text}")
            pyautogui.write(full_text + " ", interval=0.01)
            
    except Exception as e:
        print(f"Transcription error: {e}")
    
    update_status("READY", "green")

# --- Hotkey Event Handlers ---

def on_press(key):
    global is_recording
    if key == HOTKEY_KEY:
        if not is_recording:
            is_recording = True
            # Flush any old audio noise
            while not audio_queue.empty():
                try: audio_queue.get_nowait()
                except: break
            
            update_status("LISTENING...", "red")
            print("Held: Recording...")

def on_release(key):
    global is_recording
    if key == HOTKEY_KEY:
        if is_recording:
            is_recording = False
            print("Released: Processing...")
            # Run transcription in a background thread so the GUI stays responsive
            threading.Thread(target=transcribe_and_type, daemon=True).start()

def start_hotkey_listener():
    """Starts the keyboard listener."""
    global hotkey_listener
    hotkey_listener = keyboard.Listener(on_press=on_press, on_release=on_release)
    hotkey_listener.start()

# --- Main Application Setup ---

def setup_gui():
    global app, status_label, stt_model, audio_stream

    app = customtkinter.CTk()
    app.geometry("250x120")
    app.title("STT Hold-to-Talk")
    
    # Uncomment the line below to hide the window once you know it's working
    # app.withdraw() 

    status_label = customtkinter.CTkLabel(app, text="Initializing...", font=("Helvetica", 14, "bold"))
    status_label.pack(expand=True, pady=20)

    def load_model():
        global stt_model
        print(f"Loading {MODEL_SIZE} model on {DEVICE}...")
        stt_model = faster_whisper.WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=QUANTIZATION)
        update_status("READY", "green")

    # Load model in background
    threading.Thread(target=load_model, daemon=True).start()

    # Initialize Mic
    try:
        audio_stream = sd.InputStream(samplerate=SAMPLE_RATE, channels=1, callback=audio_callback)
        audio_stream.start()
    except Exception as e:
        print(f"Mic Error: {e}")
        update_status("MIC ERROR", "red")

    # Start Keyboard Listener
    start_hotkey_listener()
    
    app.mainloop()

if __name__ == "__main__":
    setup_gui()
