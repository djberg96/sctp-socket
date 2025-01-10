## 0.1.2 - 10-Jan-2025
* Added support for BSD.

## 0.1.1 - 1-Jan-2025
* Added the set_shared_key method.
* Added the get_active_shared_key and set_active_shared_key methods.
* Added the get_initmsg method.
* Added autoclose getter and setter methods.
* Added the enable_auth_support method.
* Added methods for getting, setting or deleting a shared key.
* Added the map_ipv4 method.
* Updated the get_peer_address_params method to include more info.
* Many comment additions and updates.
* Added a rake task to create dummy IP addresses for testing.
* Added a funding_uri to the gemspec.

## 0.1.0 - 31-May-2024
* Added support for sender dry events.
* Added the get_peer_address_params method.
* Comments were added to methods that were missing them.
* Remove version locking for dev dependencies, doesn't matter to me.
* Bumped version to 0.1.0, I guess I'll declare it stable.

## 0.0.7 - 28-May-2024
* Added the recvv method.
* The getlocalnames and getpeernames methods now accept optional fileno and
  association ID arguments.
* The peeloff method now returns the peeled off fileno and no longer modifies
  the receiver, so I dropped the exclamation point from the method name.
* Added the get_subscriptions method.
* Changed bind method to bindx and connect method to connectx. I may try to
  subclass Socket someday so I didn't want a conflict, and this more closely
  matches the underlying function name anyway.
* Changed the sock_fd method to fileno.
* Changed the default backlog from 1024 to 128 for the listen method.
* Updated comments and documentation.
* Added more specs.

## 0.0.6 - 24-May-2024
* Fixup the sendv method and add some documentation.
* Added documentation to the get_status method.
* Update the example server and client code, including comments for how to
  setup multiple dummy IP addresses locally for testing.
* Some warning cleanup and build improvements.
* Added SCTP_BINDX constants.
* Started adding some real specs.

## 0.0.5 - 15-Dec-2021
* Add handling for Linux platforms that don't support the sctp_sendv function
  and/or the SCTP_SEND_FAILED_EVENT notification.
* Some minor updates to Rakefile and Gemfile.

## 0.0.4 - 3-Dec-2020
* Added the send method. Use this when you already have a connection.
* Fixed a flags bug in the sendmsg method.
* Fixed an association_id typo in the connect method.
* The SCTP_PR_SCTP_TTL flag is automatically set if a TTL value is provided.
* Added some constants so you can actually start passing flag values.

## 0.0.3 - 1-Dec-2020
* Added notification hooks that you can subscribe to, so now the subscribe method
  actually does something.

## 0.0.2 - 29-Nov-2020
* Fixed the homepage link in the gemspec metadata. Thanks go to Nick LaMuro for the patch.
* The getlocalnames and getpeernames now return an array of addresses.
* Added a shutdown method.
* Added more documentation.

## 0.0.1 - 24-Nov-2020
* Initial release.
