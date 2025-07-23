getopt -T

if [ "$?" -ne 4 ]; then
    echo "wrong version of 'getopt' installed, exiting..." >&2
    exit 1
fi

outputPath="./"
format=1

params="$(getopt -o o:f: --long output:,help -- "$@")" 

eval set -- "$params"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --output | -o)
      if [ -d "$2" ]; then
	      outputPath="$2"
      else
        echo "Error: Output path does not exist or is not a directory."
        exit
      fi
      shift 2;;
    ---f)
      if [[ "$2" == "1" ]] || [[ "$2" == "2" ]]; then
        format="$2"
      else
        echo "Folder format must be '1' or '2'"
      fi
      shift 2;;
    --help)
      echo -e "\
\e[1m== 'packwbfs' HELP ==\e[0m
Usage:
  packwbfs \e[0;32m[options] [file paths]\e[0m
  packwbfs \e[0;32m[options]\e[0m
  packwbf \e[0;36mTakes all .wbfs files in working directory, pack in same directory\e[0m

Options:
  \e[0;32m--help\e[0m \e[0;36mSee this menu\e[0m
  \e[0;32m-o [directory]\e[0m or \e[0;32m--output [directory]\e[0m \e[0;36mChoose an output directory for packed files\e[0m
  \e[0;32m-f [1,2]\e[0m \e[0;36mChoose a format option for your packed directories (1 for 'gameName [gameID]', 2 for 'gameID_gameName')\e[0m
  \e[0;32m-v\e[0m \e[0;36mEcho more information\e[0m
"

      exit
      ;;
    --)
      shift
      break;;
    *)
      echo "Error: Unhandled option! $1"
      shift;;
  esac
done

inputPaths="$@"

if [[ $# == 0 ]]; then
  inputPaths=*.wbfs
fi

local i=0

for arg in $inputPaths; do
  [[ $i > 0 ]] && echo "-----------"
  if [ -f "$arg" ]; then
    gameID=$(wit ID6 "$arg")
    gameName=$(wit ls "$arg" --sections | grep "^name=" | cut -d "=" -f 2)
    
    [[ "$format" == 1 ]] && dirName="$gameName [$gameID]"
    [[ "$format" == 2 ]] && dirName="$gameID""_""$gameName"

    echo "Making directory '$outputPath/$dirName'"
    mkdir "$outputPath/$dirName"

    echo "Running 'wit copy' on '$arg'"
    wit copy "$arg" "$outputPath/$dirName" -z -q
    for file in "$outputPath/$dirName"/*; do
      extension="${file##*.}"
      echo "Renaming '$file' to '$gameID.$extension'"
      mv "$file" "$outputPath/$dirName/$gameID.$extension"
    done
  else
    echo "No such file \"$arg\""
  fi
  i+=1
done
