Helper scripts.  These are super dangerous.

Remove all remote non-master branches:
git branch -r | awk -F'origin/' '{print $2}' |grep -v ^master | xargs -I {} git push origin :{}

Delete all local non-master branches:
git branch|grep -v master | xargs -I {} git branch -D {}
