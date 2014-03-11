#!/bin/sh

SCRIPT_NAME=`basename "${0}"`
VERSION=1.2

usage() {
  echo "Usage: ${SCRIPT_NAME} {none|command|full} [<password> [<old password>]]"
  echo "Example: ${SCRIPT_NAME} command \"123321\" \"123456\""
  echo "RuntimeAbortScript"
  exit 1
}

echo "Running ${SCRIPT_NAME} v${VERSION}"

if [ ${#} -lt 1 ]
then
  usage
fi

SYS_VERS=`sw_vers -productVersion | awk -F. '{ print $2 }'`

SETREGPROPTOOL=`dirname "${0}"`/setregproptool 

if [ -e "${SETREGPROPTOOL}" ] && [ ${SYS_VERS} -ge 6 ]
then
  "${SETREGPROPTOOL}" -c
  PASSWORDSET=${?}
  if [ ${PASSWORDSET} -eq 1 ]
  then
    if [ ${#} -eq 2 ] || [ "${1}" = "none" ]
    then
      case "${1}" in
        "none")
          ;;
        "command")
          "${SETREGPROPTOOL}.exp" "${SETREGPROPTOOL}" -m command -p "${2}" >/dev/null
          if [ $? -ne 0 ]
          then
            echo "RuntimeAbortScript"
            exit 1
          fi
          ;;
        "full")
          "${SETREGPROPTOOL}.exp" "${SETREGPROPTOOL}" -m full -p "${2}" >/dev/null
          if [ $? -ne 0 ]
          then
            echo "RuntimeAbortScript"
            exit 1
          fi
          ;;
         *)
          echo "Invalid firmware password mode (${1}), script aborted."
          echo "RuntimeAbortScript"
          exit 1
          ;;
      esac
    else
      usage
    fi
  elif [ ${#} -eq 3 ] || [ "${1}" = "none" ]
  then
    case "${1}" in
      "none")
        "${SETREGPROPTOOL}.exp" "${SETREGPROPTOOL}" -d -o "${2}" >/dev/null
        if [ $? -ne 0 ]
        then
          echo "Incorrect password, script aborted."
          echo "RuntimeAbortScript"
          exit 1
        fi
        ;;
      "command")
        "${SETREGPROPTOOL}.exp" "${SETREGPROPTOOL}" -m command -p "${2}" -o "${3}" >/dev/null
        if [ $? -ne 0 ]
        then
          echo "Incorrect password, script aborted."
          echo "RuntimeAbortScript"
          exit 1
        fi
        ;;
      "full")
        "${SETREGPROPTOOL}.exp" "${SETREGPROPTOOL}" -m full -p "${2}" -o "${3}" >/dev/null
        if [ $? -ne 0 ]
        then
          echo "Incorrect password, script aborted."
          echo "RuntimeAbortScript"
          exit 1
        fi
        ;;
      *)
        echo "Invalid firmware password mode (${1}), script aborted."
        echo "RuntimeAbortScript"
        exit 1
        ;;
    esac
  else
    echo "Old password required!"
    usage
  fi
elif [ ${#} -ge 2 ] || [ "${1}" = "none" ]
then
  case "${1}" in
    "none")
      /usr/sbin/nvram security-mode="none" >/dev/null
      ;;
    "command")
      /usr/sbin/nvram security-mode="command" security-password="${2}" >/dev/null
      ;;
    "full")
      /usr/sbin/nvram security-mode="full" security-password="${2}" >/dev/null
      ;;
    *)
      echo "Invalid firmware password mode (${1}), script aborted."
      echo "RuntimeAbortScript"
      exit 1
      ;;
  esac
else
  usage
fi

echo "Exiting ${SCRIPT_NAME} v${VERSION}"

exit 0
