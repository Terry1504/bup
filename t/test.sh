#!/bin/bash
. wvtest.sh
#set -e

TOP="$(pwd)"
export BUP_DIR="$TOP/buptest.tmp"

bup()
{
    "$TOP/bup" "$@"
}

WVSTART "init"

#set -x
rm -rf "$BUP_DIR"
WVPASS bup init

WVSTART "split"

WVPASS bup split --bench -b <testfile1 >tags1.tmp
WVPASS bup split -vvvv -b testfile2 >tags2.tmp
WVPASS bup split -t testfile2 >tags2t.tmp
WVPASS bup split -t testfile2 --fanout 3 >tags2tf.tmp
WVPASS bup split -r "$BUP_DIR" -c testfile2 >tags2c.tmp
WVPASS ls -lR \
   | WVPASS bup split -r "$BUP_DIR" -c --fanout 3 --max-pack-objects 3 -n lslr
WVFAIL diff -u tags1.tmp tags2.tmp

# fanout must be different from non-fanout
WVFAIL diff -q tags2t.tmp tags2tf.tmp
wc -c testfile1 testfile2
wc -l tags1.tmp tags2.tmp

WVSTART "join"
WVPASS bup join $(cat tags1.tmp) >out1.tmp
WVPASS bup join <tags2.tmp >out2.tmp
WVPASS bup join <tags2t.tmp >out2t.tmp
WVPASS bup join -r "$BUP_DIR" <tags2c.tmp >out2c.tmp
WVPASS diff -u testfile1 out1.tmp
WVPASS diff -u testfile2 out2.tmp
WVPASS diff -u testfile2 out2t.tmp
WVPASS diff -u testfile2 out2c.tmp

WVSTART "save/fsck"
(
    set -e
    cd "$BUP_DIR" || exit 1
    #git repack -Ad
    #git prune
    (cd "$TOP/t/sampledata" && WVPASS bup save -vvn master .) || WVFAIL
    n=$(git fsck --full --strict 2>&1 | 
	  egrep -v 'dangling (commit|tree)' |
	  tee -a /dev/stderr | 
	  wc -l)
    WVPASS [ "$n" -eq 0 ]
) || exit 1
