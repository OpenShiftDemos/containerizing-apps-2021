# Introduction

Welcome to the Containerizing Applications lab! During this 0th lab you will
perform a simple configuration step.

Expected completion: 2 minutes

## Terminal
There is a terminal window to the right of the lab steps. You will type all of
your commands there unless asked to visit another website (for example, the
OpenShift web console).

## Copy & Paste
You will frequently see commands in a block like the following:

```bash
$ echo 'hello, world!'
```

If you wish to copy paste, you'll need to:

1. highlight the text with your mouse
1. right-click and select `Copy`
1. left-click in the terminal
1. use `Control-Shift-V` or `Command-Shift-V`
1. then hit `Enter`

Try it with the `echo` command above!

## Set up environment variables
We have included a script for you that will set up some environment variables.
Please execute the following:

```bash
$ bash ~/support/lab0/setup/configure-lab.sh
$ source ~/envfile
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

Great - you're in! 

**WARNING**

**MAKE SURE TO EXIT** for one more thing, and then you'll go right back.

```
[lab-user@studentvm 0 ~]$ exit
```

## Copy environment files to your lab system
The above steps created an `envfile` that has important variables for your lab.
However, as you'll be performing many of the steps inside the remote lab
environment (remote to your lab terminal), you'll need to send those environment
variables over there.

```bash
$ scp ~/envfile lab-user@$SSH_HOST:
```

You'll need to use the same password as before.

OK, now you're ready to do your labs. Go ahead and SSH back into the lab system:

```bash
$ ssh lab-user@$SSH_HOST
```

**_NOTE_:** If you want to generate an SSH key and copy it to the lab system to
avoid using a password, that will work just fine.

## tmux and screen
If you are comfortable using `tmux` or `screen`, you may wish to do so, as some
of the lab steps take a while. However, it is unlikely that the remote terminal
you are using in this lab guide will disconnect from the remote lab VM. It's up
to you!

## Clone the lab content repository
Make sure you are logged into the lab VM, and then you will need to clone the
lab content repository:

```bash
$ git clone https://github.com/OpenShiftDemos/containerizing-apps-2021 containerizing-apps
```