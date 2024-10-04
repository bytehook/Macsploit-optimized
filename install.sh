#!/bin/sh

main() {
    clear
    echo "Welcome to the MacSploit Optimized Experience!"
    echo "Install Script Version 2.6"

    curl -s "https://git.raptor.fun/main/jq-macos-amd64" -o "./jq" && chmod +x ./jq
    curl -s "https://git.raptor.fun/sellix/hwid" -o "./hwid" && chmod +x ./hwid
    
    user_hwid=$(./hwid)
    hwid_info=$(curl -s "https://git.raptor.fun/api/whitelist?hwid=$user_hwid")
    hwid_resp=$(echo "$hwid_info" | ./jq -r ".success")
    rm ./hwid
    
    if [ "$hwid_resp" != "true" ]; then
        echo -n "Enter License Key: "
        read input_key

        resp=$(curl -s "https://git.raptor.fun/api/sellix?key=$input_key&hwid=$user_hwid")
        
        if [ "$resp" != "Key Activation Complete!" ]; then
            rm ./jq
            exit
        fi
    else
        free_trial=$(echo "$hwid_info" | ./jq -r ".free_trial")
        if [ "$free_trial" = "true" ]; then
            echo -n "Enter License Key (Press Enter to Continue as Free Trial): "
            read input_key
            
            if [ -n "$input_key" ]; then
                resp=$(curl -s "https://git.raptor.fun/api/sellix?key=$input_key&hwid=$user_hwid")
            fi
        fi
    fi

    echo "Installing Latest Roblox..."
    [ -f ./RobloxPlayer.zip ] && rm ./RobloxPlayer.zip

    robloxVersionInfo=$(curl -s "https://clientsettingscdn.roblox.com/v2/client-version/MacPlayer")
    versionInfo=$(curl -s "https://git.raptor.fun/main/version.json")
    
    mChannel=$(echo "$versionInfo" | ./jq -r ".channel")
    version=$(echo "$versionInfo" | ./jq -r ".clientVersionUpload")
    robloxVersion=$(echo "$robloxVersionInfo" | ./jq -r ".clientVersionUpload")

    if [ "$version" != "$robloxVersion" ] && [ "$mChannel" = "preview" ]; then
        curl -s "http://setup.rbxcdn.com/mac/$robloxVersion-RobloxPlayer.zip" -o "./RobloxPlayer.zip"
    else
        curl -s "http://setup.rbxcdn.com/mac/$version-RobloxPlayer.zip" -o "./RobloxPlayer.zip"
    fi
    
    rm ./jq
    [ -d "/Applications/Roblox.app" ] && rm -rf "/Applications/Roblox.app"
    unzip -o -q "./RobloxPlayer.zip" && mv ./RobloxPlayer.app /Applications/Roblox.app
    rm ./RobloxPlayer.zip

    echo "Installing MacSploit..."
    curl -s "https://git.raptor.fun/main/macsploit.zip" -o "./MacSploit.zip"
    unzip -o -q "./MacSploit.zip"

    echo "Updating Dylib..."
    if [ "$version" != "$robloxVersion" ] && [ "$mChannel" = "preview" ]; then
        curl -Os "https://git.raptor.fun/preview/macsploit.dylib"
    else
        curl -Os "https://git.raptor.fun/main/macsploit.dylib"
    fi

    echo "Patching Roblox..."
    mv ./macsploit.dylib "/Applications/Roblox.app/Contents/MacOS/macsploit.dylib"
    mv ./libdiscord-rpc.dylib "/Applications/Roblox.app/Contents/MacOS/libdiscord-rpc.dylib"
    ./insert_dylib "/Applications/Roblox.app/Contents/MacOS/macsploit.dylib" "/Applications/Roblox.app/Contents/MacOS/RobloxPlayer" --strip-codesig --all-yes
    mv "/Applications/Roblox.app/Contents/MacOS/RobloxPlayer_patched" "/Applications/Roblox.app/Contents/MacOS/RobloxPlayer"
    rm -r "/Applications/Roblox.app/Contents/MacOS/RobloxPlayerInstaller.app"
    rm ./insert_dylib

    echo "Installing MacSploit App..."
    [ -d "/Applications/MacSploit.app" ] && rm -rf "/Applications/MacSploit.app"
    mv ./MacSploit.app /Applications/MacSploit.app
    rm ./MacSploit.zip
    
    touch ~/Downloads/ms-version.json
    echo "$versionInfo" > ~/Downloads/ms-version.json
    if [ "$version" != "$robloxVersion" ] && [ "$mChannel" = "preview" ]; then
        ./jq '.channel = "previewb"' ~/Downloads/ms-version.json > tmp.json && mv tmp.json ~/Downloads/ms-version.json
    fi
    
    echo "Done."
    echo "Install Complete. Install by Nexus42! (Optimized by bytehook.)"
    exit
}

main
