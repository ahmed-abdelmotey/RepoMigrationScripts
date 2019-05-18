#!/bin/bash
branches=`git branch --list | sed -e 's/\(^\* \|^  \)//g' | cut -d " " -f 2`;
error=
for branch in $branches; do
  remote=`git branch -a | egrep "origin/$branch" | wc -l`
  if [ $remote -gt 0 ];
  then
    commits=`git log --oneline origin/$branch..$branch | wc -l`;
    if [ $commits -gt 0 ];
    then
    errors+="$branch:$commits\n"
    fi

  else
    errors+="$branch:0\n"
  fi
done

echo -e ${errors::-2} | sort -t ':' -rnk 2 | awk '
    BEGIN{ FS=":"; RS="\n";
        print "---------------------------------------------------------------------------------"
        print "> Branches analysis";
        print "---------------------------------------------------------------------------------"
        print "Branch name                                                  | Missing Updates   "
        print "---------------------------------------------------------------------------------"
    }
    {
        printf("%-60s | %-2s %-s\n",$1,$2==0?"-":$2,$2==0?"missing branch":"missing commits")
    }
    END{
        print "---------------------------------------------------------------------------------"
        printf("* %-2d branches needs your attention\n", NR)
        print "---------------------------------------------------------------------------------"
    }
'

stashes=`git stash list --format="%gd:%s" |
    sed -e 's/\(:[^:]*\)//2' |
    sed -e 's/\(WIP on \|On \)//g' |
    sort -t ':' -k 2 | xargs -d ' ' -n 1`

stashlist=
for stash in $stashes; do
    id=`echo $stash | cut -d ':' -f 1 | sed -e 's/[^0-9]*//g'`
    branch=`echo $stash | cut -d ':' -f 2`
    changes=`git stash show --stat stash@{$id} | head -n -1 | wc -l`
    stashlist+="$id:$branch:$changes\n"
done

echo -e ${stashlist::-2} | sort -t ':' -rnk 3 | awk '
     BEGIN{ FS=":"; RS="\n";
        print "> Stash analysis";
        print "---------------------------------------------------------------------------------"
        print "  ID  | Branch name                                          | Change(s) "
        print "---------------------------------------------------------------------------------"
    }
    {
        printf("%5d | %-52s | %-2d file(s) changed\n",$1,$2,$3)
    }
    END{
        print "---------------------------------------------------------------------------------"
        printf("* %-2d stashes needs your attention\n", NR)
        print "* To view stash type git stash show stash@{ID}"
        print "---------------------------------------------------------------------------------"
    }
'
