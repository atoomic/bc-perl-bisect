#!/bin/sh

git proper

set -e

BASE_DIR=/root/perlbin_tmp
PATCH_DIR=/root/bc/minimal-patches/
LOG=/tmp/log.bc.configure.bisect

cd ~/workspace/perl5/
echo '# git clean -dxf'
git clean -dxf >/dev/null 2>&1

/bin/rm -rf $BASE_DIR ||:

echo "..."
echo "# patching files"
for p in $PATCH_DIR/*.patch; do
    echo "## Applying patch $p"
    patch -p3 -i $p
done

echo "[DONE] patching perl";


echo "..."
echo "Running ./Configure"
./Configure -Dprefix=$BASE_DIR -Dusedevel -Doptimize=-g -des -Dinstallusrbinperl=no -Dscriptdir=$BASE_DIR/bin -Dscriptdirexp=$BASE_DIR/bin -Dman1dir=none -Dman3dir=none >$LOG 2>&1 || ( cat $LOG; exit $? ) 

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
# This runs the actual testcase. You could use -e instead:

set +e

# testing a simple test case
#echo '#127568: \w'
#$BASE_DIR/bin/perl -e 'my $f = $ENV{user} =~ qr{_?[\W\_]}; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant: PI'
#$BASE_DIR/bin/perl -e 'use utf8; use constant PI => 4 * atan2(1, 1); print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant only'
#$BASE_DIR/bin/perl -e 'use constant; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'

$BASE_DIR/bin/perl -E 'say qq{## Perl $] installed - use $^X}'

# ... TODO install and test BC

git checkout .

export PATH=/root/perlbin_tmp/bin:$PATH

# adding B::Flags

for module in "B-Flags-0.17" "Template-Toolkit-2.27"; do 
	echo "# installing $module"; 
	set -e
	cd /root/bc/$module
	git clean -dxf
	echo | perl Makefile.PL
	make install
	set +e
done

cd /root/workspace/bc

perl Makefile.PL >$LOG 2>&1 || ( cat $LOG; exit $? ) #  installdirs=vendor
echo "B::C - Makefile.PL: ok"

make -j4 install >>$LOG 2>&1 || ( cat $LOG; exit $? )

echo "# which perlcc ?"
which perlcc

echo "# testing B::C"
rm -f a.out*; /root/perlbin_tmp/bin/perlcc -r -e 'print qq{## Hello from perlcc $] - use $^X - OK\n}'


#if you need to invert the exit code, replace the above exit with this:
#[ $ret -eq 0 ] && exit 1
#exit 0
