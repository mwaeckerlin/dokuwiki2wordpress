#!/bin/bash -e

# internal use only
append_msg() {
    if test $# -ne 0; then
        echo -en ":\e[0m \e[1m$*"
    fi
    echo -e "\e[0m"
}

# write a notice
notice() {
    if test $# -eq 0; then
        return
    fi
    echo -e "\e[1m$*\e[0m" 1>&3
}

# write error message
error() {
    echo -en "\e[1;31merror" 1>&2
    append_msg $* 1>&2
}

# write a warning message
warning() {
    echo -en "\e[1;33mwarning" 1>&2
    append_msg $* 1>&2
}

# write a success message
success() {
    echo -en "\e[1;32msuccess" 1>&2
    append_msg $* 1>&2
}

# commandline parameter evaluation
PATH_TO_DOKUWIKI=${PATH_TO_DOKUWIKI:-$(pwd)}
while test $# -gt 0; do
    case "$1" in
        (--help|-h) less <<EOF
SYNOPSIS

  $0 [OPTIONS] [FILES]

OPTIONS

  --help, -h                 show this help
  --path, -p <path>          path to dokuwiki (default: $PATH_TO_DOKUWIKI)

FILES

  Files to convert. By default converts all files in data/pages. Path
  must be relative to the path to dokuwiki.

  e.g. $0 data/pages/path/to/a/file.txt

DESCRIPTION

Converts dokuwiki to wordpress, generates an RSS-XML file to import in wordpress.

EOF
                    exit;;
        (--path|-p) shift; PATH_TO_DOKUWIKI=$1;;
        (*) break;;
    esac
    if test $# -eq 0; then
        error "missing parameter, try $0 --help"; exit 1
    fi
    shift;
done

# run a command, print the result and abort in case of error
# option: --no-check: ignore the result, continue in case of error
run() {
    check=1
    while test $# -gt 0; do
        case "$1" in
            (--no-check) check=0;;
            (*) break;;
        esac
        shift;
    done
    echo -en "\e[1m-> running:\e[0m $* ..."
    result=$($* 2>&1)
    res=$?
    if test $res -ne 0; then
        if test $check -eq 1; then
            error "failed with return code: $res"
            if test -n "$result"; then
                echo "$result"
            fi
            exit 1
        else
            warning "ignored return code: $res"
        fi
    else
        success
    fi
}

# error handler
function traperror() {
    set +x
    local err=($1) # error status
    local line="$2" # LINENO
    local linecallfunc="$3"
    local command="$4"
    local funcstack="$5"
    for e in ${err[@]}; do
        if test -n "$e" -a "$e" != "0"; then
            error "line $line - command '$command' exited with status: $e (${err[@]})"
            if [ "${funcstack}" != "main" -o "$linecallfunc" != "0" ]; then
                echo -n "   ... error at ${funcstack} "
                if [ "$linecallfunc" != "" ]; then
                    echo -n "called at line $linecallfunc"
                fi
                echo
            fi
            exit $e
        fi
    done
    success
    exit 0
}

# catch errors
trap 'traperror "$? ${PIPESTATUS[@]}" $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}" "${FUNCTION}"' ERR SIGINT INT TERM EXIT

##########################################################################################

cp ${0%/*}/dokucli.php ${PATH_TO_DOKUWIKI}/bin/
cd $PATH_TO_DOKUWIKI
cat<<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0"
    xmlns:excerpt="http://wordpress.org/export/1.2/excerpt/"
    xmlns:content="http://purl.org/rss/1.0/modules/content/"
    xmlns:wfw="http://wellformedweb.org/CommentAPI/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:wp="http://wordpress.org/export/1.2/" >

    <channel>
        <wp:wxr_version>1.2</wp:wxr_version>
EOF
for file in ${*:-$(find data/pages/)}; do
    path=${file#data/pages}
    filename=${file##*/}
    categories=${path%${filename}}
    categories=${tags%/}
    title="$(sed -n '/^ *=\+ *\([^ ].*[^ =]\) *=\+ *$/{s//\1/p;q}' ${file})"
    title=${title:-${filename%.txt}}
    cat <<EOF
        <item>
            <title>$title</title>
            <dc:creator><![CDATA[admin]]></dc:creator>
            <description></description>
            <content:encoded><![CDATA[
$(php $PATH_TO_DOKUWIKI/bin/dokucli.php < $file)
]]></content:encoded>
            <excerpt:encoded><![CDATA[]]></excerpt:encoded>
            <wp:post_date>2015-03-03 16:20:00</wp:post_date>
            <wp:status>publish</wp:status>
            <wp:post_type>post</wp:post_type>
        </item>
EOF
done
cat <<EOF
    </channel>
</rss>
EOF
