# Peninsula

A macOS notch app that helps you manage your Mac.

## Features

### Cmd-Tab

Replace the default Cmd-Tab with a more useful app switcher. Use `cmd + tab` to show the app switcher:

- Hold `cmd` and press `tab` to move to the next app
- Hold `cmd` and press `shift` to move to the previous app
- Hold `cmd` and press `esc` to exit the app switcher and do nothing
- Unhold `cmd` to select the app

This part of code mainly comes from [alt-tab-macos](https://github.com/lwouis/alt-tab-macos).

### Switch inside Peninsula

Click the original notch to show Peninsula, and click again to move to next Peninsula window.
Click anywhere outside Peninsula to exit.

There are totally 5 Peninsula windows currently:

- Inner-screen App Switcher: show all running apps on the current screen
- Notification Center: show all notifcation apps you have added
- Tray: place and fetch some temporary files
- Menu: basic operations
- Settings: settings for Peninsula

This part of code mainly comes from [NotchDrop](https://github.com/Lakr233/NotchDrop).

### Notification Center

Add your favorite notification apps to Peninsula.
By clicking the add button on the top right corner of notification center, you can select the apps you want to add.
Click the minus button to remove the app.

When any notification comes, Peninsula will show the app icon in the right hand side of the notch. Click the icon to open the app.
It will last for 6.18 seconds and then show the total number of notifications. Click the number to open the notification center.

This part of code mainly comes from [Doll](https://github.com/xiaogdgenuine/Doll).
