from gpiozero import LED
from time import sleep

# Configurer le GPIO 26 comme une sortie
gpio_26 = LED(26)

# Envoyer un signal haut (1) pendant 0.5 seconde
gpio_26.on()
sleep(0.5)
gpio_26.off()
