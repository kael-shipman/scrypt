#!/bin/bash

#Verify arguments
show_usage() {
	echo "Usage: $0 -[e|d]Rp path [path...]"
  echo 
  echo "  -e|--encrypt      Encrypt, if not already encrypted (if neither -e nor -d is specified, the program decrypts"
  echo "                    if file ending is '.scrypt' and encrypts of file ending is not '.scrypt')"
  echo "  -d|--decrypt      Decrypt, if not already decrypted (see -e above)"
  echo "  -p|--preserve     Preserve original (defaults to false: replaces original file with newly encrypted or"
  echo "                    decrypted file)"
  echo "  -R|--recursive    Recursively descend through directories"
  echo
}

RECURSIVE=0
ACTION=0
PRESERVE=0
VERB='process'
declare -a FILES

while test $# -gt 0; do
  case $1 in 

    -h|--help)
      show_usage
      exit 0
      ;;

    -e|--encrypt)
      # Err out if action already set
      if [ "$ACTION" -gt 0 ]; then
        echo "ERROR: Can't set action twice (i.e., there should only be one -e or -d argument passed)"
        show_usage
        exit 1
      fi

      ACTION=1
      VERB='encrypt'
      shift
      ;;

    -d|--decrypt)
      if [ "$ACTION" -gt 0 ]; then
        echo "ERROR: Can't set action twice (i.e., there should only be one -e or -d argument passed)"
        show_usage
        exit 1
      fi

      ACTION=2
      VERB='decrypt'
      shift
      ;;

    -p|--preserve)
      PRESERVE=1
      shift
      ;;

    -R|--recursive)
      RECURSIVE=1
      shift
      ;;

    *)
      if [ "${1:0:1}" == "-" ]; then
        echo 'Argument `'"$1"'` unknown!'
        show_usage
        exit 1
      fi
      FILES+=("$1")
      shift
      ;;

  esac
done



# Validate

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "You must supply at least one file or directory to $VERB!"
  show_usage
  exit 1
fi

      

#get password
PASS=''
CONFIRMPASS=''
PASSWORDACCEPTED=0

while [ $PASSWORDACCEPTED -eq 0 ]
do
	echo -n "Please enter your password: "
	read -s PASS
	echo
	echo -n "Please confirm your password: "
	read -s CONFIRMPASS
	if [ "$PASS" = "" ]
	then
		echo
		echo "You must enter a real password!"
	elif [ "$PASS" != "$CONFIRMPASS" ]
	then
		echo
		echo "The passwords you entered don't match. Please try again."
	else
		PASSWORDACCEPTED=1
		echo
	fi
done


#process files
process_files() {
	FILE=`realpath "$1"`

	#functions
	dec() {
		#get target name
		let "BASELN=${#1}-7"
		BASENM=${1:0:$BASELN}
		echo "decrypting $BASENM"
		/usr/bin/openssl des3 -k "$2" -d -in "$1" -out "$BASENM"
		CODE=$?
    if [ $CODE -eq 0 ]; then
      if [ $PRESERVE -eq 0 ]; then
				rm "$1"
        if [ "$?" -gt 0 ]; then
          >&2 echo "Warning! Couldn't remove original file '$1'."
        fi
      fi
    else
      rm "$BASENM"
    fi
    return $CODE
	}

	enc() {
		echo "encrypting $1"
		/usr/bin/openssl des3 -k "$2" -in "$1" -out "$1.scrypt"
		CODE=$?
    if [ $CODE -eq 0 ]; then
      if [ $PRESERVE -eq 0 ]; then
				rm "$1"
        if [ "$?" -gt 0 ]; then
          >&2 echo "Warning! Couldn't remove original file '$1'."
        fi
      fi
    else
      rm "$1.scrypt"
		fi
		return $CODE
	}

	#cryption
	CODES=0
  if [ -d "$FILE" ]; then
    for f in "$FILE"/*; do
      if [ ! -d "$f" -o "$RECURSIVE" -eq 1 ]; then
        process_files "$f"
        CODES=$(expr "$CODES" + "$?")
      fi
    done
  else
    if [ "${FILE:(-7)}" == '.scrypt' ]; then
      if [ "$ACTION" -eq 0 ] || [ "$ACTION" -eq 2 ]; then
        dec "$FILE" "$PASS"
        return $?
      else
        echo "skipping $FILE"
      fi
    else
      if [ "$ACTION" -eq 0 ] || [ "$ACTION" -eq 1 ]; then
        enc "$FILE" "$PASS"
        return $?
      else
        echo "skipping $FILE"
      fi
    fi
  fi

	return $CODES
}


echo
EXITSTATUS=0
for f in "${FILES[@]}"; do
  if [ -e "$f" ]; then
    process_files "$f"
    EXITSTATUS=$(expr "$EXITSTATUS" + "$?")
  else
    >&2 echo "The file '$f' doesn't exist!"
  fi
done




#exit
echo
if [ $EXITSTATUS -gt 0 ]
then
	echo "There were errors $VERB""ing your files! Maybe you used the wrong password? See output for details."
	echo
	exit $EXITSTATUS
else
	echo "Files successfully $VERB""ed"
	echo
	exit 0
fi

