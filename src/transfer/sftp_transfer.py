import paramiko
import sys
import os


def sftp_connect(host, port, user, keyfile=None):
    sftp_handle = None
    transport = None
    try:
        transport = paramiko.Transport( (host, int(port)) )
        if not keyfile == None:
            if not os.path.exists(keyfile):
                sys.stderr.write('ERROR: No such file/directory %s' % keyfile)
                return sftp_handle, transport
            encrkey = paramiko.RSAKey.from_private_key_file(keyfile)
            transport.connect(username=user, pkey=encrkey)
            sftp_handle = paramiko.SFTPClient.from_transport(transport)
    except Exception, err_msg:
        sys.stderr.write('EXCEPTION: %s' % err_msg)

    return sftp_handle, transport


def sftp_mkdir_p(sftp_handle, remote_directory):
    dir_path = str()
    for dir_folder in remote_directory.split("/"):
        if dir_folder == "":
            continue
        dir_path += r"/{0}".format(dir_folder)
        try:
            sftp_handle.listdir(dir_path)
        except IOError:
            try:
                sftp_handle.mkdir(dir_path)
            except Exception, msg:
                sys.stderr.write('EXCEPTION: %s' % msg)
                raise


def sftp_progress(bytes_done, bytes_todo):
    sys.stderr.write('\r')
    sys.stderr.write( 'transferred {0} bytes out of {1} '.format(bytes_done, bytes_todo))
    sys.stderr.flush()


def sftp_put(sftp_handle, local_path, remote_path, create_remote=True):

    if create_remote:
        dest_dir = os.path.dirname(remote_path)
        sftp_mkdir_p(sftp_handle, dest_dir)
    else:
        d_stat = sftp_handle.lstat(remote_path)
    sftp_handle.put(local_path, remote_path)


def sftp_get(sftp_handle, remote_path, local_path, create_local=False):

    if create_local:
        local_dir = os.path.dirname(local_path)
        sftp_mkdir_p(sftp_handle, local_dir)

    sftp_handle.get(remote_path, local_path) ## /*, callback=sftp_progress*/)
