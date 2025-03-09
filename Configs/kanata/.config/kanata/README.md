1. Install [Karabiner-DriverKit-VirtualHIDDevice] (https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice)
2. Install kanata (homebrew install kanata)
3. Daemons (load/unload):
        * sudo launchctl load /Library/LaunchDaemons/com.example.kanata.plist
        * sudo launchctl start com.example.kanata
        * sudo tail -f /Library/Logs/Kanata/kanata.err.log

        * sudo launchctl load /Library/LaunchDaemons/com.user.karabiner.virtualhiddevice.plist
        * sudo launchctl list | grep karabiner
        * sudo launchctl start com.user.karabiner.virtualhiddevice
        * cat /tmp/karabiner-daemon.err
        * cat /tmp/karabiner-daemon.log

