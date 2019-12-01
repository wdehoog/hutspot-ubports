Hutspot is currently an unconfined app. This is due to implementing the Mpris2 interface and using a powerd DBus method to prevent the phone from suspending while playing audio.

If you want to run it as a confined one you need to add two policy groups to you system and to the apparmor file.
