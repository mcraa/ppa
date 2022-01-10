curl -s --compressed "https://mcraa.github.io/ppa/KEY.gpg" | sudo apt-key add -
sudo curl -s --compressed -o /etc/apt/sources.list.d/balena_list_file.list "https://mcraa.github.io/ppa/files.list"
sudo apt update