#!/bin/bash
 
 
#check if correct parameter passed to the script
if [[ $# -ne 1 ]];then
  echo "usage: change_imei [imei|'rand']"
  exit 1
fi
 
imei=$1
 
if [[ $imei == 'rand' ]];then
  #generate a random imei number which is valid for the device
  imei="35"
  range=10;
  for i in {0..11}; do
    r=$RANDOM;
    let "r %= $range";
    imei="$imei""$r";
  done;
 
  #generate luhn check digit
  a=$((${imei:0:1} + ${imei:2:1} + ${imei:4:1} + ${imei:6:1} + ${imei:8:1} + ${imei:10:1} + ${imei:12:1}))
  b="$((${imei:1:1}*2))$((${imei:3:1}*2))$((${imei:5:1}*2))$((${imei:7:1}*2))$((${imei:9:1}*2))$((${imei:11:1}*2))$((${imei:13:1}*2))"
  c=0
 
  for (( i=0; i<${#b}; i++ )); do
    c=$(($c+${b:$i:1}))
  done
 
  d=$(($a + $c))
  luhn=$((10-$(($d%10))))
  if [[ "$luhn" -eq 10 ]]; then luhn=0; fi
  
  #set imei with luhn digit
  imei="$imei$luhn"
 
else
  #check if length of imei is ok
  if [[ ${#1} -ne 15 ]];then
    echo "length of imei not correct"
    exit 1
  fi
fi
 
#reboot into bootloader
adb reboot bootloader &>/dev/null
 
#check if we are in fastboot already
sudo sh -c "fastboot getvar imei" &>/dev/null
sleep 1
 
#get the old imei
old_imei=$(sudo sh -c "fastboot getvar imei 2>&1" | sed -n 1p | awk '{print $2}')
 
#write the new one
sudo sh -c "fastboot oem writeimei $imei" &>/dev/null
 
#get the new set imei
new_imei=$(sudo sh -c "fastboot getvar imei 2>&1" | sed -n 1p | awk '{print $2}')
 
#reboot device 
sudo sh -c "fastboot reboot" &>/dev/null
 
#check if the new imei matches the imei on the phone
if [[ $imei == $new_imei ]]; then
  echo -e "old imei: $old_imei\nnew imei: $imei"
else
  echo -e "something went wrong\nactual imei: $new_imei"
fi
