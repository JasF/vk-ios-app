#!/bin/bash

BuildDir=`mktemp -d /tmp/package-XXXXXX`

function usage {
    echo ""
    echo "Usage: $1 <AppFolder> <DSYMFolder> <ResultName>"
    echo ""
    echo "<AppFolder>  is absolute path to *.app"
    echo "<DSYMFolder> is absolute path to *.dsym"
    echo "<ResultName> is the name for resulting package file in the current directory"
    echo ""
    echo "Following is resulting package structure:"
    echo ""
    echo "<ResultName>/<ResultName>.dSYM"
    echo "<ResultName>/<ResultName>.ipa"
    echo ""
}

function remove_build_dir {
    if [ -d "$BuildDir" ]
    then
        cd /
        rm -rf "$BuildDir"
    fi
}

function exit_if_error {
    if [ $? -ne 0 ]
    then
        echo "$1"
        remove_build_dir
        exit 1
    fi
}

if [ $# -ne 3 ]
then
    usage $0
    exit 1
fi

AppFolder="$1"
DSYMFolder="$2"
ResultName="$3"
InitialDir=`pwd`

if [ -d "$ResultName" ]
then
    rm -rf "$ResultName"
    exit_if_error "Failed removing previous package"
fi

cd "$BuildDir"
exit_if_error "Failed to change dir"

mkdir Payload
exit_if_error "Failed to create 'Payload' directory'"

cp -rp "$InitialDir"/"$AppFolder" Payload/
exit_if_error "Failed to copy application bundle into 'Payload' folder"

zip -ry "$ResultName".ipa Payload
exit_if_error "Failed to zip 'Payload'"

cd -
exit_if_error "Failed to change directory to original"

mkdir "$ResultName"
exit_if_error "Failed to create artifact dir"

cp "$BuildDir"/"$ResultName".ipa "$ResultName"/
exit_if_error "Failed to copy 'ipa'"

cp -rp "$InitialDir"/"$DSYMFolder" "$ResultName"/"$ResultName".dSYM
exit_if_error "Failed to copy 'dSYM'"

remove_build_dir
