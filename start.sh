#!/bin/bash


cd server/src


# Uruchomienie skryptów Python'a w tle
python3 static_server.py &
STATIC_PID=$!
python3 video_endpoint.py &
VIDEO_PID=$!
python3 hardware_controller.py &
HARDWARE_PID=$!

# Funkcja czyszcząca, która zamyka wszystkie uruchomione skrypty
cleanup_function() {
    echo "Cleaning up..."
    kill $STATIC_PID 2>/dev/null
    kill $VIDEO_PID 2>/dev/null
    kill $HARDWARE_PID 2>/dev/null
    wait $STATIC_PID 2>/dev/null
    wait $VIDEO_PID 2>/dev/null
    wait $HARDWARE_PID 2>/dev/null
    echo "Cleanup completed."
}

# Ustawienie pułapki na sygnały SIGINT i SIGTERM
trap 'cleanup_function' SIGINT
trap 'cleanup_function' SIGTERM

# Funkcja monitorująca działanie skryptów
monitor_processes() {
    while true; do
        for PID in $STATIC_PID $VIDEO_PID $HARDWARE_PID; do
            if ! kill -0 $PID 2>/dev/null; then
                echo "Process $PID has terminated. Cleaning up remaining processes..."
                cleanup_function
                exit 1
            fi
        done
        sleep 1
    done
}

# Uruchomienie funkcji monitorującej w tle
monitor_processes &

# Poczekaj na zakończenie wszystkich skryptów
wait $STATIC_PID
wait $VIDEO_PID
wait $HARDWARE_PID

# Wywołanie funkcji czyszczącej w przypadku zakończenia wszystkich skryptów
cleanup_function
