
import tkinter as tk
from tkinter import ttk
from pynvml import *
import time
import threading
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from matplotlib.figure import Figure

# Try to initialize NVML, else use mock data
use_mock = False
try:
    nvmlInit()
    handle = nvmlDeviceGetHandleByIndex(0)
except:
    use_mock = True

def get_gpu_info():
    if use_mock:
        return {
            "name": "Laptop GPU RTX 3050 Ti",
            "temp": 55,
            "util": (int(time.time()) * 3) % 100,  # Varying mock data
            "mem_used": 2200,
            "mem_total": 8192
        }
    else:
        name = nvmlDeviceGetName(handle).decode("utf-8")
        temp = nvmlDeviceGetTemperature(handle, NVML_TEMPERATURE_GPU)
        util = nvmlDeviceGetUtilizationRates(handle).gpu
        mem_info = nvmlDeviceGetMemoryInfo(handle)
        mem_used = mem_info.used // (1024 * 1024)
        mem_total = mem_info.total // (1024 * 1024)
        return {
            "name": name,
            "temp": temp,
            "util": util,
            "mem_used": mem_used,
            "mem_total": mem_total
        }

# GUI Setup
root = tk.Tk()
root.title("GPU Monitor")
root.geometry("350x400")
root.resizable(False, False)

style = ttk.Style()
style.theme_use("clam")

frame = ttk.Frame(root, padding=10)
frame.pack(fill="both", expand=True)

gpu_label = ttk.Label(frame, text="GPU:", font=("Helvetica", 12))
gpu_label.pack(pady=5)

temp_label = ttk.Label(frame, text="Temperature:", font=("Helvetica", 12))
temp_label.pack(pady=5)

util_label = ttk.Label(frame, text="Utilization:", font=("Helvetica", 12))
util_label.pack(pady=5)

mem_label = ttk.Label(frame, text="Memory:", font=("Helvetica", 12))
mem_label.pack(pady=5)

# Matplotlib Graph
fig = Figure(figsize=(3.5, 2), dpi=100)
ax = fig.add_subplot(111)
ax.set_title("GPU Utilization (%)")
ax.set_ylim(0, 100)
line, = ax.plot([], [], color='blue')
x_data, y_data = [], []

canvas = FigureCanvasTkAgg(fig, master=frame)
canvas.draw()
canvas.get_tk_widget().pack(pady=10)

# Update function
def update_info():
    i = 0
    while True:
        info = get_gpu_info()
        gpu_label.config(text=f"GPU: {info['name']}")
        temp_label.config(text=f"Temperature: {info['temp']}°C")
        util_label.config(text=f"Utilization: {info['util']}%")
        mem_label.config(text=f"Memory: {info['mem_used']} / {info['mem_total']} MB")

        x_data.append(i)
        y_data.append(info['util'])
        if len(x_data) > 30:
            x_data.pop(0)
            y_data.pop(0)
        line.set_data(x_data, y_data)
        ax.set_xlim(max(0, i - 30), i + 1)
        canvas.draw()

        i += 1
        time.sleep(1)

# Start background update thread
threading.Thread(target=update_info, daemon=True).start()

root.mainloop()
