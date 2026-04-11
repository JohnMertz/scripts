#!/bin/bash

if [ -e "${HOME}/.local/state/ssh-agent.sock" ]; then
    PID=$(tail -n 1 "${HOME}/.local/state/ssh-agent.env" | sed 's/echo Agent pid \([0-9]*\);/\1/')
    if [ -z "$PID" ]; then
        rm "${HOME}/.local/state/ssh-agent.sock" "${HOME}/.local/state/ssh-agent.pid" 2>/dev/null
        pkill ssh-agent
    else
        CMD=$(ps -p "$PID" -o comm | tail -n 1)
        if [ -n "$CMD" ] && [ "$CMD" == 'ssh-agent' ]; then
            echo "Valid agent already found at ${HOME}/.local/state/ssh-agent.sock with PID $PID"
            exit
        fi
    fi
fi

eval $(ssh-agent -a "${HOME}/.local/state/ssh-agent.sock" | tee "${HOME}/.local/state/ssh-agent.env")
