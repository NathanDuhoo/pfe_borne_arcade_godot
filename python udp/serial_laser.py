import socket
import serial
import re

# Configuration du port série pour les lasers
PORT_LASERS = 'COM6'  # Remplace par ton port série
BAUD_RATE_LASERS = 9600

# Initialisation du port série
try:
    laser_ser = serial.Serial(PORT_LASERS, BAUD_RATE_LASERS, timeout=0.1)
    print(f"Port série {PORT_LASERS} pour les lasers initialisé avec succès.")
except serial.SerialException as e:
    print(f"Erreur lors de l'initialisation du port série : {e}")
    exit(1)

# Configuration du client TCP
SERVER_IP = '127.0.0.1'  # Adresse IP du serveur Godot
SERVER_PORT = 12346      # Port du serveur Godot

# Connexion au serveur TCP
try:
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client_socket.connect((SERVER_IP, SERVER_PORT))
    print(f"Connecté au serveur TCP sur {SERVER_IP}:{SERVER_PORT}")
except socket.error as e:
    print(f"Erreur lors de la connexion au serveur TCP : {e}")
    laser_ser.close()
    exit(1)

# Fonction pour traiter les données reçues de Godot
def process_data(data):
    """
    Traite les données reçues de Godot et envoie les commandes au laser.
    :param data: str, données reçues de Godot
    """
    data = re.sub(r'[^0-5]', '', data)  # Filtrer pour ne garder que les chiffres entre 0 et 5
    if data.isdigit() and 0 <= int(data) <= 5:
        command = int(data)
        laser_ser.write(f"{command}\n".encode('utf-8'))  # Envoyer la commande au port série
        print(f"Commande envoyée au laser : {command}")
    else:
        print(f"Données invalides reçues : {data}")

# Boucle principale pour gérer la communication avec le serveur
try:
    while True:
        # Recevoir les données du serveur Godot
        data = client_socket.recv(1024).decode('utf-8').strip()
        if not data:
            print("Connexion fermée par le serveur.")
            break
        print(f"Données reçues de Godot : {data}")
        process_data(data)

except KeyboardInterrupt:
    print("\nArrêt du client TCP.")
except Exception as e:
    print(f"Erreur : {e}")
finally:
    laser_ser.close()
    client_socket.close()
    print("Ressources libérées.")
