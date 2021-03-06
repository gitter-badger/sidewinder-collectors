#!/bin/bash -e
# ref: https://raw.githubusercontent.com/cdown/travis-automerge/master/travis-automerge

if [ ! -z "$TRAVIS_TAG" ]; then 
   printf "Don't execute releases on tag builds request"
   exit 0
fi

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then 
   printf "Don't execute releases on pull request"
   exit 0
fi

if [ "snapshot" == "$TRAVIS_BRANCH" ]; then
     printf "Snapshot branch will deploy snapshot to Maven central"
     mvn -T2 -B clean deploy
fi

if [ "master" == "$TRAVIS_BRANCH" ]; then 
    printf "Master branch will cut a release to Maven central"
    mkdir -p "/tmp/secrets"
    printf "Extracting SSH Key"
    openssl aes-256-cbc -K $encrypted_91b39159b132_key -iv $encrypted_91b39159b132_iv -in build/secrets.tar.enc -out /tmp/secrets/secrets.tar -d
    tar xf /tmp/secrets/secrets.tar -C /tmp/secrets/
    
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    cp /tmp/secrets/secrets/id_rsa ~/.ssh/id_rsa
    chmod 400 ~/.ssh/id_rsa
    
    git remote set-url origin $REPO
    git checkout master || git checkout -b master
    git reset --hard origin/master
    
    git config --global user.name "Travis CI"
    git config --global user.email "$COMMIT_AUTHOR_EMAIL"
    
    git checkout master || git checkout -b master
    git reset --hard origin/master
    
    gpg -q --fast-import --batch /tmp/secrets/secrets/codesign.asc >> /dev/null
    
    mvn -T2 -B -Darguments=-Dgpg.passphrase=$passphrase release:clean release:prepare release:perform --settings settings.xml
fi
