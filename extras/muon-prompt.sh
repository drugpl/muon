__muon_dir ()
{
    local dir=`pwd`
    while [ "$dir" != "/" ]; do
        if [ -d "${dir}/.muon" ]; then
            echo "${dir}/.muon"
            return 0
        else
            dir=`dirname "$dir"`
        fi
    done
}

__muon_ps1 ()
{
    local dir="$(__muon_dir)"
    if [ -n "$dir" ]; then
        if [ -f "$dir/current" ]; then
            echo " [●]"
        else
            echo " [ ]"
        fi
    fi
}