function detect_package_manager {
    local text="Checking for available package manager (DNF/Microdnf/YUM/Zypper) ..."
    echo_running "$text"
    if check_tool_silent "zypper"; then
        manager="zypper"
    elif check_tool_silent "dnf"; then
        manager="dnf"
    elif check_tool_silent "yum"; then
        manager="yum"
    elif check_tool_silent "microdnf"; then
        manager="microdnf"
    fi

    if test -z "$manager"; then
        echo_okfail_rc 1 "$text" ||
            die "Could not detect your package manager, is this an RPM-based system?"
    fi

    echo_okfail_rc 0 "$text"
    echo_helptext "Detected package manager as '$manager'"
    return 0
}

function setup_repository {
    if test "$manager" == "yum" -o "$manager" == "dnf"; then
        check_rpm_tool "yum-utils"
    fi
    if test "$manager" == "dnf"; then
        check_rpm_tool "dnf-plugin-config-manager"
    fi

    local repofile="$tmpdir/balena-etcher.repo"
    check_fetch_config

    local text="Fetching 'balena/etcher' repository configuration ..."
    echo_running "$text"
    fetch_config > "$repofile"
    echo_okfail "$text" || die "Could not fetch repository config!"

    local text="Installing 'balena/etcher' repository via $manager ..."
    echo_running "$text"

    if test "$manager" == "yum" -o "$manager" == "dnf"; then
        if test "$manager" == "yum"; then
            local yum_dnf_config_manager="yum-config-manager"
        elif test "$manager" == "dnf"; then
            local yum_dnf_config_manager="dnf config-manager"
        fi

        $yum_dnf_config_manager --add-repo "$repofile" &>$tmp_log
        local rc=$?
    elif test "$manager" == "microdnf"; then
        mv "$repofile" "/etc/yum.repos.d/balena-etcher.repo"
        local rc=$?
    else
        zypper ar -f $repo_file "$repofile" &>$tmp_log
        local rc=$?
    fi

    echo_okfail_rc $rc "$text" || die "Could not install the repository, do you have permissions?"

    local text="Updating the $manager cache to fetch the new repository metadata ..."
    echo_running "$text"

    if test "$manager" == "yum" -o "$manager" == "dnf"; then
        $manager -q makecache -y \
          --disablerepo='*' --enablerepo='balena-etcher*'
        local rc=$?
    elif test "$manager" == "microdnf"; then
        local min_version="3.8.0"
        local cur_version="$(rpm -q --queryformat '%{VERSION}' microdnf)"

        if [[ "$(printf "%s\n" $cur_version $min_version | sort -V | head -n 1)" != "$min_version" ]]; then
            $manager upgrade microdnf # v3.8+ required to use makecache
        fi

        $manager makecache -y \
          --disablerepo='*' --enablerepo='balena-etcher*'
        local rc=$?
    else
        zypper --gpg-auto-import-keys --non-interactive \
          refresh balena-etcher balena-etcher-source &>$tmp_log
        local rc=$?
    fi

    echo_okfail_rc $rc "$text" || {
        echo_colour "red" "Failed to update via $manager"
        die "Failed to update via $manager."
    }
}

manager=""

rpm --import https://mcraa.github.io/ppa/rpm/repodata/KEY.gpg

setup_repository