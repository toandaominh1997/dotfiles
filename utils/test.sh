checkMacOS(){
  if [ "$(uname)" == "Darwin" ]
  then
    echo true
  fi
  echo false
}
checkLinux() {
  if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
  then
    echo true
  fi
  echo false
}
checkMacOSorLinux() {

}


name=tonne
value=tonne
if [ $name == tonne ]
then
  echo "done"
fi
echo name = $name

checkMacOS
test=$?
echo testne=$(checkMacOS)
if [ $test == 1 ]
then
  echo "kaka"
else
  echo "lala"
fi