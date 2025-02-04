#!/bin/sh

chmod +x export/Squash\ the\ Creeps\ \(3D\).arm64
chmod +x export/Squash\ the\ Creeps\ \(3D\).sh

./export/Squash\ the\ Creeps\ \(3D\).sh &


# Lancer le script Python après la pause de 3 secondes
python ./python\ udp/tcp_for_serial.py &