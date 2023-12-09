# select git ssh key automatically.
# 
# v0.0.0
# Copyright (c) 2023 Harvey w.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


#! /usr/bin/zsh

#--------------------------------------------------------------------#
# Start                                                              #
#--------------------------------------------------------------------#


function _detect_git_dir() {
    [[ -d .git ]] && return 0 || return 1
}

function _get_repo_owner() {
    GIT_URL=$(git remote get-url --push origin)

    GIT_SCHM=($(echo ${GIT_URL} | sed -e 's#^\([[:alpha:]]\+:\/\/\)\?\([[:alnum:]]\+\)@.*:\(.\+\)\/.*#?\1 ?\2 ?\3#g' 2>/dev/null))

    case ${GIT_SCHM[0]} in
    '#https://')
        echo "https url"
        GIT_USR="${GIT_SCHM[1]}"
        ;;
    '#ssh://')
        echo "ssh url"
        GIT_USR="${GIT_SCHM[2]}"
        ;;
    *)
        unset GIT_USR
    esac

    if [[ ${GIT_USR} == '#' ]]; then
        unset GIT_USR
    else
        echo ${GIT_USR/#\#}
    fi
}

function _record_usr_props() {

    USER_NAME=${1/#\#}
    USR_EMAIL=${2/#\#}
    USR_SSH_DIR=${3/#\#}
    USR_SSH_KEY=${4/#\#}

    [[ -n ${USER_NAME} ]] && \
        read "USER_NAME?  User name?  (<cr> for default: ${USER_NAME})    - " || \
        read "USER_NAME?  User name?           -  "
    USER_NAME=${USER_NAME:-${USER_NAME}}

    [[ -n ${USR_EMAIL} ]] && \
        read "USR_EMAIL?  User email?  (<cr> for default: ${USR_EMAIL})    - " || \
        read "USR_EMAIL?  User email?          -  "
    USR_EMAIL=${USR_EMAIL:-${USR_EMAIL}}

    [[ -n ${USR_SSH_DIR} ]] && \
        read "USR_SSH_DIR?  User SSH Key folder?  (<cr> for default: ${USR_SSH_DIR})    - " || \
        read "USR_SSH_DIR?  SSH Key folder?    -  "
    USR_SSH_DIR=${USR_SSH_DIR:-${HOME}/.ssh}

    [[ -n ${USR_SSH_KEY} ]] && \
        read "USR_SSH_KEY?  User SSH Key file?  (<cr> for default: ${USR_SSH_KEY})    - " || \
        read "USR_SSH_KEY?  SSH Key file?      -  "
    USR_SSH_DIR=${USR_SSH_DIR:-${HOME}/.ssh}

    USR_SSH_KEY="${USR_SSH_DIR%*/}/${USR_SSH_KEY}"
    if [[ (! -f ${USR_SSH_KEY}) && (! -L ${USR_SSH_KEY}) ]]; then
        echo "Cannot access File: ${USR_SSH_KEY}. "
        return 1
    fi

    git config user.name "${USER_NAME}"
    git config user.email "${USR_EMAIL}"
    git config core.sshCommand "ssh -i "${USR_SSH_KEY}""

    echo "All set: user "${USER_NAME}"; email: "${USR_EMAIL}"; ssh key: "${USR_SSH_KEY}""
}

function _suppress_helper() {
    GIT_CONF=${1}

    [[ (! -f ${GIT_CONF}) && (! -L ${GIT_CONF}) ]] && \
        echo "${SUPPRESSION}" > ${GIT_CONF} || \
        sed -e "\|${SUPPRESSION}|h;"      `# Search for the source string and copy it to the hold space` \
            -e "\${"                      `# Go to the end of the file and run the following commands` \
            -e "x;"                       `# Exchange the last line with the hold space` \
            -e "s|${SUPPRESSION}||;"      `# Erase the source string if it was actually found` \
            -e "{g;"                      `# Bring back the last line` \
            -e "t};"                      `# Test if the substitution succeeded (the source string was found)` \
            -e "a\\${SUPPRESSION}"        `# Append the source string` \
            -e "}" -i ${GIT_CONF}
}

function _on_git_dir_switch() {
    _detect_git_dir || return 0

    GIT_CONF='./.git/config'

    SUPPRESSION='#Suppress git-ssh-helper.zsh'


    if [[ (-f ${GIT_CONF}) || (-L ${GIT_CONF}) ]]; then
        grep 'sshCommand' ${GIT_CONF} 2>&1 >/dev/null && \
            return 0
        grep ${SUPPRESSION} ${GIT_CONF} 2>&1 >/dev/null && \
            return 0
    fi

    echo "Git repository detected, but no usr-props defined within. "
    GIT_USR=$(_get_repo_owner)

    unset ACTION
    until [[ (-n ${ACTION}) && (${ACTION} != 'y') ]]; do
        echo ${ACTION}
        [[ -z ${ACTION} ]] && \
            read "ACTION?Init? Y(es) S(uppress) N(o): " || \
            read "ACTION?Retry Init? Y(es) S(uppress) N(o): "

        case ${ACTION} in
        'y' | 'Y' | 'yes' | 'YES' | 'Yes')
            ;;
        'n' | 'N' | 'no' | 'NO' | 'No')
            return 0
            ;;
        's' | 'S' | 'suppress' | 'SUPPRESS' | 'Suppress')
            _suppress_helper ${GIT_CONF}
            return 0
            ;;
        *)
            echo "Not a clear indication."
            unset ACTION
            continue
        esac

        USER_NAME=${USER_NAME:-${GIT_USR}}
        
        USER_EMAIL=$(sed -n \
            -e '/[user]/{N' \
            -e 's/email = \(.\+@[a-zA-Z0-9_-]\+\.[a-zA-Z0-9_-]\+\)\n\s\+.\+$/\1/gp' \
            -e '}' \
            ${GIT_CONF})
        
        USR_SSH_DIR=${USR_SSH_DIR:-${HOME}/.ssh}

        _record_usr_props \#${GIT_USR} \#${USR_EMAIL} \#${HOME}/.ssh \#${USR_SSH_KEY} && \
            ACTION='n' break || \
            ACTION='y' continue

    done

    unset GIT_URL
    unset GIT_CONF
    unset GIT_SCHM
    unset GIT_USR
    unset USER_NAME
    unset USR_EMAIL
    unset USR_SSH_DIR
    # unset USR_SSH_KEY
}

# Start plugin by adding hook when current working directory is changed

$(git --version 2>&1 >/dev/null) || exit 0

add-zsh-hook chpwd _on_git_dir_switch

