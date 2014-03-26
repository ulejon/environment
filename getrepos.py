#!/usr/bin/python
import json, urllib2, os, time, calendar, pickle

CACHE_AGE_LIMIT = 1200
cachefile = "/tmp/.repocache"
gitblitserverurl = "http://pogit:8080/gitblit/"

def getrepolist():
    if (not os.path.isfile(cachefile) or calendar.timegm(time.gmtime()) - os.path.getmtime(cachefile) > CACHE_AGE_LIMIT):
        repos = getrepolistfromserver(gitblitserverurl)
        with open(cachefile, 'wb') as f:
            pickle.dump(repos, f)
    else:
        with open(cachefile, 'r') as f:
            repos = pickle.load(f)

    return repos

def getrepolistfromserver( serverurl ):
    req = "rpc?req="
    listrepos = "LIST_REPOSITORIES"
    url = serverurl + req + listrepos

    resp = urllib2.urlopen(url)
    data = json.load(resp)
    repos = []
    for r in data:
        repos.append(data[r]['name'].encode("utf-8")[:-4])

    return repos


print "\n".join(getrepolist())
