import socket
import serial
from serial.tools import list_ports
import gpiod
import time
import select
import re

# ########### CONFIGURATION GPIO ###########
LASER_PINS = [17, 27, 22, 26]  # Exemple : GPIO 17, 27, 22
CHIP_NAME = "gpiochip0"  # Nom de la puce GPIO sur Raspberry Pi 5
INPUT_PIN = 23  # GPIO à surveiller pour détecter un "1"
JOYSTICK_UP_PIN = 5  # GPIO du joystick (haut)
JOYSTICK_DOWN_PIN = 6  # GPIO du joystick (bas)

# Initialisation des lignes GPIO
chip = gpiod.Chip(CHIP_NAME)
lines = [chip.get_line(pin) for pin in LASER_PINS]

for line in lines:
    line.request(consumer="life_control", type=gpiod.LINE_REQ_DIR_OUT)
    line.set_value(0)  # Éteindre tous les contrôles de vie par défaut

# Configuration de la ligne GPIO en entrée
input_line = chip.get_line(INPUT_PIN)
input_line.request(consumer="gpio_input", type=gpiod.LINE_REQ_DIR_IN)

# Configuration des entrées du joystick
joystick_up = chip.get_line(JOYSTICK_UP_PIN)
joystick_down = chip.get_line(JOYSTICK_DOWN_PIN)

joystick_up.request(consumer="joystick_up", type=gpiod.LINE_REQ_DIR_IN)
joystick_down.request(consumer="joystick_down", type=gpiod.LINE_REQ_DIR_IN)

# ########### PORTS SÉRIE ###########
PORT_VIE = '/dev/serial/by-path/platform-xhci-hcd.1-usb-0:2:1.0-port0'
BAUD_RATE_VIE = 9600
PORT_DUE = '/dev/serial/by-path/platform-xhci-hcd.0-usb-0:2:1.0'
BAUD_RATE_DUE = 9600

print(f"(python) Initialisation du port série : {PORT_DUE} à {BAUD_RATE_DUE} bauds")

try:
    vie_ser = serial.Serial(PORT_VIE, BAUD_RATE_VIE, timeout=0.1)
    print("(python) Port série pour la jauge de vie initialisé avec succès.")
except serial.SerialException as e:
    print(f"(python) Erreur lors de l'initialisation du port série pour la jauge de vie : {e}")
    exit(1)

try:
    ser_due = serial.Serial(PORT_DUE, BAUD_RATE_DUE, timeout=0.1)
    print("(python) Port série pour l'UNO initialisé avec succès.")
except serial.SerialException as e:
    print(f"(python) Erreur lors de l'initialisation du port série pour l'UNO : {e}")

    vie_ser.close()
    exit(1)
    
# ########### CONFIGURATION SERVEUR TCP ###########
SERVER_IP = '127.0.0.1'
SERVER_PORT = 12345

print(f"(python) Démarrage du serveur TCP sur {SERVER_IP}:{SERVER_PORT}...")
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((SERVER_IP, SERVER_PORT))
    sock.listen(1)
    print(f"(python) Serveur TCP en écoute sur {SERVER_IP}:{SERVER_PORT}...")
    
    client_sock, client_addr = sock.accept()
    print(f"(python) Connexion acceptée depuis {client_addr}.")

except socket.error as e:
    print(f"(python) Erreur lors de l'initialisation du serveur TCP : {e}")
    exit(1)

# ########### BOUCLE PRINCIPALE ###########
try:
    while True:
        ready_to_read, _, _ = select.select([ser_due, client_sock], [], [], 0.1)
        
        for ready in ready_to_read:
            if ready == ser_due:
                data_from_serial = ser_due.readline().decode('utf-8').strip()
                if data_from_serial:
                    print(f"(python) Données série reçues : {data_from_serial}")
                    try:
                        client_sock.sendall(data_from_serial.encode('utf-8'))
                        print(f"(python) Envoyé au client : {data_from_serial}")
                    except (BrokenPipeError, ConnectionResetError):
                        print("(python) Le client s'est déconnecté. En attente d'une nouvelle connexion...")
                        client_sock.close()
                        client_sock, client_addr = sock.accept()
                        print(f"(python) Nouvelle connexion acceptée depuis {client_addr}")

            if ready == client_sock:
                try:
                    data_from_client = client_sock.recv(1024).decode('utf-8').strip()
                    
                    if not data_from_client:
                        print("(python) Le client a fermé la connexion.")
                        client_sock.close()
                        client_sock, client_addr = sock.accept()
                        print(f"(python) Nouvelle connexion acceptée depuis {client_addr}")
                        continue  # On repart à la boucle principale

                    data_from_client = re.sub(r'[^\x20-\x7E]', '', data_from_client)
                    print(f"(python) Reçu du client : {data_from_client}")

                    if data_from_client.startswith('Life:'):
                        life_value = data_from_client.split(':')[1]
                        if life_value.isdigit() and 0 <= int(life_value) <= 8:
                            vie_ser.write(f"{life_value}\n".encode())
                            print(f"(python) Commande vie envoyée au système série : ---{life_value}---")
                            
                            response = vie_ser.readline().decode('utf-8').strip()
                            print(f"(python) Réponse du système série : {response if response else 'Aucune réponse reçue.'}")
                        else:
                            print(f"(python) Valeur de vie invalide : {life_value}")
                    else:
                        print(f"(python) Données invalides reçues : {data_from_client}")
                
                except socket.error:
                    print("(python) Erreur de lecture du socket.")

        gpio_value = input_line.get_value()
        if gpio_value == 1:
            try:
                client_sock.sendall("jump\n".encode('utf-8'))
                print("(python) Signal détecté, 'jump' envoyé au client.")
            except (BrokenPipeError, ConnectionResetError):
                print("(python) Impossible d'envoyer 'jump', le client s'est déconnecté.")
        
        if joystick_up.get_value() == 1:
            try:
                client_sock.sendall("up\n".encode('utf-8'))
                print("(python) Joystick haut détecté, 'up' envoyé au client.")
            except (BrokenPipeError, ConnectionResetError):
                print("(python) Impossible d'envoyer 'up', le client s'est déconnecté.")
            time.sleep(0.1)

        if joystick_down.get_value() == 1:
            try:
                client_sock.sendall("down\n".encode('utf-8'))
                print("(python) Joystick bas détecté, 'down' envoyé au client.")
            except (BrokenPipeError, ConnectionResetError):
                print("(python) Impossible d'envoyer 'down', le client s'est déconnecté.")
            time.sleep(0.1)

except KeyboardInterrupt:
    print("(python) Fermeture du programme.")
finally:
    # ########### LIBÉRATION DES RESSOURCES ###########
    for line in lines:
        line.set_value(0)
        line.release()
    input_line.release()
    joystick_up.release()
    joystick_down.release()
    chip.close()
    ser_due.close()
    client_sock.close()
    sock.close()
    print("(python) GPIO, port série et connexion TCP libérés.")
