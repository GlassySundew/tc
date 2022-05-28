#!/bin/bash

declare -A tagged
tagged[player]=1

declare -A framed
framed[player]=1


cd separated

for file in */ ; do
	cd "$file"
		tag=''
		frame=''
				
		if [ ${tagged[${file::-1}]} ] ; then 
			tag="{tag}_" 
		fi
		
		if [ ${framed[${file::-1}]} ] ; then 
			frame="_{frame0}" 
		fi
		
		aseprite -b ../../ase/"${file::-1}".ase --save-as "$tag"{slice}"$frame".png 
	cd ..
done

cd structures

aseprite -b ../../ase/door.ase --save-as {slice}0.png
