# How do I use some of these scripts?

Table of Contents

* [man2pdf](#man2pdf)
* [clusterssh helper scripts](#clusterssh-helper-scripts)
* [wasted-ram-updates.py](#wasted-ram-updatespy)
* [Mass GPG encrypted file management](#mass-gpg-encrypted-file-management)

----
## man2pdf

[man2pdf](man2pdf) is a simple script which converts man pages to PDF format.
This is useful for reading man pages on the go in an e-book reader.  The
permissions of the script should be 755.

Example, converting the bash man page into PDF.

    chmod 755 man2pdf
    ./man2pdf bash

----
## clusterssh helper scripts

I use the following helper scripts to maintain the `/etc/clusters` file:

* `knownhosts.sh`
* `missing_from_all_clusters.sh`
* `servercount`
* `sort_clusters`

I maintain my `/etc/clusters` file with a standardized naming convention.  The
first line has an `All_clusters` alias.  Its only purpose is to be an alias for
all aliases in the `/etc/clusters` file.  From there every alias starts with one
of two standardized prefixes: `cluster_` or `host_`.

Here is a sample `/etc/clusters` file using that naming convention.

    All_clusters cluster_website cluster_dns host_Config_management

    cluster_website host1.domain.com host2.domain.com host3.domain.com

    cluster_dns ns1.domain.com ns2.domain.com

    host_Config_management someconfigmanagement.domain.com

`knownhosts.sh` - This script reads stdin a list of host names, queries the ssh
fingerprint, and checks to see if that known host exists in
`~/.ssh/known_hosts`.  If it exists then it outputs nothing.  If there's any
missing (or possibly incorrect) then it will output only the problem hosts.  If
no hosts have any problems then it exits with a proper success exit code.  This
can be used with `servercount`.

`missing_from_all_clusters.sh` - This goes through the `/etc/clusters` file for
all of the aliases and checks to make sure that all aliases are added to
`All_clusters`.  If there is no alias then it will output the problem entry.
There will be no output if all entries are properly accounted for.

`servercount` - This goes through the `/etc/clusters` file and displays a list
of host names only (with no aliases).  This will consist of one host per line.

`sort_clusters` - As you keep adding aliases to `/etc/clusters` there becomes a
need to alphabetically sort the aliases in the file.  This will sort the
aliases.  It also sorts the list of aliases on the `All_clusters` line at the
top of the file.

### Example usage

Get a head count of the number of servers in the clusters file.

    servercount | wc -l

Check that there aren't any bad `known_hosts` fingerprints for clusters host
names.

    servercount | knownhosts.sh

Generage a list of ip addresses associated with all of the hosts.

    servercount | while read server;do dig +short ${server};done
    servercount | while read server;do echo "$(dig +short ${server}) ${server}";done

The remaining scripts are fairly standalone.

----
## wasted-ram-updates.py

Ever hear about Linux being able to update without ever needing to be restarted
(with exception for a few critical packages)?  Ever wonder how to figure out
which services need to actually be restarted after a large update of hundreds of
packages?  With `wasted-ram-updates.py` you no longer need to wonder.

`wasted-ram-updates.py` helps to resolve these questions by showing which
running processes are using files in memory that have been deleted on disk.
This lets you know that there is likely an outdated library being used.  If you
restart the daemon associated with this process then it will use the updated
copy of the library.

### List of packages which require a restart

Over time I've encountered a small list of critical packages which require a
restart of the Linux OS.  Here's a non-comprehensive list of which I'm aware.
Feel free to open an [issue](https://github.com/sag47/drexel-university/issues)
letting me know of another package which requires a system reboot.

* dbus (used by `/sbin/init` which is pid 1)
* glibc
* kernel

Other than that you should be able to simply restart the associated service.

_Please note: some programs regularly create and delete temporary files which
will show up in `wasted-ram-updates.py`.  This is normal and does not require a
service restart for this case._

### Example usage

Just display an overall summary

    wasted-ram-updates.py summary

Organize the output by deleted file handle (I've found this to be less useful
for accomplishing a system update).

    wasted-ram-updates.py

Organize the output by process ID and show a heirarchy of deleted file handles
as children to the PIDs.  This is the most useful command for determining which
services to restart.

    wasted-ram-updates.py pids

----
## Mass GPG encrypted file management

These scripts assume a basic knowledge and usage of GPG.  These scripts automate
encrypting files.

I've written a set of scripts for massively managing gpg encrypted files.  In a
nutshell, these scripts will encrypt all files in a directory using GPG.  It
will encrypt individual files (e.g. two individual files result in two encrypted
files).  These scripts were written as a solution to store encrypted files in
Dropbox.

_Please note that these scripts only preserve confidentiality of contents of
files.  The file names will have a similar name as when they were unencrypted so
that files can be easily searched using an indexer._


##### Encryption related scripts

* `gpg_encrypt_individual_files.sh` - encrypts all unencrypted files
  individually.  Generates a `sha1sum.txt` file in each directory which is the
  checksum of encrypted files in said directory.
* `gpg_decrypt_individual_files.sh` - decrypts all individually encrypted files.
* `gpg_sign_sha1sums.sh` - Digitally sign all sha1sum.txt files.  Because the
  contents of the sha1sum.txt file is the hash of all encrypted files this
  essentially guaruntees the signature of every file.

##### Validation and verification related scripts

* `gpg_validate_sha1sums.sh` - validates all `sha1sum.txt.sig` signatures.  If
  the contents of any `sha1sum.txt` file has changed then signature validation
  will fail.  Failure means maliciously modified or corrupted `sha1sum.txt`
  file.
* `gpg_verify_checksums.sh` - Runs a checksum verification of all encrypted
  files using the `sha1sum.txt` file as a checksum reference.  If the contents
  of any encrypted file has changed then checksum verification will fail.
  Failure means maliciously modified or corrupted encrypted files.
* `gpg_fix_missing_sha1sums.sh` - Removes missing files from all `sha1sum.txt`
  files and adds missing encrypted files from `sha1sum.txt` files.  This is for
  renaming and moving files without decrypting them.

### Example usage

Encrypt all files in the current directory and sign the resulting `sha1sum.txt`
files.

    gpg_encrypt_individual_files.sh ./
    gpg_sign_sha1sums.sh ./

Rename an encrypted file and update the checksums and signature of the
`sha1sum.txt` file.

    mv oldname.txt.gpg newname.txt.gpg
    gpg_fix_missing_sha1sums.sh ./

Validate and verify all encrypted files.

    gpg_validate_sha1sums.sh ./
    gpg_verify_checksums.sh ./
