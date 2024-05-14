for hostname in "$@" ; do
  echo "Handling host $hostname ... pinging first ... output following:"
  if salt "$hostname" test.ping ; then
    echo "Deploying new os-release file for rel $RELEASE on $hostname"
    salt "$hostname" state.apply profile.base.os-update-$RELEASE
    echo "Clear all other caches and update data on minion $hostname ... output following:"
    salt "$hostname" state.apply profile.base.sync-salt-information
    echo "Deploy new repositories on $hostname"
    salt "$hostname" state.apply profile.base.zypp
  fi
done
