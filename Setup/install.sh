#! /bin/bash

#check if there's an argument on the command line
if [[ -f /home/pi/quiet_mode ]]
then
    quiet_mode=1
else
    quiet_mode=0
fi

if [[ "$quiet_mode" -eq "0" ]]
then
    echo "  _____            _                                ";
    echo " |  __ \          | |                               ";
    echo " | |  | | _____  _| |_ ___ _ __                     ";
    echo " | |  | |/ _ \ \/ / __/ _ \ '__|                    ";
    echo " | |__| |  __/>  <| ||  __/ |                       ";
    echo " |_____/ \___/_/\_\\__\___|_| _        _            ";
    echo " |_   _|         | |         | |      (_)           ";
    echo "   | |  _ __   __| |_   _ ___| |_ _ __ _  ___  ___  ";
    echo "   | | | '_ \ / _\ | | | / __| __| '__| |/ _ \/ __|";
    echo "  _| |_| | | | (_| | |_| \__ \ |_| |  | |  __/\__ \ ";
    echo " |_____|_| |_|\__,_|\__,_|___/\__|_|  |_|\___||___/ ";
    echo "                                                    ";
    echo "                                                    ";
    echo " "
fi


echo "  ______  _____   _____  _____  ______  _____ "
echo " |  ____ |     | |_____]   |   |  ____ |     |"
echo " |_____| |_____| |       __|__ |_____| |_____|"
echo " "
echo "Welcome to GoPiGo Installer."
echo "Please ensure internet connectivity before running this script."
if [[ "$quiet_mode" -eq "0" ]]
then
echo "NOTE: Raspberry Pi wil reboot after completion."
fi
echo "Special thanks to Joe Sanford at Tufts University.  This script was derived from his work.  Thank you Joe!"
echo " "

if [[ $EUID -ne 0 ]]; then
	echo "FAIL!  This script must be run as such: sudo ./install.sh"
	exit 1
fi
echo " "
if [[ "$quiet_mode" -eq 0 ]]
then
    echo "Press ENTER to begin..."
fi
# read

SCRIPTDIR="$(readlink -f $(dirname $0))"
echo "Installing GoPiGo software in $SCRIPTDIR"

echo " "
echo "Check for internet connectivity..."
echo "=================================="
wget -q --tries=2 --timeout=20 http://raspberrypi.org 
if [ $? -eq 0 ];then
	echo "Connected"
	sudo rm index.html
else
	echo "Unable to Connect, try again !!!"
	exit 0
fi

echo " "
echo "Installing Dependencies"
echo "======================="
sudo apt-get install python-pip git libi2c-dev python-serial python-rpi.gpio i2c-tools python-smbus arduino minicom libnss-mdns python-dev -y
sudo pip install -U RPi.GPIO

echo "Dependencies installed"

#Copy Software Servo
cp -R ../Firmware/SoftwareServo/ /usr/share/arduino/libraries/

chmod +x gopigo 
cp gopigo /usr/bin

cd ../Software/Python
python setup.py install

# Install the DHT library
cd sensor_examples/dht/Adafruit_Python_DHT
sudo python setup.py install
cd ../../../../../Setup/

git clone git://git.drogon.net/wiringPi
cd wiringPi
./build
echo "wiringPi Installed"

echo " "
echo "Removing blacklist from /etc/modprobe.d/raspi-blacklist.conf . . ."
echo "=================================================================="
if grep -q "#blacklist i2c-bcm2708" /etc/modprobe.d/raspi-blacklist.conf; then
	echo "I2C already removed from blacklist"
else
	sudo sed -i -e 's/blacklist i2c-bcm2708/#blacklist i2c-bcm2708/g' /etc/modprobe.d/raspi-blacklist.conf
	echo "I2C removed from blacklist"
fi
if grep -q "#blacklist spi-bcm2708" /etc/modprobe.d/raspi-blacklist.conf; then
	echo "SPI already removed from blacklist"
else
	sudo sed -i -e 's/blacklist spi-bcm2708/#blacklist spi-bcm2708/g' /etc/modprobe.d/raspi-blacklist.conf
	echo "SPI removed from blacklist"
fi

#Adding in /etc/modules
echo " "
echo "Adding I2C-dev and SPI-dev in /etc/modules . . ."
echo "================================================"
if grep -q "i2c-dev" /etc/modules; then
	echo "I2C-dev already there"
else
	echo i2c-dev >> /etc/modules
	echo "I2C-dev added"
fi
if grep -q "i2c-bcm2708" /etc/modules; then
	echo "i2c-bcm2708 already there"
else
	echo i2c-bcm2708 >> /etc/modules
	echo "i2c-bcm2708 added"
fi
if grep -q "spi-dev" /etc/modules; then
	echo "spi-dev already there"
else
	echo spi-dev >> /etc/modules
	echo "spi-dev added"
fi

echo " "
echo "Making I2C changes in /boot/config.txt . . ."
echo "================================================"

echo dtparam=i2c1=on >> /boot/config.txt
echo dtparam=i2c_arm=on >> /boot/config.txt

#Adding ARDUINO setup files
echo " "
echo "Making changes to Arduino . . ."
echo "==============================="
cd /tmp
wget http://project-downloads.drogon.net/gertboard/avrdude_5.10-4_armhf.deb
sudo dpkg -i avrdude_5.10-4_armhf.deb
sudo chmod 4755 /usr/bin/avrdude

cd /tmp
wget http://project-downloads.drogon.net/gertboard/setup.sh
chmod +x setup.sh
sudo ./setup.sh

#Enabling serial port in Arduino IDE
crontab -l > file; echo '@reboot ln -sf /dev/ttyAMA0 /dev/ttyS0' >> file; crontab file
rm file

sudo rm -r /tmp/di_update

sudo adduser pi i2c
sudo chmod +x $SCRIPTDIR/../Software/Scratch/GoPiGo_Scratch_Scripts/*.sh

if [[ "$quiet_mode" -eq 0 ]]
then
    echo " "
    echo "Please restart the Raspberry Pi for the changes to take effect"
    echo " "
    echo "Please restart to implement changes!"
    echo "  _____  ______  _____ _______       _____ _______ "
    echo " |  __ \|  ____|/ ____|__   __|/\   |  __ \__   __|"
    echo " | |__) | |__  | (___    | |  /  \  | |__) | | |   "
    echo " |  _  /|  __|  \___ \   | | / /\ \ |  _  /  | |   "
    echo " | | \ \| |____ ____) |  | |/ ____ \| | \ \  | |   "
    echo " |_|  \_\______|_____/   |_/_/    \_\_|  \_\ |_|   "
    echo " "
    echo "Please restart to implement changes!"
    echo "To Restart type sudo reboot"
fi
