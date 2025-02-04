#!/bin/sh

# Fermer tout processus Python existant
sudo pkill -f python

# Donner les permissions d'exécution nécessaires
chmod +x /home/yannp/monjeu/pfe_borne_arcade_godot/export/BillieBustUpArcade.arm64
chmod +x /home/yannp/monjeu/pfe_borne_arcade_godot/export/BillieBustUpArcade.sh

# Lancer l'application (jeu) en arrière-plan
/home/yannp/monjeu/pfe_borne_arcade_godot/export/BillieBustUpArcade.sh --rendering-driver opengl3 &

# Lancer le script Python en arrière-plan
python "/home/yannp/monjeu/pfe_borne_arcade_godot/python udp/tcp_for_serial.py" &

# Attendre que l'application principale (le jeu) se termine
wait $!