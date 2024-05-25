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
