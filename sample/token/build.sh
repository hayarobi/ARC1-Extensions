#!/bin/bash

echo "-- ARC1 --" > output.lua

process_file() {
  cat ../src/ARC1-$1.lua >> output.lua
}

process_file "Core" 
process_file "Mintable" 
process_file "Pausable" 
process_file "Blacklist" 
process_file "allApproval" 
process_file "limitedApproval" 

cat sample.lua >> output.lua
