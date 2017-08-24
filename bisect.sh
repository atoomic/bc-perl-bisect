#!/bin/sh
set -e

BASE_DIR=/root/perlbin_tmp
PATCH_DIR=/root/bc/minimal-patches/

cd ~/workspace/perl5/
echo '# git clean -dxf'
git clean -dxf >/dev/null 2>&1

/bin/rm -rf $BASE_DIR ||:

for p in $PATCH_DIR/*.patch; do
    echo "## Applying patch $p"
    patch -p3 -i $p
done

echo "patching done....";
sleep 5;

./Configure -Dprefix=$BASE_DIR -Dusedevel -Doptimize=-g -des -Dinstallusrbinperl=no -Dscriptdir=$BASE_DIR/bin -Dscriptdirexp=$BASE_DIR/bin -Dman1dir=none -Dman3dir=none

test -f config.sh || exit 125

# need to convert to a patch
# Correct makefile for newer GNU gcc
perl -ni -we 'print unless /<(?:built-in|command)/' makefile x2p/makefile

# if you just need miniperl, replace test_prep with miniperl
make -j18 install
[ -x ./perl ] || exit 125
git checkout makedepend.SH
VER=`./perl -e'print substr ($^V, 1)'`
ln -s perl${VER} $BASE_DIR/bin/perl
# This runs the actual testcase. You could use -e instead:

# testing a simple test case
#echo '#127568: \w'
#$BASE_DIR/bin/perl -e 'my $f = $ENV{user} =~ qr{_?[\W\_]}; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant: PI'
#$BASE_DIR/bin/perl -e 'use utf8; use constant PI => 4 * atan2(1, 1); print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'
#echo '#127392: constant only'
#$BASE_DIR/bin/perl -e 'use constant; print qx{egrep "VmRSS|VmPeak" /proc/$$/status}'

$BASE_DIR/bin/perl -E 'say qq{## Perl $] installed}'



#if you need to invert the exit code, replace the above exit with this:
#[ $ret -eq 0 ] && exit 1
#exit 0
