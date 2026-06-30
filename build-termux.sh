#!/usr/bin/env bash

set -e

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
ask() {
	local y
	for ((n = 0; n < 3; n++)); do
		pr "$1 [y/n]"
		if read -r y; then
			if [ "$y" = y ]; then
				return 0
			elif [ "$y" = n ]; then
				return 1
			fi
		fi
		pr "Asking again..."
	done
	return 1
}

pr "Ask for storage permission"
until
	yes | termux-setup-storage >/dev/null 2>&1
	ls /sdcard >/dev/null 2>&1
do sleep 1; done
if [ ! -f ~/.rvmm_"$(date '+%Y%m')" ]; then
	pr "Setting up environment..."
	yes "" | pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && pkg install -y git curl jq openjdk-17 zip
	: >~/.rvmm_"$(date '+%Y%m')"
fi
mkdir -p /sdcard/Download/Youtube-Black/

if [ -d Youtube-Black ] || [ -f config.toml ]; then
	if [ -d Youtube-Black ]; then cd Youtube-Black; fi
	pr "Checking for Youtube-Black updates"
	git fetch
	if git status | grep -q 'is behind\|fatal'; then
		pr "Youtube-Black is not synced with upstream."
		pr "Cloning Youtube-Black. config.toml will be preserved."
		cd ..
		cp -f Youtube-Black/config.toml .
		rm -rf Youtube-Black
		git clone https://github.com/LyelKwon1/Youtube-Black --recurse --depth 1
		mv -f config.toml Youtube-Black/config.toml
		cd Youtube-Black
	fi
else
	pr "Cloning Youtube-Black."
	git clone https://github.com/LyelKwon1/Youtube-Black --depth 1
	cd Youtube-Black
	sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' config.toml
	grep -q 'Youtube-Black' ~/.gitconfig 2>/dev/null ||
		git config --global --add safe.directory ~/Youtube-Black
fi

[ -f ~/storage/downloads/Youtube-Black/config.toml ] ||
	cp config.toml ~/storage/downloads/Youtube-Black/config.toml

if ask "Open rvmm-config-gen to generate a config?"; then
	am start -a android.intent.action.VIEW -d https://j-hc.github.io/rvmm-config-gen/
fi
printf "\n"
until
	if ask "Open 'config.toml' to configure builds?\nAll are disabled by default, you will need to enable at first time building"; then
		am start -a android.intent.action.VIEW -d file:///sdcard/Download/Youtube-Black/config.toml -t text/plain
	fi
	ask "Setup is done. Do you want to start building?"
do :; done
cp -f ~/storage/downloads/Youtube-Black/config.toml config.toml

./build.sh

cd build
PWD=$(pwd)
for op in *; do
	[ "$op" = "*" ] && {
		pr "glob fail"
		exit 1
	}
	mv -f "${PWD}/${op}" ~/storage/downloads/Youtube-Black/"${op}"
done

pr "Outputs are available in /sdcard/Download/Youtube-Black folder"
am start -a android.intent.action.VIEW -d file:///sdcard/Download/Youtube-Black -t resource/folder
sleep 2
am start -a android.intent.action.VIEW -d file:///sdcard/Download/Youtube-Black -t resource/folder
