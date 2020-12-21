apt-get install ffmpeg

echo "Cloning GSPCA Repo..."
git clone https://github.com/grandchild/gspca-kinect2.git && cd gspca-kinect2
echo "Building & Installing Modules (copying into /lib/modules/`uname -r`/kernel/drivers/kinect)"
make -C /lib/modules/`uname -r`/build  M=`pwd` SRCROOT=`pwd` clean modules
cp gspca_main.ko gspca_kinect_main.ko
cp gspca_kinect_main.ko /lib/modules/`uname -r`/kernel/drivers/kinect/gspca_kinect_main.ko
cp gspca_kinect2.ko /lib/modules/`uname -r`/kernel/drivers/kinect/gspca_kinect2.ko
cd ..

echo "Cloning V4L2Loopback Repo..." 
git clone https://github.com/umlaeute/v4l2loopback.git && cd v4l2loopback
echo "Building and Installing Modules"
make && make install
cd ..
echo "Resolving Module Dependencies"
depmod -a
echo "Enabling GSPCA & V4L2Loopback Modules at boot"
for module in "videodev" "gspca_kinect_main" "gspca_kinect2" "v4l2loopback"
do
	if grep -Fxq $module /etc/modules
	then
    		echo "$module found - skipping..."
	else
    		echo "$module not found - adding to /etc/modules"
                echo $module >> /etc/modules
	fi
done

echo "options video_nr=10 card_label='Kinect v2'" > /etc/modprobe.d/v4l2loopback.conf
echo "Creating ffmpeg service v4l2-loopback.service"
echo "[Unit]
Description=V4L2 Loopback Service for Kinect Webcam

[Service]
Type=simple
ExecStart=ffmpeg -i /dev/video0 -vsync drop -filter:v fps=30,scale=1280:-1,hflip -pix_fmt yuyv422 -color_trc bt709 -color_primaries bt709 -color_range tv -f v4l2 /dev/video10

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/v4l2-kinect.service

echo "Enabling v4l2-loopback.service at boot"
systemctl enable v4l2-loopback
