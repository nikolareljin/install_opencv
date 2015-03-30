#!/bin/bash

# include helper functions
source helper.sh

sudo echo "Start";

# ------------------------------------------
# specific branch - INPUT PARAMS
branch=$1;
pwd=${PWD};

# ------------------------------------------
# params
cuda="7.0";
install_dir="/usr/local";
projects="/home/$HOME/Projects";
# git source locations
opencv_git="opencv-git";
opencv_git_contrib="opencv-git-contrib";
opencv_git_extra="opencv-git-extra";

# ------------------------------------------
# remove all OPENCV libraries
clean_libraries(){
	show_text "Clean the $install_dir/lib"
	cd $install_dir/lib;
	sudo rm -rf libopencv_*;
}

# ------------------------------------------
# install all dependencies into Ubuntu
install_dependencies(){
	show_text "Install all the dependencies"
	sudo apt-get update;
	sudo apt-get install build-essential checkinstall cmake pkg-config yasm libjpeg-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libxine-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libv4l-dev python-dev python-numpy libtbb-dev libqt4-dev libgtk2.0-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils ffmpeg cmake qt5-default;
	sudo apt-get install libgtkglext1 libgtkglext1-dev
	#sudo apt-get install libopencv-dev 
	# update 
	#sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove && sudo apt-get autoclean	
}

# ------------------------------------------
# install CUDA
install_cuda(){
	show_text "Install CUDA"
	cd $projects;
	wget --no-check-certificate https://developer.nvidia.com/cuda-downloads
	URL=`grep 1404 cuda-downloads |grep x86_64|head -n 1|cut -d"\"" -f4`
	VERSION=`grep 1404 cuda-downloads |grep x86_64|head -n 1|cut -d"\"" -f4|cut -d"_" -f3|cut -d"-" -f1`
	wget `echo $URL`
	sudo dpkg -i --force-all cuda*.deb
	sudo apt-get update
	sudo apt-get install cuda
	export PATH=/usr/local/cuda-`echo $VERSION`/bin:$PATH
	export LD_LIBRARY_PATH=/usr/local/cuda-`echo $VERSION`/lib64:$LD_LIBRARY_PATH
	echo "export PATH=/usr/local/cuda-`echo $VERSION`/bin:$PATH" >> ~/.bashrc
	echo "export LD_LIBRARY_PATH=/usr/local/cuda-`echo $VERSION`/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc
	cd /usr/local/cuda-`echo $VERSION`/samples
	sudo ln -s /usr/local/cuda-`echo $VERSION` /usr/local/cuda
	sudo make clean;
	sudo make;
	cd $pwd;
}


# ------------------------------------------
# set CMAKE options
set_cmake(){
	# param 1: install dir
	dir=$1;
	#	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=$install_dir -D WITH_TBB=ON  -D WITH_CUBLAS=ON -D WITH_CUFFT=ON -D WITH_EIGEN=ON -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_V4L=ON -D BUILD_EXAMPLES=ON -D INSTALL_C_EXAMPLES=ON -D INSTALL_PYTHON_EXAMPLES=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_CUDA=ON -D CUDA_ARCH_BIN="$cuda" -D CUDA_ARCH_PTX="" -D FORCE_VTK=OFF -D BUILD_TESTS=ON -D BUILD_PERF_TESTS=ON ..
	
	# CUDA, PYTHON, EXAMPLES, OPENGL, QT, TESTS
	#cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=$dir -D BUILD_NEW_PYTHON_SUPPORT=ON -D BUILD_EXAMPLES=ON -D INSTALL_C_EXAMPLES=ON -D INSTALL_PYTHON_EXAMPLES=ON -D WITH_QT=ON -D WITH_OPENGL=ON -D WITH_CUDA=ON -D BUILD_TESTS=ON ..
	
	# PYTHON, EXAMPLES, OPENGL, QT
	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=$dir -D BUILD_NEW_PYTHON_SUPPORT=ON -D BUILD_EXAMPLES=ON -D INSTALL_C_EXAMPLES=ON -D INSTALL_PYTHON_EXAMPLES=ON -D WITH_QT=ON -D WITH_OPENGL=ON ..
	
}


# ------------------------------------------
# ----------- MAIN PROGRAM -----------------
# ------------------------------------------
# install dependencies
install_dependencies;
clean_libraries;
# install cuda
#install_cuda

show_text "pick the GIT source"
cd $projects;
git clone https://github.com/Itseez/opencv.git $opencv_git
git clone https://github.com/Itseez/opencv_contrib.git $opencv_git_contrib
git clone https://github.com/Itseez/opencv_extra.git $opencv_git_extra

# go to opencv dir
cd $projects/$opencv_git;

# fetch and pull
show_text "Get the branch: $branch"
git checkout master;  #$branch;
git checkout tags/$branch;
git fetch --all;
git pull origin/master;

# prepare release (for make)
show_text "Prepare the release"
if [ -d "$projects/$opencv_git/release" ]; then
	rm -rf $projects/$opencv_git/release;
fi;
mkdir $projects/$opencv_git/release;
cd $projects/$opencv_git/release;

show_text "Set CMAKE"
#cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=$install_dir ..
#cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=$install_dir -D BUILD_NEW_PYTHON_SUPPORT=ON -D BUILD_EXAMPLES=ON ..
set_cmake($install_dir);

#cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUBLAS=ON -D WITH_CUFFT=ON -D WITH_EIGEN=ON -D BUILD_EXAMPLES=OFF -D BUILD_TESTS=OFF -D CUDA_ARCH_BIN="3.0" ..

# clean previous make
show_text "Make Clean";
make clean

# new compile
show_text "MAKE";
make
show_text "INSTALL";
sudo make install
	
# config the system
sudo ldconfig;

# return to the original folder
cd $pwd;

