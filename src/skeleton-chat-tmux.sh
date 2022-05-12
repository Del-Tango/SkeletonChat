#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
# 

# Hot parameters
CONF_FILE_PATH="$1"

# Cold parameters
SESSION="Skeleton-${RANDOM}"
SCRIPT_DIR='src'
DOX_DIR='dox'
WRITER_SCRIPT="${SCRIPT_DIR}/skeleton-chat-writer.sh"
READER_SCRIPT="${SCRIPT_DIR}/skeleton-chat-reader.sh"
DOX_SCRIPT="${DOX_DIR}/skeleton-chat.dox"

if [ -f "$CONF_FILE_PATH" ]; then
	source "$CONF_FILE_PATH"
fi

# set up tmux
tmux start-server

# create a new tmux SESSION
tmux new-session -d -s $SESSION -n bash

# Select pane 1, start skeleton reader
tmux selectp -t 1
tmux send-keys "clear; ${READER_SCRIPT} ${CONF_FILE_PATH}" C-m

# Split pane 1 vertically by 15%, start skeleton writer
tmux splitw -v -p 15
tmux send-keys "clear; ${WRITER_SCRIPT} ${CONF_FILE_PATH}" C-m

# create a new window called Dox
tmux new-window -t $SESSION:1 -n Dox
tmux select-window -t $SESSION:1
tmux send-keys "clear; $DOX_SCRIPT" C-m

# return to main window
tmux select-window -t $SESSION:0

# Locked(n)Loaded! Attach to the tmux session
tmux attach-sessio -t $SESSION

