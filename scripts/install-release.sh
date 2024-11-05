#!/usr/bin/env bash
set -e

DEFAULT_RELEASE="latest"
DEFAULT_MATCH_STAGE_1="browser_download_url"


main(){
    if [ -z "$REPO" ] && [ -z "$DD_URL" ]; then
        usage
        exit 1
    fi
    if [ -z "$DD_URL" ]; then
        echo "Query for $REPO"
        echo
        api_url="https://api.github.com/repos/$REPO/releases/$TAG"
        echo "API: $api_url"
        echo
        candidates=$(curl $SET_AUTH $SET_PROXY -sSfL "$api_url" | grep -P "$MATCH_STAGE_1")
        echo "Candidates:"
        echo "$candidates"
        echo
        dl_url=$(echo "$candidates" | grep -P "$MATCH_STAGE_2" | cut -d '"' -f 4)
    else
        dl_url="$DD_URL"
    fi
    if [ $(echo -e "$dl_url" | wc -l) -ne 1 ] || [ -z "$dl_url" ]; then
        exit 0
    fi
    echo "From:"
    echo "$dl_url"
    echo


    if [ -z "$PROG_PATH" ]; then
        exit 0
    fi
    echo "12/3" | awk -F'/' '{print $NF}'
    echo "Prepare tmp directory"
    pkgname=$(echo "$dl_url" | awk -F'/' '{print $NF}')
    echo "test1"
    if [ ! -z "$PKG_NAME" ]; then
        pkgname="$PKG_NAME"
    fi
    echo "test2"
    tmp_dir="/tmp/$pkgname-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
    echo "test3"

    mkdir -p "$tmp_dir"
    pushd "$tmp_dir" >/dev/null 2>&1
    ext=$(echo "$pkgname" | awk -F'.' '{print $NF}')
    ext_tar=$(echo "$pkgname" | awk -F'.' '{print $(NF-1)}')
    dirname=
    echo "Downloading..."
    if (echo $ext | grep -i zip) >/dev/null 2>&1; then
        curl $SET_AUTH $SET_PROXY -SfLo source_pkg.zip "$dl_url"
        unzip -o source_pkg.zip
        dirname=$(rev <<< "$pkgname" | cut -d '.' -f 2- | rev)
    elif (echo $ext | grep -i tar) || (echo $ext | grep -i tgz) >/dev/null 2>&1; then
        curl $SET_AUTH $SET_PROXY -SfLo source_pkg.$ext "$dl_url"
        tar -xvf source_pkg.$ext
        dirname=$(rev <<< "$pkgname" | cut -d '.' -f 2- | rev)
    elif (echo $ext_tar | grep -i tar) >/dev/null 2>&1; then
        curl $SET_AUTH $SET_PROXY -SfLo source_pkg.tar.$ext "$dl_url"
        tar -xvf source_pkg.tar.$ext
        dirname=$(rev <<< "$pkgname" | cut -d '.' -f 3- | rev)
    else
        echo "Unknown format: $pkgname"
        exit 1
    fi
    echo "Inflation complete"
    rm source_pkg.*
    if [ ! -z "$PKG_DIR" ]; then
        if [ "$PKG_DIR" = "-" ]; then
            if [ -z $SED_EXP ]; then
                cd "$dirname"
            else
                cd "$(echo $dirname | sed -E $SED_EXP)"
            fi
        elif [ $PKG_DIR -ge 0 ]; then
            dirs=$(ls -l|awk '/^d/ {print $NF}')
            arr_dirs=($dirs)
            cd "${arr_dirs[$PKG_DIR]}"
        else
            cd "$PKG_DIR"
        fi
    fi
    CWD=$(pwd)
    if [ ${CWD:0:5} != "/tmp/" ]; then
        echo "Wrong dir inside package!"
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
            exit 1
        else
            mkdir -p "$PROG_PATH"
        fi
    fi
    if [ -z "$PROG_NAME" ]; then
        cp -fr * "$PROG_PATH/"
    else
        if [ $FILE_COPY -eq 1 ]; then
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
    echo "    -p <PATH>        Program path";
    echo "    -n <NAME>        Program name";
    echo "    -f               Copy program name file only (when -n is set)";
    echo "    -o <NAME>        Package name";
    echo "    -d <DIR>         Dir inside package (set number as index; set '-' as packge name)";
    echo "    -e <EXP>         Expression for sed (only for '-d -')";
    echo "    -c <COMMAND>     Command for reload";
    echo "    -a <USER:PASS>   Auth user[:pass]";
    echo "    -x <PROXY>       Proxy [protocol://]host[:port]";
}

REPO=
TAG=$DEFAULT_RELEASE
MATCH_STAGE_1=$DEFAULT_MATCH_STAGE_1
MATCH_STAGE_2=
DD_URL=
PROG_PATH=
PROG_NAME=
FILE_COPY=0
PKG_NAME=
PKG_DIR=
SED_EXP=
CMD_RELOAD=
SET_AUTH=
SET_PROXY=
while getopts ":r:t:k:m:u:p:n:fo:d:e:c:a:x:" OPT; do
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
        p)
            PROG_PATH=$OPTARG;
            ;;
        n)
            PROG_NAME=$OPTARG;
            ;;
        f)
            FILE_COPY=1;
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
