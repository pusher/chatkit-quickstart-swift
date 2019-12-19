# chatkit-getting-started-swift

The starter project to accompany the Getting Started guide for Chatkit
You can find the corresponding guide [in the Chatkit documentation](https://pusher.com/docs/chatkit/getting_started/swift).

Check out the [start](https://github.com/pusher/chatkit-getting-started-swift/tree/start) branch so you can follow the getting start guide and add the code yourself!

## Requirements

Recent versions of:

- Xcode
- Cocoapods
- Node.JS

## Contents

- `app` - the Xcode project with the sample app
- `server` - the corresponding server scripts

## Running and usage

- Create a Pusher Chatkit instance at (dash.pusher.com/chatkit)[https://dash.pusher.com/chatkit]
- In the `server` directory run add your Chatkit instance credentials into `chatkit.js`, then run `npm install`, and finally `npm run create-environment`
- In the `app/Chatkit Quickstart/` directory in the iOS project populate the file `Chatkit.plist` with your Chatkit instance locator and test token provider endpoint.
- In the `app` directory run `pod install`
- Open the generated `XCWorkspace` file and run the project.

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
❯ sh -c "$(curl -fsSL https://raw.githubusercontent.com/pusher/chatkit-quickstart-swift/master/chatkit-quickstart-install.sh)" YOUR_INSTANCE_LOCATOR
```
