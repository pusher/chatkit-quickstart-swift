# chatkit-quickstart-swift

App which accompanies the Chatkit Swift Quickstart, accessible for all new
instances created on the [Chatkit Dashboard](https://dash.pusher.com/chatkit).

This application demonstrates how to connect to the Chatkit service, as well
as a demonstration of tracking both received and pending messages which can
be used as a base to extend in to a more fully featured application or as a
reference during integration.

## Requirements

Recent versions of:

- Xcode
- Cocoapods

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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/pusher/chatkit-quickstart-swift/master/chatkit-quickstart-install.sh)" YOUR_INSTANCE_LOCATOR
```
