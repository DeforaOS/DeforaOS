DeforaOS Project
================

About DeforaOS
--------------

DeforaOS is an Operating System developed with new and innovative concepts in
its design and architecture. Its goal is to let users work securely yet
seamlessly across any number of devices. This means that the relevant data is
readily available, while the state of the applications remains consistent
regardless of the form factor, location, or connectivity.

This is achieved in a decentralized manner, without necessarily using shared
computing platforms from third parties (also known as "cloud").

Project structure
-----------------

The project is essentially divided into three main components:

1. Distributed framework

   Used for the communication between the different components of the system,
   locally as well as when accessing resources on remote devices.

2. Self-hosted environment

   Contains the components necessary to let the system build itself again.

3. Graphical interface

   Implements a featureful desktop environment, making full use of the
   underlying design and architecture.

Getting started
---------------

The current requirements to build and install DeforaOS are:

* POSIX-compliant Operating System (NetBSD, Linux, mac OS, other BSDs...)
* a working C compiler and assembler (GCC, LLVM...)
* Git, to download and synchronize the components as required

Run the following command to configure the sources for the project and compile
the essential tools to build it:

    $ make bootstrap

Once this done, run the following command to automatically download and build
its different components:

    $ make


Alternatively, a helper script is available, in order to build bootable images
of the Operating System:

    $ build.sh image

Contact information
-------------------

The project can be found and contacted at:

* Web:     https://www.defora.org/ or on [GitHub](https://github.com/DeforaOS)
* e-mail:  info@defora.org or via mailing-lists at https://lists.defora.org/
* IRC:     #DeforaOS on the [OFTC network](https://www.oftc.net/)
* Twitter: [@DeforaOS](https://twitter.com/DeforaOS)

Donations are accepted at the following address:

* Bitcoin: `1yKwy1JqXYkXX8WQtWQK4iHodXWiqWivD`

