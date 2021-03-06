#!/usr/bin/env sh

########  Public functions #####################

#Usage: dns_nsupdate_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_nsupdate_add() {
  fulldomain=$1
  txtvalue=$2
  basedomain=$(echo "$fulldomain" | sed -e 's/^.*\.\(.*\..*\)$/\1/')
  [ -n "${NSUPDATE_SERVER}" ] || NSUPDATE_SERVER="localhost"
  [ -n "${NSUPDATE_SERVER_PORT}" ] || NSUPDATE_SERVER_PORT=53
  [ -n "${NSUPDATE_KEYDIR}" ] || NSUPDATE_KEYDIR="${LE_WORKING_DIR}/keys"
  # save the dns server, keydir and key to the account conf file.
  _saveaccountconf NSUPDATE_SERVER "${NSUPDATE_SERVER}"
  _saveaccountconf NSUPDATE_SERVER_PORT "${NSUPDATE_SERVER_PORT}"
  _saveaccountconf NSUPDATE_KEY "${NSUPDATE_KEY}"
  _saveaccountconf NSUPDATE_KEYDIR "${NSUPDATE_KEYDIR}"
  # try to find a matching key
  if [ -r "${NSUPDATE_KEYDIR}/${basedomain}.key" ]; then
    NSUPDATE_KEY="${NSUPDATE_KEYDIR}/${basedomain}.key"
    _info "using non default key ${NSUPDATE_KEYDIR}/${basedomain}.key"
    # try to use the current SOA of the domain as nameserver
    if [ -n "$(command -v host)" ]; then
      NSUPDATE_SERVER="$(host -t SOA "${basedomain}" | cut -d ' ' -f5 | sed 's/\.$//')"
      _info "using non default server ${NSUPDATE_SERVER}"
    fi
  fi
  _checkKeyFile || return 1
  _info "adding ${fulldomain}. 60 in txt \"${txtvalue}\""
  nsupdate -k "${NSUPDATE_KEY}" <<EOF
server ${NSUPDATE_SERVER} ${NSUPDATE_SERVER_PORT} 
update add ${fulldomain}. 60 in txt "${txtvalue}"
send
EOF
  if [ $? -ne 0 ]; then
    _err "error updating domain"
    return 1
  fi

  return 0
}

#Usage: dns_nsupdate_rm   _acme-challenge.www.domain.com
dns_nsupdate_rm() {
  fulldomain=$1
  basedomain=$(echo "$fulldomain" | sed -e 's/^.*\.\(.*\..*\)$/\1/')
  [ -n "${NSUPDATE_SERVER}" ] || NSUPDATE_SERVER="localhost"
  [ -n "${NSUPDATE_SERVER_PORT}" ] || NSUPDATE_SERVER_PORT=53
  [ -n "${NSUPDATE_KEYDIR}" ] || NSUPDATE_KEYDIR="${LE_WORKING_DIR}/keys"
  # try to find a matching key
  if [ -r "${NSUPDATE_KEYDIR}/${basedomain}.key" ]; then
    NSUPDATE_KEY="${NSUPDATE_KEYDIR}/${basedomain}.key"
    _info "using non default key ${NSUPDATE_KEYDIR}/${basedomain}.key"
    # try to use the current SOA of the domain as nameserver
    if [ -n "$(command -v host)" ]; then
      NSUPDATE_SERVER="$(host -t SOA "${basedomain}" | cut -d ' ' -f5 | sed 's/\.$//')"
      _info "using non default server ${NSUPDATE_SERVER}"
    fi
  fi
  _checkKeyFile || return 1
  _info "removing ${fulldomain}. txt"
  nsupdate -k "${NSUPDATE_KEY}" <<EOF
server ${NSUPDATE_SERVER} ${NSUPDATE_SERVER_PORT} 
update delete ${fulldomain}. txt
send
EOF
  if [ $? -ne 0 ]; then
    _err "error updating domain"
    return 1
  fi

  return 0
}

####################  Private functions below ##################################

_checkKeyFile() {
  if [ -z "${NSUPDATE_KEY}" ]; then
    _err "you must specify a path to the nsupdate key file"
    return 1
  fi
  if [ ! -r "${NSUPDATE_KEY}" ]; then
    _err "key ${NSUPDATE_KEY} is unreadable"
    return 1
  fi
}
