Production Deployment 
=====================

Testing for development
~~~~~~~~~~~~~~~~~~~~~~~

.. note:: 

 Oracle Enterprise Linux OS (version 6.8) is the default operating system in production
 that is currently supported by Clemson CCIT (07/18/2016)

The source code repository has a configuration file to test full scale deployment of
the entire end-to-end operation of connecting to the database server, 
extracting the payload and transfer of it to the SFTP server. 

The end-to-end tests can be kicked off from a laptop running Linux.
It has been tested to successfully deploy in the following linux environments 

 * Oracle Enterprise Linux 6.7, 6.8, 7.0) 
 * Ubuntu (Precise Pangolin, Trusty Tahr, Wily Warewolf, Xenial Xerus)

Dependencies
------------
The following are the dependencies for development and running the end-to-end tests

 * Python 2.7 development environment
 * `Virtualbox <https://www.virtualbox.org/wiki/Downloads>`_
 * `Vagrant <https://www.vagrantup.com/downloads.html>`_
 * `Ansible <http://docs.ansible.com/ansible/intro_installation.html#getting-ansible>`_

Check out the code from the repository. By default you will be using the development
branch - which is also the preferred approach. Clone the `development branch <https://github.com/HSSC/scsqc>`_
and add it as `upstream master <https://help.github.com/articles/configuring-a-remote-for-a-fork/>`_.

Additional files
----------------
For security pruposes and removing the overhead of storing Oracle
development RPM's these files are not in the repository. One needs
to obtain them for development purposes. 

  * :ref:`Oracle client RPM's <oracle-client-libs>`
  * :ref:`Client-side Wallet Files <client-side-wallet>`
  * :ref:`SFTP Server Public Key <sftp-server-key>`

Once you have the files/directories needed, copy them over to the following
location:
  
.. code-block:: bash
 
  roles/pyenv/files/

.. note::
  There are place holders (empty files) that indicate the Oracle client RPM's, the Client-side wallet folder and the SFTP public key.
  You will basically be overwriting them with the ones you obtain. 

Unit/Functional Tests
---------------------
To perform unit and functional tests, use the following command

.. code-block:: bash
 
  make prepare
  make pytest-unit
 
Integration Test
----------------
To perform end-to-end testing, use the following command

.. code-block:: bash
 
  make prepare
  make vagrant-test
  
Demonstration 
-------------
A screen capture of the terminal session of the full end-to-end test

.. image:: _static/capture.gif



Testing for Production
~~~~~~~~~~~~~~~~~~~~~~~
