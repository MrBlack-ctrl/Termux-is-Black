# Termux-is-Black

**Willkommen zu Termux-is-Black**, einem leistungsstarken Bash-Skript, das Termux-Nutzern hilft, ihre Umgebung zu verwalten, Python-Skripte auszuführen, Systemressourcen zu überwachen und vieles mehr. Entwickelt von **Mr.Black** unter der Schirmherrschaft von **Black-Enterprises**, ist dieses Projekt für die Community der Telegram-Gruppe **MIB Main in Black** gedacht. Kontaktiere mich unter **@MrBlackHead01** auf Telegram für Fragen, Feedback oder Vorschläge!

Dieses Skript automatisiert häufige Aufgaben in Termux, wie die Installation von Paketen, das Verwalten von Python-Modulen, das Erstellen von Backups, das Verwalten eines SSH-Servers und vieles mehr. Es ist ideal für Anfänger und Profis, die ihre Termux-Umgebung effizient nutzen möchten.

---

## Inhaltsverzeichnis

- [Funktionen](#funktionen)
- [Voraussetzungen](#voraussetzungen)
- [Installation](#installation)
- [Verwendung](#verwendung)
- [Python-Skripte](#python-skripte)
- [Konfigurationsdatei](#konfigurationsdatei)
- [Funktionsübersicht](#funktionsübersicht)
- [Fehlerbehebung](#fehlerbehebung)
- [Kontakt und Community](#kontakt-und-community)
- [Lizenz](#lizenz)

---

## Funktionen

`Termux-is-Black` bietet eine Vielzahl von Funktionen, die deine Termux-Erfahrung verbessern:

- **Systemverwaltung**:
  - Aktualisiere und upgrade Termux-Pakete mit einem Klick.
  - Installiere Pakete manuell oder prüfe, ob Tools wie `mc`, `htop` oder `nmap` verfügbar sind.
  - Zeige detaillierte Systeminformationen (Gerät, Android-Version, Speicher, RAM, etc.).

- **Python-Unterstützung**:
  - Scanne Python-Skripte auf benötigte Module und installiere diese automatisch.
  - Starte Python-Skripte direkt aus einem benutzerdefinierten Verzeichnis.
  - Verwalte Python-Module manuell (Installation und Deinstallation, inkl. Versionsangaben).

- **Netzwerk- und Sicherheitsfunktionen**:
  - Führe einfache Netzwerkscans mit `nmap` durch.
  - Verwalte einen SSH-Server (Starten, Stoppen, Status prüfen).

- **Backup und Git**:
  - Erstelle Backups deiner Termux-Umgebung als komprimierte Archive.
  - Verwalte Git-Repositorys (Status, Pull, Commit, Push).
  - Aktualisiere das Skript direkt von diesem GitHub-Repository.

- **Benutzerfreundlichkeit**:
  - Farbiges, interaktives Menü mit klaren Optionen.
  - Logging aller Aktionen und Fehler in einer Logdatei.
  - Konfigurationsdatei für benutzerdefinierte Einstellungen.
  - Fortschrittsanzeige für langlaufende Befehle.

---

## Voraussetzungen

Um `Termux-is-Black` zu verwenden, benötigst du:

- Ein Android-Gerät mit **Termux** installiert (verfügbar im Google Play Store oder über F-Droid).
- Grundlegende Kenntnisse der Termux-Befehlszeile.
- Internetverbindung für die Installation und Updates.
- Speicherzugriff für Python-Skripte und Backups:
  ```bash
  termux-setup-storage
  ```

---

## Installation

Folge diesen Schritten, um `Termux-is-Black` zu installieren:

### Option 1: Installation über Git
1. Installiere `git` in Termux:
   ```bash
   pkg install git
   ```
2. Klone das Repository:
   ```bash
   git clone https://github.com/MrBlack-ctrl/Termux-is-Black.git
   ```
3. Wechsle in das Verzeichnis und mache das Skript ausführbar:
   ```bash
   cd Termux-is-Black
   chmod +x startup.sh
   ```
4. Starte das Skript:
   ```bash
   ./startup.sh
   ```

### Option 2: Direkter Download
1. Installiere `wget`:
   ```bash
   pkg install wget
   ```
2. Lade das Skript herunter:
   ```bash
   wget https://raw.githubusercontent.com/MrBlack-ctrl/Termux-is-Black/main/startup.sh
   ```
3. Mache das Skript ausführbar und starte es:
   ```bash
   chmod +x startup.sh
   ./startup.sh
   ```

### Nach der Installation
- Beim ersten Start richtet das Skript einen Autostart in `~/.bashrc` ein, sodass es bei jedem Termux-Start automatisch läuft.
- Eine Konfigurationsdatei (`~/.termux_startup.conf`) wird erstellt, die du anpassen kannst (siehe [Konfigurationsdatei](#konfigurationsdatei)).
- Alle Aktionen und Fehler werden in `~/termux_startup.log` protokolliert.

---

## Verwendung

Nach dem Start von `./startup.sh` öffnet sich ein farbiges Menü mit den folgenden Optionen:

1. **Update System**: Aktualisiert und upgraded alle Termux-Pakete (`pkg update && pkg upgrade`).
2. **Dateimanager**: Startet `mc` (Midnight Commander), falls installiert.
3. **Prozesse**: Zeigt Prozesse mit `htop`, falls installiert.
4. **Netzwerk Info**: Zeigt Netzwerkdetails mit `ifconfig`, falls installiert.
5. **Paket installieren**: Ermöglicht die manuelle Installation von Termux-Paketen.
6. **Py-Module Auto-Install**: Scannt Python-Skripte und installiert fehlende Module.
7. **Python Skript starten**: Listet und führt Python-Skripte aus einem definierten Verzeichnis aus.
8. **Py-Module Manuell**: Installiert Python-Module nach Benutzereingabe (z. B. `requests==2.28.1`).
9. **Py-Module Deinstallieren**: Entfernt angegebene Python-Module.
10. **Git Helfer**: Verwaltet Git-Repositorys (Status, Pull, Commit, Push).
11. **Netzwerk Scan**: Führt einen Ping-Scan mit `nmap` durch.
12. **.bashrc bearbeiten**: Öffnet `~/.bashrc` in `nano` zur Bearbeitung.
13. **Termux Backup**: Erstellt ein Backup von `~/` als `.tar.gz`-Datei.
14. **SSH-Server Verwaltung**: Startet, stoppt oder prüft den Status eines SSH-Servers.
15. **Skript aktualisieren**: Lädt die neueste Version von `startup.sh` aus diesem Repository.
16. **Beenden**: Beendet das Skript.

Navigiere durch das Menü, indem du die entsprechende Nummer eingibst und mit Enter bestätigst.

---

## Python-Skripte

Um Python-Skripte mit `Termux-is-Black` auszuführen, platziere sie im richtigen Verzeichnis:

1. **Standardverzeichnis**:
   - Das Skript sucht nach Python-Skripten in `~/storage/shared/py` (definiert in `~/.termux_startup.conf` als `PYTHON_SCRIPT_DIR`).
   - Stelle sicher, dass der Speicherzugriff aktiviert ist:
     ```bash
     termux-setup-storage
     ```
   - Erstelle den Ordner, falls er nicht existiert:
     ```bash
     mkdir -p ~/storage/shared/py
     ```

2. **Skripte platzieren**:
   - Kopiere deine `.py`-Dateien in `~/storage/shared/py`, z. B.:
     ```bash
     cp my_script.py ~/storage/shared/py/
     ```
   - Stelle sicher, dass die Skripte ausführbar sind (optional):
     ```bash
     chmod +x ~/storage/shared/py/my_script.py
     ```

3. **Module automatisch installieren**:
   - Wähle Option `6` (Py-Module Auto-Install), um benötigte Module zu scannen und zu installieren.
   - Das Skript erkennt `import`-Anweisungen und ignoriert Standardmodule wie `os` oder `sys`.

4. **Skripte starten**:
   - Wähle Option `7` (Python Skript starten), um eine Liste der `.py`-Dateien in `~/storage/shared/py` zu sehen.
   - Gib die Nummer des gewünschten Skripts ein, und es wird ausgeführt.

**Tipp**: Wenn du ein anderes Verzeichnis für Python-Skripte verwenden möchtest, bearbeite `PYTHON_SCRIPT_DIR` in `~/.termux_startup.conf`.

---

## Konfigurationsdatei

Die Konfigurationsdatei (`~/.termux_startup.conf`) wird beim ersten Start erstellt und enthält:

```bash
# Termux Startup Konfiguration
SCRIPT_NAME="startup.sh"
PYTHON_SCRIPT_DIR="$HOME/storage/shared/py"
PYTHON_CMD="python3"
BASHRC_FILE="$HOME/.bashrc"
AUTOSTART_MARKER="# AUTOSTART_TERMUX_SCRIPT_V1"
LOG_FILE="$HOME/termux_startup.log"
```

**Anpassungen**:
- Ändere `PYTHON_SCRIPT_DIR`, um ein anderes Verzeichnis für Python-Skripte zu verwenden.
- Setze `PYTHON_CMD` auf z. B. `python3.11`, wenn du eine spezifische Python-Version nutzt.
- Bearbeite `LOG_FILE`, um Logs an einen anderen Ort zu schreiben.

Bearbeite die Datei mit:
```bash
nano ~/.termux_startup.conf
```

---

## Funktionsübersicht

Hier ist eine detaillierte Beschreibung jeder Funktion:

1. **Update System** (`pkg`):
   - Führt `pkg update && pkg upgrade -y` aus, um alle Termux-Pakete zu aktualisieren.
   - Zeigt eine Fortschrittsanzeige für langlaufende Operationen.

2. **Dateimanager** (`mc`):
   - Startet den Midnight Commander (`mc`), ein Terminal-basierter Dateimanager.
   - Installiert `mc`, wenn es fehlt (nach Bestätigung).

3. **Prozesse** (`htop`):
   - Zeigt laufende Prozesse mit `htop`, einem interaktiven Prozess-Viewer.
   - Installiert `htop`, wenn es fehlt.

4. **Netzwerk Info** (`ifconfig`):
   - Zeigt Netzwerkdetails (z. B. IP-Adressen) mit `ifconfig`.
   - Installiert `net-tools`, wenn es fehlt.

5. **Paket installieren** (`pkg`):
   - Ermöglicht die Eingabe von Paketnamen (z. B. `vim curl`) zur Installation mit `pkg install`.

6. **Py-Module Auto-Install**:
   - Scannt `.py`-Dateien in `PYTHON_SCRIPT_DIR` auf `import`-Anweisungen.
   - Installiert fehlende Module mit `pip`, ignoriert Standardmodule.
   - Fährt bei Fehlern fort, um maximale Kompatibilität zu gewährleisten.

7. **Python Skript starten**:
   - Listet alle `.py`-Dateien in `PYTHON_SCRIPT_DIR`.
   - Führt das ausgewählte Skript mit der konfigurierten Python-Version aus.

8. **Py-Module Manuell** (`pip`):
   - Ermöglicht die Installation von Python-Modulen nach Benutzereingabe.
   - Unterstützt Versionsangaben (z. B. `requests==2.28.1`).

9. **Py-Module Deinstallieren** (`pip`):
   - Listet installierte Module und erlaubt deren Deinstallation.
   - Protokolliert alle Aktionen.

10. **Git Helfer**:
    - Verwaltet Git-Repositorys mit Optionen für:
      - `git status`: Zeigt den Status des Repositorys.
      - `git pull`: Holt Änderungen vom Remote-Repository.
      - `git commit`: Commited lokale Änderungen mit einer Nachricht.
      - `git push`: Pusht Änderungen zum Remote-Repository.

11. **Netzwerk Scan** (`nmap`):
    - Führt einen Ping-Scan mit `nmap` durch, um Geräte im Netzwerk zu finden.
    - Erkennt automatisch das lokale Subnetz (z. B. `192.168.1.0/24`).

12. **.bashrc bearbeiten** (`nano`):
    - Öffnet `~/.bashrc` in `nano` zur Bearbeitung von Shell-Einstellungen.
    - Änderungen werden beim nächsten Termux-Start wirksam.

13. **Termux Backup** (`tar`):
    - Erstellt ein komprimiertes Backup von `~/` in `~/storage/shared/termux_backups`.
    - Dateien werden mit Zeitstempel benannt (z. B. `termux_backup_20250428_123456.tar.gz`).

14. **SSH-Server Verwaltung** (`sshd`):
    - Startet, stoppt oder prüft den Status eines SSH-Servers.
    - Installiert `openssh`, wenn es fehlt.

15. **Skript aktualisieren** (`github`):
    - Prüft, ob eine neuere Version von `startup.sh` im Repository verfügbar ist.
    - Nutzt `git pull` (in einem Git-Repository) oder `wget` (direkter Download).
    - Erstellt ein Backup und startet das aktualisierte Skript neu.

16. **Beenden**:
    - Beendet das Skript und entfernt die Autostart-Variable.

---

## Fehlerbehebung

- **Skript startet nicht**:
  - Stelle sicher, dass es ausführbar ist: `chmod +x startup.sh`.
  - Prüfe, ob Bash installiert ist: `pkg install bash`.

- **Python-Skripte werden nicht gefunden**:
  - Überprüfe, ob `PYTHON_SCRIPT_DIR` (z. B. `~/storage/shared/py`) existiert und `.py`-Dateien enthält.
  - Stelle sicher, dass Speicherzugriff aktiviert ist: `termux-setup-storage`.

- **Module werden nicht installiert**:
  - Prüfe, ob `pip` installiert ist: `python -m ensurepip --upgrade`.
  - Überprüfe die Internetverbindung.
  - Schaue in `~/termux_startup.log` nach Fehlermeldungen.

- **Update-Funktion schlägt fehl**:
  - Stelle sicher, dass `git` oder `wget` installiert ist.
  - Prüfe die Internetverbindung.
  - Wenn du kein Git-Repository verwendest, wird die direkte URL (`RAW_SCRIPT_URL`) genutzt.

- **Logfile ist leer oder fehlt**:
  - Überprüfe den Pfad in `~/.termux_startup.conf` (`LOG_FILE`).
  - Stelle sicher, dass das Verzeichnis schreibbar ist.

Für weitere Hilfe, kontaktiere mich in der Telegram-Gruppe oder direkt unter **@MrBlackHead01**.

---

## Kontakt und Community

`Termux-is-Black` wurde von **Mr.Black** für die **MIB Main in Black** Community entwickelt. Tritt unserer Telegram-Gruppe bei, um Updates, Tipps und Unterstützung zu erhalten:

- **Telegram-Gruppe**: 🕵️‍♂️ [MIB Main in Black](https://t.me/+Mde3XjyTPUFlMjQy)  
- **Kontakt**: [@MrBlackHead01](https://t.me/MrBlackHead01)  
- **Firma**: Black-Enterprises

Wir freuen uns auf dein Feedback, Fehlerberichte oder Vorschläge für neue Funktionen! Öffne ein [Issue](https://github.com/MrBlack-ctrl/Termux-is-Black/issues) oder sende eine Nachricht in der Gruppe.

---

## Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert. Siehe die [LICENSE](LICENSE)-Datei für Details.

---

**Entwickelt mit 💪 von Mr.Black für Black-Enterprises und die MIB Main in Black Community!**
