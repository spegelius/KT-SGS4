echo "Copy SERVER LINKS FILE"
cp ../Packages/url/SERVERLINKS_ORIG.txt ../Packages/url/SERVERLINKS.txt
echo "Switch to AOSP 4.4"
git checkout aosp4.4

echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_att.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_spr.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_tmo.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_vzw.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_intl.sh

echo "Switch to Touchjizz 4.4"
git checkout tw4.4
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_att.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_spr.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_tmo.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_vzw.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_intl.sh

echo "Switch to Touchjizz GE 4.4"
git checkout twge4.4

echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_att.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_intl.sh
echo "Make Clean"
make clean
echo "Make Mrproper"
make mrproper
./build_vzw.sh

echo "Switch to AOSP 4.4"
git checkout aosp4.4

