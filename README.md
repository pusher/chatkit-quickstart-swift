# chatkit-getting-started-swift

The starter project to accompany the Getting Started guide for Chatkit
You can find the corresponding guide [in the Chatkit documentation](https://pusher.com/docs/chatkit/getting_started/swift).

Check out the [complete](https://github.com/pusher/chatkit-getting-started-swift/tree/complete) branch so you can follow the getting start guide and add the code yourself!

## Requirements

Recent versions of:

- Xcode
- Cocoapods
- Node.JS

## Contents

- `app` - the Xcode project with the sample app
- `server` - the corresponding server scripts

## Assets attribution

User avatar images used in the demo app are made by [Freepik](https://www.freepik.com/home) from www.flaticon.com

## Install script for quick start within dashboard

Within the dashboard we have a quickstart which uses this repo. The shell script is used to get people running quickly.
It does the following:

- clones the repo
- installs the dependencies with Cocoapods
- Injects the credentials, which as passed as an argument

And can be ran like so:

```
❯ sh -c "$(curl -fsSL https://raw.githubusercontent.com/pusher/chatkit-quickstart-swift/start/chatkit-quickstart-install.sh)" YOUR_INSTANCE_LOCATOR
```
