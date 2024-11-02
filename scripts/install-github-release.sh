#!/usr/bin/env bash
set -e

DEFAULT_URL_KEY="browser_download_url"


main(){
    if [ -z "$REPO" ]; then
        usage
        exit 1
    fi
    echo "Query for $REPO"
    echo
    api_url="https://api.github.com/repos/$REPO/releases/latest"
    echo "API: $api_url"
    echo
    candidates=$(curl $SET_PROXY -sSfL $api_url | grep -P $MATCH_RELEASE)
    echo "Candidates:"
    echo "$candidates"
    echo
    dl_url=$(echo "$candidates" | grep $URL_KEY | cut -d '"' -f 4)
    echo "From:"
    echo "$dl_url"
    echo

    if [ $(echo -e "$dl_url" | wc -l) -ne 1 ] || [ -z $dl_url ]; then
        usage
        exit 1
    fi
    if [ -z $PROG_NAME ] || [ -z $VER_PARAM ] ; then
        curr_ver="VERSION_NOT_EXIST"
    else
        curr_ver=$($PROG_PATH/$PROG_NAME $VER_PARAM 2>/dev/null||echo VERSION_NOT_EXIST)
    fi

    if (echo $dl_url | grep -i $curr_ver) >/dev/null 2>&1; then
        echo "Already latest version!"
    else
        if [ -z $PROG_PATH ]; then
            exit 0
        fi
        echo "Downloading..."
        pkgname=$(echo $dl_url | awk -F'/' '{print $NF}')
        if [ ! -z $PKG_NAME ]; then
            pkgname=$PKG_NAME
        fi
        tmp_dir="/tmp/$pkgname-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
        mkdir -p "$tmp_dir"
        pushd "$tmp_dir" >/dev/null 2>&1
        ext=$(echo $pkgname | awk -F'.' '{print $NF}')
        ext_tar=$(echo $pkgname | awk -F'.' '{print $(NF-1)}')
        dirname=
        if (echo $ext | grep -i zip) >/dev/null 2>&1; then
            curl $SET_PROXY -SfLo source_pkg.zip "$dl_url"
            unzip -o source_pkg.zip
            dirname=$(rev <<< $pkgname | cut -d '.' -f 2- | rev)
        elif (echo $ext_tar | grep -i tar) >/dev/null 2>&1; then
            curl $SET_PROXY -SfLo source_pkg.tar.$ext "$dl_url"
            tar -xvf source_pkg.tar.$ext
            dirname=$(rev <<< $pkgname | cut -d '.' -f 3- | rev)
        else
            echo "Unknown format: $pkgname"
            exit 1
        fi
        if [ ! -z $PKG_DIR ]; then
            if [ "$PKG_DIR" = "-" ]; then
                if [ -z $SED_EXP ]; then
                    cd $dirname
                else
                    cd $(echo $dirname | sed $SED_EXP)
                fi
            elif [ $PKG_DIR -ge 0 ]; then
                dirs=$(ls -l|awk '/^d/ {print $NF}')
                arr_dirs=($dirs)
                cd ${arr_dirs[$PKG_DIR]}
            else
                cd $PKG_DIR
            fi
        fi

        CWD=$(pwd)
        if [ ${CWD:0:5} != "/tmp/" ]; then
            echo "Wrong dir inside package!"
            exit 1
        fi
        echo
        echo "Installing..."
        echo "From: $CWD"
        echo "To: $PROG_PATH/"
        cp -fr * "$PROG_PATH/"
        if [ -z $PROG_NAME ]; then
            echo "Install Complete!"
        else
            chmod +x "$PROG_PATH/$PROG_NAME"
            if [ -z $VER_PARAM ]; then
                echo "Install Complete!"
            else
                echo "Install Complete ($curr_ver -> $($PROG_PATH/$PROG_NAME $VER_PARAM 2>/dev/null||echo VERSION_NOT_EXIST))!"
            fi
        fi
        popd >/dev/null
        rm -rf "$tmp_dir"

        if [ ! -z "$CMD_RELOAD" ]; then
            $CMD_RELOAD
        fi
    fi
}


usage(){
    echo "Usage: $0 [OPTIONS]";
    echo "Options:";
    echo "    -r <REPO>        Github repo (required)";
    echo "    -m <MATCH>       Match release with regexp (required)";
    echo "    -k <KEY>         URL key for Github API (default: $DEFAULT_URL_KEY)";
    echo "    -p <PATH>        Program path";
    echo "    -n <NAME>        Program name";
    echo "    -o <NAME>        Package name";
    echo "    -d <DIR>         Dir inside package (set number as index; set '-' as packge name)";
    echo "    -e <EXP>         Expression for sed (only for '-d -')";
    echo "    -v <VERSION>     Version param";
    echo "    -c <COMMAND>     Command for reload";
    echo "    -x <PROXY>       Proxy [protocol://]host[:port]";
}

REPO=
MATCH_RELEASE=
URL_KEY=$DEFAULT_URL_KEY
PROG_PATH=
PROG_NAME=
PKG_NAME=
PKG_DIR=
SED_EXP=
VER_PARAM=
CMD_RELOAD=
SET_PROXY=
while getopts ":r:m:k:p:n:o:d:e:v:c:x:" OPT; do
    case $OPT in
        r)
            REPO=$OPTARG;
            ;;
        m)
            MATCH_RELEASE=$OPTARG;
            ;;
        k)
            URL_KEY=$OPTARG;
            ;;
        p)
            PROG_PATH=$(realpath -e $OPTARG);
            ;;
        n)
            PROG_NAME=$OPTARG;
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
        v)
            VER_PARAM=$OPTARG;
            ;;
        c)
            CMD_RELOAD=$OPTARG;
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
