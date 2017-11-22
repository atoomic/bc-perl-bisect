#!/bin/sh

git checkout .
git clean -dxf

set -e

BASE_DIR=/root/perlbin_tmp
PATCH_DIR=/root/bc/minimal-patches
LOG=/tmp/log.bc.configure.bisect

cd ~/workspace/perl5/
echo '# git clean -dxf'
git clean -dxf >/dev/null 2>&1

/bin/rm -rf $BASE_DIR ||:

echo "..."
# echo "# patching files"
# for p in $PATCH_DIR/*.patch; do
#     echo "## Applying patch $p"
#     patch -p3 -i $p
# done

# echo "[DONE] patching perl";


echo "..."
echo "Running ./Configure"
export TEST_JOBS=10
./Configure -Dprefix=$BASE_DIR -Dcc="ccache gcc" -Dusedevel -Doptimize=-g3 -des -Dinstallusrbinperl=no -Dscriptdir=$BASE_DIR/bin -Dscriptdirexp=$BASE_DIR/bin -Dman1dir=none -Dman3dir=none >$LOG 2>&1 || ( cat $LOG; exit $? ) 

echo "[DONE] ./Configure";
test -f config.sh || exit 125

# need to convert to a patch
# Correct makefile for newer GNU gcc
#perl -ni -we 'print unless /<(?:built-in|command)/' makefile x2p/makefile

# if you just need miniperl, replace test_prep with miniperl

echo "..."
echo "Running: make -j18 install"
make -j18 install >$LOG 2>&1 || ( cat $LOG; exit $? )
echo "[DONE] compiled perl"

[ -x ./perl ] || exit 125
git checkout makedepend.SH
VER=`./perl -e'print substr ($^V, 1)'`
ln -s perl${VER} $BASE_DIR/bin/perl

git checkout .

##### Settign & checking perl
export PATH=/root/perlbin_tmp/bin:$PATH
$BASE_DIR/bin/perl -E 'say qq{## Perl $] installed - use $^X}'

###### FROM HERE can test & use perl

# testing a simple test case
#echo '#127568: \w'
#$BASE_DIR/bin/perl -e 'my $f = $ENV{user} =~ qr{_?[\W\_]}; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant: PI'
#$BASE_DIR/bin/perl -e 'use utf8; use constant PI => 4 * atan2(1, 1); print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant only'
#$BASE_DIR/bin/perl -e 'use constant; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'

###### INSTALLING a few modules required by B::C

# install cpanminus
for module in "Scalar-List-Utils-1.48" "App-cpanminus-1.7043"; do 
 	echo "# installing $module"; 
 	cd /root/bc/modules/$module
 	git clean -dxf
 	echo | perl Makefile.PL
 	make install
done

# install all dependencies of App::perlbrew
for module in "Path::Class" "App::perlbrew"; do
	echo "# installing module $module using cpanm";
	/root/perlbin_tmp/bin/cpanm --notest $module
done

# run test for App::perlbrew
for module in "App-perlbrew-0.80"; do 
	echo "# installing $module"; 
	cd /root/bc/modules/$module
	git clean -dxf
	echo | perl Makefile.PL
	make test
done

