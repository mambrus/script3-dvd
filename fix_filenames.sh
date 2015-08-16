#! /bin/bash

EXT=${EXT-"mp4"}

for F in $(find . -type f | tr ' ' '%'); do 
	mv "$(tr '%' ' ' <<< $F)" \
		$(
			dirname $F)/$(tr '%' '_' <<< $(basename $F) | \
				tr '\.' '_' | \
				tr '&' '_' | \
				tr -s '_' | \
				sed -Ee 's/_'$EXT'$/.'$EXT'/' | \
				sed -Ee '/.*\.'$EXT'/b; s/(.*)/\1.'$EXT'/'
		) |& grep -Ev 'are the same file$'
done

