#

tic=$(date +%s)
ns=$(date +%N)
loc="Ecublens (Switzerland)"
symb=timestamp
dir=ts
date=$(date)
pgm=$(readlink -m $0)
echo "--- # $pgm on $date"

playload="$1"

if ipfs key list | grep -q $symb; then
key=$(ipfs key list -l --ipns-base b58mh | grep -w $symb | cut -d' ' -f 1)
ipns=$(ipfs name resolve /ipns/$key)
else
key=$(ipfs key gen -t rsa -s 3072 --ipns-base b58mh $symb)
ipns=QmUNLLsPACCz1vLxQVkXqqLX5R1X345qqfHbsf67hvA3Nn
fi

echo "We've got (time)stamp" | ipfs add --pin=true -q

ver=$(perl -S version -a $0 | xyml scheduled)
echo ver: $ver
gitid=$(git rev-parse --short HEAD)
echo gitid: $gitid
gitdir=$(git rev-parse --absolute-git-dir)
headid=$(cat $gitdir/HEAD | cut -d' ' -f2)
echo headid: $headid

( cd $gitdir; git --bare update-server-info )
dgit=$(ipfs add -r $gitdir -Q)

#set -e
cd $dir
if [ ! -e  original-timestamp.md.gpg ]; then
gpg --sign -u "Michel G. Combes" original-timestamp.md
fi
rm -f original-timestamp.md original-timestamp.md.asc
#gpg --verify original-timestamp.md.gpg
gpg --batch -o original-timestamp.md --verify original-timestamp.md.gpg
gpg --clear-sign -a -u "Michel G. Combes" original-timestamp.md

if expr $tic -  $(stat -c '%X' nip.txt) \> 1711 ; then
 rm nip.txt
fi
if [ ! -e nip.txt ]; then
curl https://iph.heliohost.org/cgi-bin/remote_addr.pl > nip.txt
echo $tic >> nip.txt
echo $$ >> nip.txt
echo $ns >> nip.txt
fi
nip=$(head -1 nip.txt)
echo nip: $nip
# ------------------------------------------------------
artifact=artifact
url=https://www.worldometers.info/coronavirus/
if expr $tic -  $(stat -c '%X' $artifact/index.html) \> 1711 ; then
 rm $artifact/index.html
fi
if [ ! -e $artifact/index.html ]; then
wget $opt -P $artifact -N -nH --cut-dirs=2 -E --convert-file-only -K -p -e robots=off -B "$url" --user-agent="$ua" -a $artifact/log.txt "$url"
fi
pandoc -t html -t markdown $artifact/index.html | grep -v -e ':::' -e '^$' > wmeters.md
pandoc -t html -t plain $artifact/index.html > $artifact/wmeters.txt
if [ -e timestamp.md ]; then
mv timestamp.md previous-timestamp.md
fi
qm=$(ipfs add -r -w nip.txt $artifact previous-timestamp.md *.log $pgm --pin=true -Q)
echo qm: $qm
perl -S fullname.pl -a $qm > bot.yml
sed -e "s/tic: .*/tic: $tic/" -e "s/ver: .*/ver: $ver/" -e "s/ns: .*/ns: $ns/" \
    -e "s,date: .*,date: $date," -e "s/nip: .*/nip: $nip/" \
    -e "s/gitid: .*/gitid: $gitid/" -e "s/dgit: .*/dgit: $dgit/" \
    -e "s/qm: .*/qm: $qm/" -e "s,ipns: .*,ipns: $ipns," \
    -e "s/user: .*/user: $USER/" -e "s/loc: .*/loc: '$loc'/" \
    -e "s|playload: .*|playload: $playload|" \
    previous-timestamp.md > timestamp.md
    pandoc --template=timestamp.md timestamp.md | pandoc -o - | sed -e "s/\`<br>\`{=html}/\n/g" > timestamp.htm 
    gpg --clear-sign -a -u "Michel G. Combes" timestamp.htm

cp -p $gitdir/info/refs info-refs.txt
# ------------------------------------------------------


qm=$(ipfs add -r -w . -Q)
echo $tic: $qm >> qm.log
eval $(perl -S fullname.pl -a $qm | eyml)
git config committer.name "$fullname"
git config committer.email "$user@$domain"
export GIT_COMMITTER_NAME="$fullname"
export GIT_COMMITTER_EMAIL="$email"


git add qm.log timestamp.htm $artifact/wmeters.txt


date=$(date +%D);
time=$(date +%T);

msg="stamped at $date on $time by $fullname (v$ver)"
if git commit -a -m "$msg"; then
gitid=$(git rev-parse HEAD)
git tag -f -a $ver -m "tagging $gitid on $date"
#echo gitid: ${gitid:0:9} # this is bash!
echo gitid: $gitid | cut -b 1-14
if test -e revs.log; then
echo $tic: $gitid >> revs.log
fi

# test if tag $ver exist ...
remote=$(git rev-parse --abbrev-ref @{upstream} |cut -d/ -f 1)
if git ls-remote --tags | grep "$ver"; then
git push --delete $remote "$ver"
fi
fi
git log -3 >> git.log
perl -S uniq.pl git.log | dee -q git.log

( cd $gitdir; git --bare update-server-info )
dgit=$(ipfs add -r $gitdir -Q)
echo $tic: $dgit >> dgit.log

echo "git push : "
branch=$(git rev-parse --abbrev-ref HEAD)
git push --follow-tags $remote $branch
tar zcf ../ts-bal.tgz .
mv ../ts-bal.tgz .
qm=$(ipfs add -w -r . $gitdir/info/refs -Q);
echo $(date +"%s%N"): $qm >> ts-bal.log
ipfs name publish --key=$symb $qm &
# external party
pina $qm "$symb-$(date +%y%m%d%H%M.%S)"
git push github
echo curl -I https://organicgit.github.io/timestamp/timestamp.htm >> curl.log
curl -I https://organicgit.github.io/timestamp/timestamp.htm >> curl.log
git push gitlab
echo curl -I https://gitlab.com/gradual-archi/timestamp/-/raw/master/timestamp.htm >> curl.log
curl -I https://gitlab.com/gradual-archi/timestamp/-/raw/master/timestamp.htm >> curl.log

cp -p timestamp.htm gist/index.html
git -C gist add index.html
git -C gist commit -m "$symb-$(date +%y%m%d%H%M.%S)"
git -C gist push
sleep 1
echo curl -I https://bl.ocks.org/michel47/e001c31cc7eea3cb0032c488f0bb30d3 >> curl.log
curl -I https://bl.ocks.org/michel47/e001c31cc7eea3cb0032c488f0bb30d3 >> curl.log
#git push framagit
#git push bitbucket

