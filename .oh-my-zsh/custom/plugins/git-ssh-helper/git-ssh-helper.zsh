
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

function _on_git_dir_switch() {
    _detect_git_dir || return 0

    GIT_URL=$(git remote get-url --push origin)

    GIT=($(echo ${GIT_URL} | sed -e 's#^\([[:alpha:]]\+:\/\/\)\?\([[:alnum:]]\+\)@.*:\(.\+\)\/.*#?\1 ?\2 ?\3#g' 2>/dev/null))

    case ${GIT[0]} in
    '?https://')
        GIT_USR="${GIT[2]}"
        ;;
    # '?ssh://')
    *)
        GIT_USR="${GIT[3]}"
        ;;
    esac

    if [[ ${GIT_USR} == '?' ]]; then
        unset GIT_USR
    else
        GIT_USR=${GIT_USR/#?}
    fi

    SUPPRESSION='#Suppress git-ssh-warp.zsh'
    if [[ -n ${GIT_USR} ]]; then
        if [[ (-f ./.git/config) || (-L ./.git/config) ]]; then
	        grep 'sshCommand' ./.git/config 2>&1 >/dev/null && return 0 || \
            grep ${SUPPRESSION} ./.git/config  2>&1 >/dev/null && return 0

        fi
    fi

    echo "You have Entered."

    until [[ -n ${ACTION} ]]; do

        read "ACTION?No usr infomation found in repository. Init? Y(es) N(o) S(uppress): "

        case ${ACTION} in
        'y' | 'Y' | 'yes' | 'YES' | 'Yes')
            ;;
        'n' | 'N' | 'no' | 'NO' | 'No')
            return 0
            ;;
        's' | 'S' | 'suppress' | 'SUPPRESS' | 'Suppress')
            sed -e "\|${SUPPRESSION}|h;"      `# Search for the source string and copy it to the hold space` \
                -e "\${"                      `# Go to the end of the file and run the following commands` \
                -e "x;"                       `# Exchange the last line with the hold space` \
                -e "s|${SUPPRESSION}||;"      `# Erase the source string if it was actually found` \
                -e "{g;"                      `# Bring back the last line` \
                -e "t};"                      `# Test if the substitution succeeded (the source string was found)` \
                -e "a\\${SUPPRESSION}"        `# Append the source string` \
                -e "}" -i ./.git/config
            return 0
            ;;
        *)
            echo "A valid instruction [Yes|No|Suppress] needed ."
            unset ACTION
        esac

        if [[ -n ${ACTION} ]]; then

            [[ -n ${GIT_USR} ]] && \
                read "REPO_USR?Found user: '${GIT_USR}', input another name: (<enter> for default)" || \
                read "REPO_USR?User name?   : "
            REPO_USR=${REPO_USR:-${GIT_USR}}

            [[ -n ${USR_EMAIL} ]] &&\
                read "USR_EMAIL?Saved email: '${USR_EMAIL}', input another: (<enter> for default)" || \
                read "USR_EMAIL?User email?  : "
            USR_EMAIL="${USR_EMAIL:-${USR_EMAIL}}"
            
            USR_SSH_DIR="${USR_SSH_DIR:-${HOME}/.ssh}"
            echo ${USR_SSH_DIR}
            [[ -d ${USR_SSH_DIR} ]] &&\
                read "USR_SSH_DIR?Found SSH Keys folder: '${USR_SSH_DIR}', input another one: (<enter> for default)" || \
                read "USR_SSH_DIR?Path to SSH Keys folder? : "
            USR_SSH_DIR="${USR_SSH_DIR:-${HOME}/.ssh}"

            read "USR_SSH_KEY?Specify SSH Key file:"
            USR_SSH_KEY="${USR_SSH_DIR%*/}/${USR_SSH_KEY}"

            if [[ ! (-f ${USR_SSH_KEY}) && ! (-L ${USR_SSH_KEY}) ]]; then
                read "ACTION?Key file ${USR_SSH_KEY} not exist. Repeat? Y(es) / <Any key> to abort."
                case ${ACTION} in
                'y' | 'Y' | 'yes' | 'YES' | 'Yes')
                    unset ACTION

                    ;;
                *)
                    return 0
                esac
            else
                echo "Set user as       : ${REPO_USR}"
                echo "Set email as      : ${USR_EMAIL}"
                echo "Set ssh key file  : ${USR_SSH_KEY}"

                git config user.name ${REPO_USR}
                git config user.email ${USR_EMAIL}
                git config core.sshCommand "ssh -i ${USR_SSH_KEY}"
            fi
        fi
    done
}


git --version 2>&1 >/dev/null || exit 0

# Start plugin by adding hook when current working directory is changed
add-zsh-hook chpwd _on_git_dir_switch


