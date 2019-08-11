
dpkg -s 'vim' &> /dev/null  
if [ $? -ne 0 ]
then
  echo "vim don't Installed"
  
else
  echo "WARNING: \"vim\" command is not found. Install it first\n"
  apt-get install -y vim  
fi