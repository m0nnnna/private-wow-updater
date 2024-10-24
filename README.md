This is a Powershell + Bat script that will allow for WoW clients to be updated automatically at launch. 

The way this works is by checking an Nginx index download page for time & date. 

You will need a domain and Nginx setup to use the download index. There are plenty of guides out there for this.

Once your index page is setup upload your files to this directly and let it index and make sure the host system has your correct time zone as this does not currently take time zones into account it only checks if the date on the index page is newer or older than the local files. 

In my testing of MPQ files for adding custom items/changes the one for 2.4.3 is "patch-enUS.MPQ" this is the file the script is looking for, you should be able to add in files to check or change what file you want to check. 

It also looks for a txt file called "changes.txt" uploaded in the same directly as the MPQ file for a change log, it will prompt the user to open the txt file after the update is complete.

On line 2 in the Powershell script you will see where to enter the URL of the file, this isn't directly to the file but using your index page naviage to the directory where the files are stored and copy and paste that URL inside of the file. 

It is already set to track the two files listed above. 

Next is the directories for your WoW client. 

In your WoW client folder create a new folder called "Update" put the files into this directory so it works correctly. 

If you encounter issues after updating with content not showing please delete the "cache" directory this changes depending on version of the game. 

This script will also launch your game at the end of the update as long as your WoW client is named "wow.exe".

The Bat file only exists to create a proper shortcut of the script that can also have an icon added to it. 
