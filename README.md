# chatkit-getting-started-swift

The starter project to accompany

- The Chatkit Swift Quickstart (accessible from the Chatkit Dashboard for your
  instance).
- [Chatkit Swift Getting Started
  Guide](https://pusher.com/docs/chatkit/getting_started/swift).

There are two branches in this repo. The first is,
[start](https://github.com/pusher/chatkit-getting-started-swift/tree/start),
which contains the outline of the project so you can follow the step by step
Getting Started Guide.

Check out the
[complete](https://github.com/pusher/chatkit-getting-started-swift/tree/complete)
branch if you want to see the completed project straight away. This is the
branch used by the Quickstart in the dashboard.

## Requirements

Recent versions of:

- Xcode
- Cocoapods
- Node.JS

## Contents

- `app` - the Xcode project with the sample app
- `server` - the corresponding server scripts

## Assets attribution

User avatar images used in the demo app are made by
[Freepik](https://www.freepik.com/home) from www.flaticon.com

## Install script for quick start within dashboard

Within the dashboard we have a quickstart which uses this repo. The shell
script is used to get people running quickly.

It does the following:

- clones the repo
- installs the dependencies with Cocoapods
- Injects the credentials, which are passed as an argument

It can be run like this:

```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/pusher/chatkit-quickstart-swift/complete/chatkit-quickstart-install.sh)" YOUR_INSTANCE_LOCATOR
```
