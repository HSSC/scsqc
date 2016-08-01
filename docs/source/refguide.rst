Reference Guide
===============

``scsqc`` Command
-----------------

.. _usage:

Usage
~~~~~

:command:`scsqc [OPTIONS]`

.. _options:

Options
~~~~~~~

.. program: virtualenv

.. option:: -h, --help

   show this help message and exit

.. option:: -c, --config CONF

   Path to configuration file

.. option:: -l LEVEL
  
   Log level for debugging. LEVEL can be one of the following

   DEBUG, INFO, WARNING, ERROR, CRITICAL, VERBOSE

.. option:: -s, --show

   Show current configuration

.. _Distribute: https://pypi.python.org/pypi/distribute
.. _Setuptools: https://pypi.python.org/pypi/setuptools


Configuration
-------------

Environment Variables
~~~~~~~~~~~~~~~~~~~~~
There are no special environment variables to be set. However, the
environment variable TNS_ADMIN is set by the application for accessing
the ``tnsnames.ora``  and ``sqlnet.ora`` configuration. It points to the
full path to the directory where these files reside. The location can be specified
with the parameter `tns_env` variable and defaults to ``/usr/local/share/qcmetrix``

.. envvar:: TNS_ADMIN

Configuration Variables
~~~~~~~~~~~~~~~~~~~~~~~
The configuration file has the following sections - **DEFAULT**, **DB**, **PAYLOAD**, **SFTP**, **QCMR**. The first
one has generic parameters which are used throughout the configuration. The rest are specific
to the database connection settings, the payload extraction and serialize settings and the
those specific to payload/response transfer to/from the sFTP server and processing payload response.

.. note::

 Refer the configuration file for detailed description of the parameters and their meaning.
 A brief summary of the parameters are shown in the table below

Brief Summary
~~~~~~~~~~~~~

 * ``DEFAULT`` Section

 +--------------------------+------------------------------+------------------------------------------------+
 | **Parameter**            |  **Default Value**           |   **Brief Description**                        |
 +--------------------------+------------------------------+------------------------------------------------+
 | log_path                 | **/var/log/scsqc/scsqc.log** |   Full path to log file                        |
 +--------------------------+------------------------------+------------------------------------------------+
 | temp_path                | **/tmp**                     |   Path to temp directory                       |
 +--------------------------+------------------------------+------------------------------------------------+
 | base_path                | **/usr/local/etc/qcmetrix**  |   Path to Oracle specific connection settings  |
 +--------------------------+------------------------------+------------------------------------------------+
 | user                     | **scsqc**                    |   Default user                                 |
 +--------------------------+------------------------------+------------------------------------------------+
 | home_path                | **/home/${user}**            |   User's home directory                        |
 +--------------------------+------------------------------+------------------------------------------------+
 | site_id                  | **1002**                     |   SQC Participating site ID                    |
 +--------------------------+------------------------------+------------------------------------------------+

 * ``DB`` Section

 +--------------------------+------------------------------+------------------------------------------------+
 | **Parameter**            |  **Default Value**           |   **Brief Description**                        |
 +--------------------------+------------------------------+------------------------------------------------+
 | tns_env                  | **${base_path}**             |    Path for **TNS_ADMIN** environment variable |
 +--------------------------+------------------------------+------------------------------------------------+
 | app                      | **/@myserv**                 |    Connection string for accessing database    |
 +--------------------------+------------------------------+------------------------------------------------+

 * ``PAYLOAD`` Section

 +--------------------------+------------------------------+------------------------------------------------+
 | **Parameter**            |  **Default Value**           |   **Brief Description**                        |
 +--------------------------+------------------------------+------------------------------------------------+
 | qcm_header_path          | **Omitted in doc**           |   QCMetrix header file defines the payload     |
 +--------------------------+------------------------------+------------------------------------------------+
 | batch_maxnum             | **20**                       |   Max no. of batches to process per extract    |
 +--------------------------+------------------------------+------------------------------------------------+
 | ndays_max_txstart        | **120**                      |   Max past days to extract surgical procedures |
 +--------------------------+------------------------------+------------------------------------------------+
 | csv_local_path           | **${temp_path}**             |   CSV payload file staging path                |
 +--------------------------+------------------------------+------------------------------------------------+
 | batch_size               | **500**                      |   Max no. of records to process per batch      |
 +--------------------------+------------------------------+------------------------------------------------+
 | ndays_txstart            | **2**                        |   Previous default transaction date            |
 +--------------------------+------------------------------+------------------------------------------------+
 | csv_file_prefix          | **qcm_**                     |   Prefix for CSV payload file                  |
 +--------------------------+------------------------------+------------------------------------------------+

 * ``FTP`` Section

 +--------------------------+------------------------------+------------------------------------------------+
 | **Parameter**            |  **Default Value**           | **Brief Description**                          |
 +--------------------------+------------------------------+------------------------------------------------+
 | remotedirs               | **Omitted in doc**           | Path(s) for sending payload on remote sFTP     |
 +--------------------------+------------------------------+------------------------------------------------+
 | host                     | **Omitted in doc**           | sFTP host used for payload/response exchange   |
 +--------------------------+------------------------------+------------------------------------------------+
 | port                     | **Omitted in doc**           | port that sFTP server is listening on          |
 +--------------------------+------------------------------+------------------------------------------------+
 | pubkey                   | **Omitted in doc**           | Public key to access the remote sFTP server    |
 +--------------------------+------------------------------+------------------------------------------------+


 * ``QCMR`` Section

 +--------------------------+------------------------------+------------------------------------------------+
 | **Parameter**            |  **Default Value**           | **Brief Description**                          |
 +--------------------------+------------------------------+------------------------------------------------+
 | proc_days                | **10**                       | Process all responses going back this days     |
 +--------------------------+------------------------------+------------------------------------------------+
 | response_dir             | **Omitted in doc**           | Path to response files to process              |
 +--------------------------+------------------------------+------------------------------------------------+
 | file_ext                 | **xml**                      | Response file extension                        |
 +--------------------------+------------------------------+------------------------------------------------+

