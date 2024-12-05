# Peninsula

A macOS notch app that helps you manage your Mac.

## Installation

1. Go to [Releases](https://github.com/Celve/Peninsula/releases) to download the latest version (the zip).
2. Unzip the file and run the Peninsula.app.
3. Trust the app in Privacy & Security in System Settings.
4. Grant access to Accessibility.

Accessibility is required for Peninsula to get the app list and show the notification count. You can also build the app yourself with this GitHub repo.

## Features

### Cmd-Tab

Replace the default Cmd-Tab with a more useful app switcher. Use `cmd + tab` to show the app switcher:

- Hold `cmd` and press `tab` to move to the next app
- Hold `cmd` and press `shift` to move to the previous app
- Hold `cmd` and press `esc` to exit the app switcher and do nothing
- Unhold `cmd` to select the app

This part of code mainly comes from [alt-tab-macos](https://github.com/lwouis/alt-tab-macos).

<https://github.com/user-attachments/assets/d58ce0d5-c685-44df-9a50-4afe99a710db>

### Switch inside Peninsula

Click the original notch to show Peninsula, and click again to move to next Peninsula window.
Click anywhere outside Peninsula to exit.

There are totally 5 Peninsula windows currently:

- Inner-screen App Switcher: show all running apps on the current screen
- Notification Center: show all notifcation apps you have added
- Tray: place and fetch some temporary files
- Menu: basic operations, like quit Peninsula, etc.
- Settings: settings for Peninsula

This part of code mainly comes from [NotchDrop](https://github.com/Lakr233/NotchDrop).

<https://github.com/user-attachments/assets/876388d9-a1cf-4317-b799-48c8ba5b0c85>

### Notification Center

Add your favorite notification apps to Peninsula.
By clicking the add button on the top right corner of notification center, you can select the apps you want to add.
Click the minus button to remove the app.

When any notification comes, Peninsula will show the app icon in the right hand side of the notch. Click the icon to open the app.
It will last for 6.18 seconds and then show the total number of notifications. Click the number to open the notification center.

This part of code mainly comes from [Doll](https://github.com/xiaogdgenuine/Doll).

<https://github.com/user-attachments/assets/37d7d89c-57ad-49b9-a8cf-8bedd3971458>
