#!/bin/bash

die(){
  error "$*"
}

error(){
  echo "$*" >&2
}

APP_DIR=`pwd`
NAME="nidel_app"

NODE_NAME=$NAME@`hostname -f`
COOKIE="mylittlecookie"

if [ -z "$2" ] ; then
    APP_ENV="development"
else
    APP_ENV=$2
fi

VM_ARGS_FILE="priv/config/vm.args"
if [ -e $VM_ARGS_FILE ]; then
    VM_ARGS="-args_file $VM_ARGS_FILE"
else
    VM_ARGS=""
fi

CONFIG_FILE="priv/config/$APP_ENV.config"
if [ -e $CONFIG_FILE ]; then
    APP_ENV_CONFIG="-config $CONFIG_FILE"
else
    error "Could not find config file: $CONFIG_FILE"
    APP_ENV_CONFIG=""
fi

# Attempt to extract the pid from ps
get_pid() {
  case `uname -s` in
      Linux|Darwin|FreeBSD|DragonFly|NetBSD|OpenBSD)
          # PID COMMAND
          PID=`ps axwww -o pid= -o command= |grep "$APP_DIR" |grep "beam" |awk '{print $1}'`
          ;;
  esac
}

# If tmp/pids exists write the pid to tmp/pids/bi.pid
write_pid() {
  sleep 2
  get_pid

  if [ -d $APP_DIR/tmp/pids ]; then
    echo $PID > $APP_DIR/tmp/pids/bi.pid
  fi
}

start()
{
    echo $*
    erl -pa $APP_DIR/deps/*/ebin $APP_DIR/ebin \
        -setcookie $COOKIE $VM_ARGS $APP_ENV_CONFIG \
        $*
    write_pid
}

start_console()
{
    start -s $NAME -name $NODE_NAME
}

start_app()
{
    start -s $NAME -name $NODE_NAME -detached
}

attach_to_rmsh()
{
    start -name ${NAME}_attacher_${RANDOM}@`hostname` -remsh $NODE_NAME -hidden

}

# Try to get the process Pid
get_pid

# Check the first argument for instructions
case "$1" in
    start)
        if [ "$PID" = "" ]
        then
            start_app
        else
            echo "VM is already running"
        fi
        ;;
    console)
        if [ "$PID" = "" ]
        then
            start_console
        else
            echo "VM is already running"
        fi
        ;;
    attach)
        if [ "$PID" != "" ]
        then
            attach_to_rmsh;
        else
            echo "VM is not running"
        fi
        ;;
    stop)
        if [ "$PID" = "" ]
        then
            echo "VM is not running"
        fi

        while `kill -3 $PID 2>/dev/null`;
        do
            echo "Stopping VM"
            sleep 1
            write_pid
        done
        ;;
    *)
        echo "Unknown command: $1"
        ;;
    esac

exit 0
