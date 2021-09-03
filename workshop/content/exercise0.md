# Introduction

Welcome to the Containerizing Applications lab! During this 0th lab you will
perform a simple configuration step.

Expected completion: 2 minutes

## Terminal
There is a terminal window to the right of the lab steps. You will type all of
your commands there unless asked to visit another website (for example, the
OpenShift web console).
## Set up environment variables
We have included a script for you that will set up some environment variables.
Please execute the following:

```bash
$ bash ~/support/lab0/setup/configure-lab.sh
```

That was easy!

## SSH into your lab system
You have a RHEL-based virtual machine that has been provisioned for you, and you
will perform all of your lab steps there. First, look at what your SSH password
for that system is:

```bash
$ echo $SSH_PASSWORD
```

You will need to use that password in the next step. For many operating systems
and browsers, you can highlight the password with your mouse, right click and
`Copy`, then use Control+Shift+V to paste.

Now, SSH into your lab system:

```bash
$ ssh lab-user@$SSH_HOST
```

Be sure to accept the fingerprint/connection, and then use the password above.
When logged in successfully, you will see that your prompt has changed to
something like:

```
[lab-user@studentvm 0 ~]$
```

## tmux and screen
If you are comfortable using `tmux` or `screen`, you may wish to do so, as some
of the lab steps take a while. However, it is unlikely that the remote terminal
you are using in this lab guide will disconnect from the remote lab VM. It's up
to you!

## Clone the lab content repository
You will need to clone the lab content repository into the VM:

```bash
$ git clone https://github.com/OpenShiftDemos/containerizing-apps-2021 containerizing-apps
```