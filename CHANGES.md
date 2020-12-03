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
