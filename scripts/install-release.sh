#!/usr/bin/env bash
set -e

DEFAULT_RELEASE="latest"
DEFAULT_MATCH_STAGE_1="browser_download_url"


main(){
    echo
    if [ -z "$REPO" ] && [ -z "$DD_URL" ]; then
        usage
        exit 1
    fi
    if [ -z "$DD_URL" ]; then
        echo "Query for $REPO"
        echo
        if $VERBOSE; then
            api_url="https://api.github.com/repos/$REPO/releases/$TAG"
            echo "API: $api_url"
            echo
            candidates=$(curl $SET_AUTH $SET_PROXY -sSfL "$api_url" | grep -P "$MATCH_STAGE_1")
            echo "Candidates:"
            echo "$candidates"
            echo
            dl_url=$(echo "$candidates" | grep -P "$MATCH_STAGE_2" | cut -d '"' -f 4)
            echo "From:"
            echo "$dl_url"
            echo
        fi
    else
        dl_url="$DD_URL"
    fi
    if [ $(echo -e "$dl_url" | wc -l) -ne 1 ] || [ -z "$dl_url" ]; then
        exit 0
    fi


    if [ -z "$PROG_PATH" ]; then
        exit 0
    fi
    echo "Prepare tmp directory"
    pkgname=$(echo "$dl_url" | awk -F'/' '{print $NF}')
    if [ ! -z "$PKG_NAME" ]; then
        pkgname="$PKG_NAME"
    fi
    tmp_dir="/tmp/$pkgname-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    mkdir -p "$tmp_dir"
    pushd "$tmp_dir" >/dev/null
    ext=$(echo "$pkgname" | awk -F'.' '{print $NF}')
    ext_tar=$(echo "$pkgname" | awk -F'.' '{print $(NF-1)}')
    dirname=
    echo "Downloading..."
    if $NO_INFLATE; then
        curl $SET_AUTH $SET_PROXY -SfLo $pkgname "$dl_url"
    else
        if (echo $ext | grep -i zip) &>/dev/null; then
            curl $SET_AUTH $SET_PROXY -SfLo source_pkg.zip "$dl_url"
            unzip -o source_pkg.zip >/dev/null
            dirname=$(rev <<< "$pkgname" | cut -d '.' -f 2- | rev)
        elif (echo $ext | grep -i tar) || (echo $ext | grep -i tgz) &>/dev/null; then
            curl $SET_AUTH $SET_PROXY -SfLo source_pkg.$ext "$dl_url"
            tar -xvf source_pkg.$ext >/dev/null
            dirname=$(rev <<< "$pkgname" | cut -d '.' -f 2- | rev)
        elif (echo $ext_tar | grep -i tar) &>/dev/null; then
            curl $SET_AUTH $SET_PROXY -SfLo source_pkg.tar.$ext "$dl_url"
            tar -xvf source_pkg.tar.$ext >/dev/null
            dirname=$(rev <<< "$pkgname" | cut -d '.' -f 3- | rev)
        else
            echo "Unknown format: $pkgname"
            popd >/dev/null
            rm -rf "$tmp_dir"
            exit 1
        fi
        echo "Inflation complete"
        rm source_pkg.*
    fi
    if [ ! -z "$PKG_DIR" ]; then
        if $VERBOSE; then
            echo
            echo "Source dir:"
        fi
        if [ "$PKG_DIR" = "-" ]; then
            if [ -z $SED_EXP ]; then
                current_dir=$dirname
            else
                current_dir=$(echo $dirname | sed -E $SED_EXP)
            fi
            if [ -d "$current_dir" ]; then
                if $VERBOSE; then
                    echo "$current_dir"
                fi
                cd "$current_dir"
            else
                else
                echo "Wrong dir inside package!"
                popd >/dev/null
                rm -rf "$tmp_dir"
                exit 1
            fi
        else
            indices=($PKG_DIR)
            for index in ${indices[@]}; do
                if [ "$index" -ge 0 ] &>/dev/null; then
                    dirs=$(ls -l|awk '/^d/ {print $NF}')
                    arr_dirs=($dirs)
                    current_dir=${arr_dirs[$index]}
                else
                    current_dir=$index
                fi
                if [ -d "$current_dir" ]; then
                    if $VERBOSE; then
                        echo "$current_dir"
                    fi
                    cd "$current_dir"
                else
                    echo "Wrong dir inside package!"
                    popd >/dev/null
                    rm -rf "$tmp_dir"
                    exit 1
                fi
            done
        fi
    fi
    CWD=$(pwd)
    if [ ${CWD:0:5} != "/tmp/" ]; then
        echo "Wrong dir inside package!"
        popd >/dev/null
        rm -rf "$tmp_dir"
        exit 1
    fi

    PROG_PATH=$(realpath "$PROG_PATH");
    echo
    echo "Installing..."
    echo "From: $CWD"
    echo "To: $PROG_PATH/"
    if [ ! -d "$PROG_PATH" ]; then
        if [ -e "$PROG_PATH" ]; then
            echo "Program path is not directory!"
            popd >/dev/null
            rm -rf "$tmp_dir"
            exit 1
        else
            mkdir -p "$PROG_PATH"
        fi
    fi
    if [ -z "$PROG_NAME" ]; then
        cp -fr * "$PROG_PATH/"
    else
        if command -v md5sum &>/dev/null; then
            echo "Version check"
            old_hash=$(md5sum -bz "$PROG_PATH/$PROG_NAME" | awk '{print $1}')
            new_hash=$(md5sum -bz "$PROG_NAME" | awk '{print $1}')
            if [ "$new_hash" = "$old_hash" ]; then
                echo "No need to update."
                popd >/dev/null
                rm -rf "$tmp_dir"
                exit 0
            fi
        fi
        if $FILE_COPY; then
            cp -f "$PROG_NAME" "$PROG_PATH/"
        else
            cp -fr * "$PROG_PATH/"
        fi
        chmod +x "$PROG_PATH/$PROG_NAME"
    fi
    echo "Install Complete!"
    popd >/dev/null
    rm -rf "$tmp_dir"

    if [ ! -z "$CMD_RELOAD" ]; then
        $CMD_RELOAD
    fi
}


usage(){
    echo "Usage: $0 [OPTIONS]";
    echo "Options:";
    echo "    -r <REPO>        Github repo";
    echo "    -t <TAG>         Release tag (default: $DEFAULT_RELEASE)";
    echo "    -k <KEY>         Match stage 1 with regexp (default: $DEFAULT_MATCH_STAGE_1)";
    echo "    -m <MATCH>       Match stage 2 with regexp";
    echo "    -u <URL>         Direct download url (bypass query repo)";
    echo "    -b               Do not inflate";
    echo "    -p <PATH>        Program path";
    echo "    -n <NAME>        Program name";
    echo "    -f               Copy program name file only (when -n is set)";
    echo "    -o <NAME>        Package name";
    echo "    -d <DIR>         Dir inside package:";
    echo "                         '-' as packge name without extension";
    echo "                         space separated stirng mixed with:";
    echo "                             number as index";
    echo "                             string as name";
    echo "    -e <EXP>         Expression for sed (only for '-d -')";
    echo "    -c <COMMAND>     Command for reload";
    echo "    -v               Verbose";
    echo "    -a <USER:PASS>   Auth user[:pass]";
    echo "    -x <PROXY>       Proxy [protocol://]host[:port]";
}

REPO=
TAG=$DEFAULT_RELEASE
MATCH_STAGE_1=$DEFAULT_MATCH_STAGE_1
MATCH_STAGE_2=
DD_URL=
NO_INFLATE=false
PROG_PATH=
PROG_NAME=
FILE_COPY=false
PKG_NAME=
PKG_DIR=
SED_EXP=
CMD_RELOAD=
VERBOSE=false
SET_AUTH=
SET_PROXY=
while getopts ":r:t:k:m:u:bp:n:fo:d:e:c:va:x:" OPT; do
    case $OPT in
        r)
            REPO=$OPTARG;
            ;;
        t)
            TAG="tags/$OPTARG";
            ;;
        k)
            MATCH_STAGE_1=$OPTARG;
            ;;
        m)
            MATCH_STAGE_2=$OPTARG;
            ;;
        u)
            DD_URL=$OPTARG;
            ;;
        b)
            NO_INFLATE=true;
            ;;
        p)
            PROG_PATH=$OPTARG;
            ;;
        n)
            PROG_NAME=$OPTARG;
            ;;
        f)
            FILE_COPY=true;
            ;;
        o)
            PKG_NAME=$OPTARG;
            ;;
        d)
            PKG_DIR=$OPTARG;
            ;;
        e)
            SED_EXP=$OPTARG;
            ;;
        c)
            CMD_RELOAD=$OPTARG;
            ;;
        v)
            VERBOSE=true;
            ;;
        a)
            SET_AUTH="-u $OPTARG";
            ;;
        x)
            SET_PROXY="-x $OPTARG";
            ;;
        :)
            echo "Option -$OPTARG requires an argument.";
            exit 1;;
        ?)
            echo "Invalid Option: -$OPTARG";
            usage;
            exit 1;;
    esac;
done;

main
