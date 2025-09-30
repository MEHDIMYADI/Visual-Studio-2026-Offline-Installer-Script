# Visual Studio 2026 Offline Installer Script

A Windows batch script to automate the process of downloading, updating, and running **Visual Studio 2026** in **offline layout mode**.  
Currently based on **Insider builds** – the script will be updated once the **official release (RTM)** is available.  

<img width="266" height="223" alt="image" src="https://github.com/user-attachments/assets/2eb57715-7edc-4b6c-88d1-7830f4d3bffd" />

---

## ✨ Features
- ✅ Choose edition (Enterprise / Professional / Community)
- ✅ Automatically download the latest Visual Studio 2026 bootstrapper
- ✅ Detect and update if a newer bootstrapper version exists
- ✅ Create or update an **offline layout** (resumes if interrupted)
- ✅ Launch Visual Studio Installer in GUI mode from the offline layout
- ✅ Detailed log file (`VSInstaller.log`) for troubleshooting

---

## 📂 Folder Structure
- `VSInstaller.bat` → Main script  
- `VSInstaller.log` → Log file (auto-generated)  
- `VSLayout\` → All offline installer files  

---

## 🚀 Usage
1. Clone or download this repository.
2. Open **Command Prompt as Administrator**.
3. Run:
   ```bat
   VSInstaller.bat
