source_repo="https://github.com/dynatrace-ace/perform2021-vhot-qualitygates.git"
clone_folder="bootstrap"
shell_user="ace"
home_folder="/home/$shell_user"

sudo apt update
sudo apt-get -f dist-upgrade
sudo apt install -y git vim

rm -rf bootstrap
##############################
# Clone repo                 #
##############################
cd $home_folder
mkdir "$clone_folder"
cd "$home_folder/$clone_folder"
git clone "$source_repo" .
chown -R $shell_user $home_folder/$clone_folder
cd "$home_folder/$clone_folder/"
chmod u+x ./build.sh  
./build.sh "$home_folder" "$clone_folder" "$source_repo"