__muon_dir ()
{
    if [ -d ".muon" ]; then
        echo ".muon"
    else
        echo ""
    fi
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