RoombaController
====================

An iOS Static Library for controlling a Roomba Vacuum connected to a WiFi Dongle such as a WiSnap or WiFly.

Required Parts:
 - Roomba Vacuum with SCI Port
 - WiFi-to-RS232 Dongle (http://serialio.com/products/wifi/wisnap-dongles/wisnap-aaa-wifi-dongle)
 - Roo232 Roomba to Serial RS232 Bridge (http://www.protechrobotics.com/proddetail.php?prod=DEV-00740)
 - A standard 7-pin Male/Male Mini-DIN cable

This controller library also depends on the WiFiDongleController library located here:
http://github.com/manybothans/WiFiDongleController

From RoombaController's "Products" directory, add "RoombaController.a" to the "Link Binary with Library" Build Phase of your Application's Target. Also add "/path/to/RoombaController/Products/include" to "Header Search Paths" in your Application's Target's Build Settings.

Also, from WiFiDongleController's "Products" directory, add "WiFiDongleController.a" to the "Link Binary with Library" Build Phase of your Application's Target. Also add "/path/to/WiFIDongleController/trunk/Products/include" to "Header Search Paths" in your Application's Target's Build Settings.

SystemConfiguration.framework must also be included in the "Link Binary with Library" Build Phase of your Application's Target.