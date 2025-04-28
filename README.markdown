# Termux-is-Black

<a href='https://postimg.cc/m1QfQDP6' target='_blank'><img src='https://i.postimg.cc/m1QfQDP6/Chat-GPT-Image-28-Apr-2025-11-15-54.png' border='0' alt='Chat-GPT-Image-28-Apr-2025-11-15-54'/></a> <!-- Ersetze durch einen tatsächlichen Banner-Link, falls verfügbar -->

Willkommen bei **Termux-is-Black**, dem ultimativen Bash-Skript für Termux, das deine Terminal-Erfahrung auf Android revolutioniert! Dieses Skript bietet ein interaktives Menü mit leistungsstarken Tools für Python-Entwicklung, Systemverwaltung, Netzwerkanalyse, Backups und mehr. Entwickelt für die **MIB Main in Black**-Community, ist es sowohl für Anfänger als auch für Profis geeignet.

## 🌟 Überblick

`startup.sh` ist ein vielseitiges Bash-Skript, das Termux-Benutzern hilft, ihre Umgebung effizient zu verwalten. Es bietet:

- Ein farbiges, kategorisiertes Menü mit benutzerfreundlicher Navigation.
- Automatisierung von Python-Modul-Installationen und Skriptausführung (inkl. Debugging).
- Netzwerk- und Sicherheits-Tools wie Port-Scans und SSH-Verwaltung.
- Backup-, Git- und Update-Funktionen.
- Ein flexibles Plugin-System mit automatischer Synchronisation aus dem Repository.
- Anpassbare Themes und ein interaktives Tutorial für neue Nutzer.
- Sicherheitsprüfungen für Python-Skripte.

Ob du Python-Skripte debuggen, dein System aktualisieren oder eigene Plugins entwickeln möchtest – **Termux-is-Black** hat alles, was du brauchst!

## 🚀 Installation

1. **Termux vorbereiten**:
   - Installiere Termux aus dem F-Droid Store oder GitHub.
   - Aktualisiere die Pakete:
     ```bash
     pkg update && pkg upgrade -y
     ```

2. **Skript herunterladen**:
   - Lade `startup.sh` aus diesem Repository:
     ```bash
     wget https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/startup.sh -O ~/startup.sh
     ```
   - Mache es ausführbar:
     ```bash
     chmod +x ~/startup.sh
     ```

3. **Skript starten**:
   - Führe das Skript aus:
     ```bash
     ./startup.sh
     ```
   - Das Skript richtet sich automatisch für den Autostart ein und erstellt eine Konfigurationsdatei (`~/.termux_startup.conf`).

4. **Optional: Repository klonen**:
   - Wenn du das gesamte Repository (inkl. Plugins) nutzen möchtest:
     ```bash
     pkg install git
     git clone https://github.com/MrBlack-ctrl/Termux-is-Black.git
     cd Termux-is-Black
     chmod +x startup.sh
     ./startup.sh
     ```

## 🖥️ Verwendung

Nach dem Start von `./startup.sh` öffnet sich ein farbiges Menü, unterteilt in Kategorien:

### 🐍 Python-Optionen
1. **Py-Module Auto-Install**: Scannt Python-Skripte und installiert fehlende Module.
2. **Python Skript starten**: Führt Python-Skripte aus einem definierten Verzeichnis aus (mit Debugging via `pdb`).
3. **Py-Module Manuell**: Installiert Python-Module nach Benutzereingabe (z. B. `requests==2.28.1`).
4. **Py-Module Deinstallieren**: Entfernt angegebene Python-Module.

### 📦 pkg-Optionen
5. **Update System**: Aktualisiert alle Termux-Pakete (`pkg update && pkg upgrade`).
6. **Dateimanager**: Startet `mc` (Midnight Commander), falls installiert.
7. **Prozesse**: Zeigt Prozesse mit `htop`, falls installiert.
8. **Netzwerk Info**: Zeigt Netzwerkdetails mit `ifconfig`, falls installiert.
9. **Paket installieren**: Ermöglicht die manuelle Installation von Termux-Paketen.

### 🌐 Netzwerk & Sicherheit
10. **Netzwerk Scan**: Führt Ping-, TCP- oder UDP-Scans mit `nmap` durch.
11. **SSH-Server Verwaltung**: Startet, stoppt oder prüft den Status eines SSH-Servers.

### 💾 Backup, Git & Update
12. **Termux Backup**: Erstellt ein Backup von `~/` als `.tar.gz`-Datei.
13. **Git Helfer**: Verwaltet Git-Repositorys (Status, Pull, Commit, Push).
14. **Skript aktualisieren**: Lädt die neueste Version von `startup.sh` aus diesem Repository.

### ⚙️ Sonstiges
15. **.bashrc bearbeiten**: Öffnet `~/.bashrc` in `nano` zur Bearbeitung.
16. **Konfiguration bearbeiten**: Bearbeitet die Konfigurationsdatei (`~/.termux_startup.conf`) in `nano`.
17. **Interaktives Tutorial**: Bietet eine Einführung in die Hauptfunktionen.
18. **Beenden**: Beendet das Skript.

### 🔌 Plugins
19+. **Dynamische Plugins**: Führt benutzerdefinierte Plugins aus `~/.termux_is_black_plugins` aus.
24. **Plugins synchronisieren und Ordner öffnen**: Synchronisiert Plugins aus dem Repository und öffnet das Plugin-Verzeichnis.

Navigiere durch das Menü, indem du die entsprechende Nummer eingibst und mit Enter bestätigst.

## 🔍 Funktionsübersicht

Hier ist eine detaillierte Beschreibung aller Funktionen:

1. **Py-Module Auto-Install** (`pip`):
   - Scannt `.py`-Dateien in `PYTHON_SCRIPT_DIR` auf `import`-Anweisungen.
   - Installiert fehlende Module mit `pip`, ignoriert Standardmodule (z. B. `os`, `sys`).
   - Fährt bei Fehlern fort, um maximale Kompatibilität zu gewährleisten.

2. **Python Skript starten** (`python`):
   - Listet alle `.py`-Dateien in `PYTHON_SCRIPT_DIR`.
   - Führt das ausgewählte Skript mit der konfigurierten Python-Version aus.
   - Bietet eine Debugging-Option mit `pdb` (Eingabe `d`).
   - Prüft Skripte auf unsichere Imports (z. B. `os.system`, `subprocess`) und warnt den Benutzer.

3. **Py-Module Manuell** (`pip`):
   - Ermöglicht die Installation von Python-Modulen nach Benutzereingabe.
   - Unterstützt Versionsangaben (z. B. `requests==2.28.1`).

4. **Py-Module Deinstallieren** (`pip`):
   - Listet installierte Module und erlaubt deren Deinstallation.
   - Protokolliert alle Aktionen.

5. **Update System** (`pkg`):
   - Führt `pkg update && pkg upgrade -y` aus, um alle Termux-Pakete zu aktualisieren.
   - Zeigt eine Fortschrittsanzeige für langlaufende Operationen.

6. **Dateimanager** (`mc`):
   - Startet den Midnight Commander (`mc`), ein Terminal-basierter Dateimanager.
   - Installiert `mc`, wenn es fehlt (nach Bestätigung).

7. **Prozesse** (`htop`):
   - Zeigt laufende Prozesse mit `htop`, einem interaktiven Prozess-Viewer.
   - Installiert `htop`, wenn es fehlt.

8. **Netzwerk Info** (`ifconfig`):
   - Zeigt Netzwerkdetails (z. B. IP-Adressen) mit `ifconfig`.
   - Installiert `net-tools`, wenn es fehlt.

9. **Paket installieren** (`pkg`):
   - Ermöglicht die Eingabe von Paketnamen (z. B. `vim curl`) zur Installation mit `pkg install`.

10. **Netzwerk Scan** (`nmap`):
    - Führt einen Ping-, TCP- oder UDP-Scan mit `nmap` durch, um Geräte oder offene Ports im Netzwerk zu finden.
    - Erkennt automatisch das lokale Subnetz (z. B. `192.168.1.0/24`).

11. **SSH-Server Verwaltung** (`sshd`):
    - Startet, stoppt oder prüft den Status eines SSH-Servers.
    - Installiert `openssh`, wenn es fehlt.

12. **Termux Backup** (`tar`):
    - Erstellt ein komprimiertes Backup von `~/` in `~/storage/shared/termux_backups`.
    - Dateien werden mit Zeitstempel benannt (z. B. `termux_backup_20250428_123456.tar.gz`).

13. **Git Helfer**:
    - Verwaltet Git-Repositorys mit Optionen für:
      - `git status`: Zeigt den Status des Repositorys.
      - `git pull`: Holt Änderungen vom Remote-Repository.
      - `git commit`: Commited lokale Änderungen mit einer Nachricht.
      - `git push`: Pusht Änderungen zum Remote-Repository.

14. **Skript aktualisieren** (`github`):
    - Prüft, ob eine neuere Version von `startup.sh` im Repository verfügbar ist.
    - Nutzt `git pull` (in einem Git-Repository) oder `wget` (direkter Download).
    - Erstellt ein Backup und startet das aktualisierte Skript neu.

15. **.bashrc bearbeiten** (`nano`):
    - Öffnet `~/.bashrc` in `nano` zur Bearbeitung von Shell-Einstellungen.
    - Änderungen werden beim nächsten Termux-Start wirksam.

16. **Konfiguration bearbeiten** (`nano`):
    - Öffnet `~/.termux_startup.conf` in `nano` zur Bearbeitung.
    - Validiert Änderungen (z. B. Existenz von `PYTHON_SCRIPT_DIR`, gültiges `THEME`).

17. **Interaktives Tutorial**:
    - Bietet eine Schritt-für-Schritt-Einführung in wichtige Funktionen (Python-Skripte, System-Update, Netzwerk-Scan, Backup).
    - Ideal für neue Benutzer.

18. **Beenden**:
    - Beendet das Skript und entfernt die Autostart-Variable.

19+. **Dynamische Plugins**:
    - Lädt und führt benutzerdefinierte Bash-Skripte aus `~/.termux_is_black_plugins` aus.
    - Plugins müssen eine Funktion `run_<plugin_name>` definieren.

24. **Plugins synchronisieren und Ordner öffnen**:
    - Synchronisiert Plugins aus dem Repository (`https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/plugins/`).
    - Öffnet `~/.termux_is_black_plugins` in `mc` (falls installiert) oder zeigt es mit `ls`.

## ⚙️ Konfigurationsdatei

Die Konfigurationsdatei (`~/.termux_startup.conf`) wird beim ersten Start erstellt und enthält:

```bash
# Termux Startup Konfiguration
SCRIPT_NAME="startup.sh"
PYTHON_SCRIPT_DIR="$HOME/storage/shared/py"
PYTHON_CMD="python3"
BASHRC_FILE="$HOME/.bashrc"
AUTOSTART_MARKER="# AUTOSTART_TERMUX_SCRIPT_V1"
LOG_FILE="$HOME/termux_startup.log"
THEME="default" # Verfügbare Themes: default, dark, mib, light
PLUGIN_REPO_URL="https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/plugins/"
```

**Anpassungen**:
- **PYTHON_SCRIPT_DIR**: Ändere das Verzeichnis für Python-Skripte (Standard: `~/storage/shared/py`).
- **PYTHON_CMD**: Setze eine spezifische Python-Version (z. B. `python3.11`).
- **LOG_FILE**: Ändere den Speicherort für Logs.
- **THEME**: Wähle ein Farbschema (`default`, `dark`, `mib`, `light`).
- **PLUGIN_REPO_URL**: Ändere die URL für Plugin-Synchronisation, falls du ein anderes Repository nutzt.

Bearbeite die Datei mit Option 16 oder direkt:
```bash
nano ~/.termux_startup.conf
```

## 🔌 Plugin-System

Das Skript unterstützt benutzerdefinierte Plugins, die in `~/.termux_is_black_plugins` gespeichert werden. Plugins sind Bash-Skripte (`.sh`), die eine Funktion `run_<plugin_name>` definieren müssen. Beispiel:

```bash
# ~/.termux_is_black_plugins/hello.sh
run_hello() {
    echo "Hallo vom Hello-Plugin!"
    read -p "Weiter..."
}
```

### Automatische Plugin-Synchronisation
- Wähle Option 24, um Plugins automatisch aus dem Repository (`https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/plugins/`) herunterzuladen.
- Plugins werden in `~/.termux_is_black_plugins` gespeichert und im Menü als dynamische Optionen (ab 19) angezeigt.
- Lokale Plugins (manuell hinzugefügt) koexistieren mit synchronisierten Plugins.

### Plugins zum Repository hinzufügen
- Erstelle ein `plugins/`-Verzeichnis in deinem Repository und füge `.sh`-Dateien hinzu.
- Benutzer erhalten diese Plugins automatisch über Option 24.
- Beispiel-Repository-Struktur:
  ```
  Termux-is-Black/
  ├── startup.sh
  ├── README.md
  └── plugins/
      ├── hello.sh
      ├── backup.sh
  ```

**Tipp**: Community-Mitglieder können eigene Plugins erstellen und Pull Requests einreichen, um sie dem Repository hinzuzufügen!

## 🛠️ Fehlerbehebung

- **Skript startet nicht**: Stelle sicher, dass es ausführbar ist (`chmod +x startup.sh`) und die richtigen Pakete installiert sind (`pkg install wget git nano`).
- **Python-Skripte werden nicht gefunden**: Überprüfe, ob `PYTHON_SCRIPT_DIR` existiert und `.py`-Dateien enthält. Führe `termux-setup-storage` aus, falls nötig.
- **Plugin-Synchronisation fehlschlägt**: Prüfe die Internetverbindung und die Logs in `~/termux_startup.log`. Stelle sicher, dass das `plugins/`-Verzeichnis im Repository existiert.
- **Unsichere Python-Skripte**: Das Skript warnt vor potenziell gefährlichen Imports. Überprüfe Skripte manuell, bevor du sie ausführst.
- **Themes funktionieren nicht**: Stelle sicher, dass `THEME` in `~/.termux_startup.conf` auf `default`, `dark`, `mib` oder `light` gesetzt ist.

## 🌐 Community

Tritt der **MIB Main in Black**-Community bei, um Tipps, Plugins und Updates zu teilen!
- **Telegram-Gruppe**: [📢 MIB Main in Black](https://t.me/+Mde3XjyTPUFlMjQy)
- **Entwickler**: [🧑‍💻 Mr.Black](https://t.me/MrBlackHead01)
- **GitHub Issues**: Melde Bugs oder schlage neue Funktionen vor: [Issues](https://github.com/MrBlack-ctrl/Termux-is-Black/issues)

## 🤝 Mitwirken

Wir freuen uns über Beiträge! So kannst du helfen:
- **Plugins entwickeln**: Erstelle `.sh`-Dateien mit `run_<plugin_name>`-Funktionen und reiche sie als Pull Request ein.
- **Funktionen vorschlagen**: Öffne ein Issue mit deinen Ideen.
- **Dokumentation verbessern**: Aktualisiere diese README oder füge Tutorials hinzu.
- **Bugs melden**: Teile Fehler in der Telegram-Gruppe oder auf GitHub.

1. Forke das Repository.
2. Erstelle einen Branch (`git checkout -b feature/awesome-plugin`).
3. Commit deine Änderungen (`git commit -m "Add awesome plugin"`).
4. Pushe den Branch (`git push origin feature/awesome-plugin`).
5. Öffne einen Pull Request.

## 📜 Lizenz

Dieses Projekt ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE](LICENSE) für Details.

## 🙌 Danksagung

- **[🧑‍💻 Mr.Black](https://t.me/MrBlackHead01)** für die Vision, Leitung und Entwicklung des Projekts.
- **Walter, C3PO, Büchereule, Onkel iROBOT, by MEXX, LUCA und Nicolas** für ihren unermüdlichen Einsatz, in der [📢 MIB Main in Black](https://t.me/+Mde3XjyTPUFlMjQy)-Community für Ordnung zu sorgen und den Rücken freizuhalten.
- **MIB Main in Black**-Community für Inspiration und Feedback.
- Termux-Entwickler für die großartige Plattform.
- Alle Mitwirkenden, die Plugins, Ideen und Bugfixes beigesteuert haben.

---

**Termux-is-Black** – Dein Tor zur Macht des Terminals! 🚀
