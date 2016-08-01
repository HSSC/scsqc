Installation
============

Environment
***********

Oracle Enterprise Linux OS (>= 6.8) is the default operating system in production.

Application requires the following minimal prerequisites
  1. Virtual environment (Python >= 2.7)
  2. Database API (cx_Oracle >= 5.1) 
  3. Oracle client libraries (instantclient -basic, -devel and -sqlplus, each >= 12.1)
  4. Git client (for checking out the application code from repository)

***********

Source Code
***********

``scsqc`` source code is available in `HSSC/scsqc <https://github.com/HSSC/scsqc/>`_ repository.
   * For *production*, check out the latest ``stable`` release from github. 
   * For *development* use the latest ``dev`` branch.

.. note::
 Due to protected nature of data it serves (*i.e.,* PHI), ``scsqc`` is **not** available on Pypi.

***********

Application Server Setup
************************

Prerequisites
-------------

In production, it is best to setup the application to run in a virtual environment.
Using a virtual environment helps avoid clutter in our system-wide libraries which 
have Python 2.6 on OEL 6.8 operating system. Install Git_ in order to clone the repository.
Obtain Git_, Python_ and virtualenv_ if you do not already have them. 


.. note::
 You have to do this (and once only) if you are:
  * setting up a new production app server     *OR* 

  * upgrading the prerequisite packages     *OR*

  * upgrading the operating system

.. warning::

 Some of the steps below require root access. Ask Clemson IT support to set it up for you
 or request admin access to app server if you want to do it yourself.
 Install **Python version >= 2.7** (if your OS does not already ship with it)

.. _Python: http://www.python.org/
.. _virtualenv: http://pypi.python.org/pypi/virtualenv
.. _Git: http://git-scm.com/


.. _oracle-client-libs:

Oracle client libraries
-----------------------
Install the Oracle client libraries. You have to copy
the RPM's from the Oracle Support Network `website <http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html>`_ by accepting their
license agreement, downloading the RPM's locally and copying them over to the application server in production. 

.. code-block:: bash
    
    sudo su -
    rpm -ivh oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm
    rpm -ivh oracle-instantclient12.1-sqlplus-12.1.0.2.0-1.x86_64.rpm
    rpm -ivh oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm

Create user/group
-----------------
Create a user:group `scsqc:scsqc` with a home directory and login shell

.. code-block:: bash

    sudo su -
    useradd -m -d /home/scsqc -s /bin/bash -c "creating user scsqc" -U scsqc
    usermod -G scsqc scsqc


Virtual environment
-------------------
Create a virtual environment `sqcenv` and activate it

.. code-block:: bash

    sudo su -
    cd /home/scsqc
    pip2.7 install virtualenv
    virtualenv -p /usr/bin/python2.7 sqcenv
    source /home/scsqc/sqcenv/bin/activate
    pip install -r /home/scsqc/prod.requirements.txt


.. _client-side-wallet:

Client-side wallet
------------------

Ask the DBA to setup a `client-side Oracle Wallet <https://docs.oracle.com/cd/B28359_01/network.111/b28530/asowalet.htm#i1011255>`_. 
This requires creating a wallet (using Oracle Wallet Manager), 
setting up the wallet files, setting file/directory permissions, the 
local naming parameters (tnsnames.ora) and profile configuration
file (sqlnet.ora). This is required for application to be able to
communicate with the Oracle database. If setup properly, the Oracle API (cx_Oracle) will be
able to establish a connection using a service name (string). 

.. code-block:: bash

    -rw-r--r--. 1 scsqc scsqc  /usr/local/share/qcmetrix/sqlnet.ora
    -rw-r--r--. 1 scsqc scsqc  /usr/local/share/qcmetrix/tnsnames.ora

    -rw-------. 1 scsqc scsqc  /usr/local/share/qcmetrix/scsqc.wxt/cwallet.sso
    -rw-r--r--. 1 scsqc scsqc  /usr/local/share/qcmetrix/scsqc.wxt/cwallet.sso.lck
    -rw-------. 1 scsqc scsqc  /usr/local/share/qcmetrix/scsqc.wxt/ewallet.p12
    -rw-r--r--. 1 scsqc scsqc  /usr/local/share/qcmetrix/scsqc.wxt/ewallet.p12.lck


.. _sftp-server-key:

SFTP server public key
----------------------
Public key of the sFTP server must be installed on the app server in the home directory with proper permissions.
This allows the application to communicate with the sFTP host.

.. code-block:: bash

    -r--------. 1 scsqc scsqc /path/to/sftp/public.key


Install ``scsqc``
-----------------

To setup a stable release of scsqc, do the following

.. code-block:: bash

    ## Get and unpack a stable release
    sudo su -
    cd /home/scsqc
    tar -zxf scsqc-<version>.tar.gz
    cd scsqc

    ## Run tests
    nosetests  

    ## Build, test and install
    python setup.py build
    python setup.py test
    python setup.py install

.. warning::

 If the nosetests fail, the application will fail to run. Fix problems with the environment and re-run the tests.
 Make sure all the tests pass before installing.

Configure ``scsqc``
-------------------
Application configuration is installed in a default location.
Reasonable values are provided for the parameters. Modify as
required. 

.. code-block:: bash

    -rw-r--r--. 1 scsqc scsqc /usr/local/etc/qcmetrix/qcmetrix.conf
