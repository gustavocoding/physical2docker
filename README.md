## Dockerization of physical Fedora 28 servers 

Instructions to convert an existing physical Linux Fedora server to a docker container. Why? 
Useful to test an existing rsync backup and to actually replace a physical server in case 
of an emergency. This procedure enables ```systemd``` suport inside the docker image, so that
it can run multiple processes inside the container.

### Step 1: Full backup of existing server

Plug and mount external storage to the physical server with enough capacity to hold all non-free space of the server.

Run the following command as ```root``` to create a full copy of the filesystem:

```
rsync -aAXv --info=progress2 --delete / --exclude={"/dev/*","/proc/*","/sys/*","/run/*","/mnt/*","/media/*","/lost+found"} /mnt/external-backup
```

Where ```/mnt/external-backup``` is where the external disk is mounted.

The advantages of using rsync to do a full backup are plenty: 
* rsync preserves file permissions and symlinks
* rsync allows incremental backups
* rsync will just backup the used space instead of the full partition size like other methods of image creation like ```dd```
* There is no need that the system where the backup is restored have the same partition layout

### Step 2: Copy the backup to the destination

Plug and mount the external drive with the backup to another computer, and follow the steps:

```
git checkout gustavonalle/physical2docker && cd physical2docker
rsync -aAXv --info=progress2 /mnt/external-backup backup/
```

### Step 3: Create the image 

#### Check Docker version

Make sure to use a recent Docker version. Fedora 28 ships with an older version that has issues with privileged and systemd enabled
containers. Follow https://docs.docker.com/install/linux/docker-ce/fedora/ to install the latest stable version.

#### Check Docker disk space 

Before proceeding, check if docker has enough space to hold the image. It usually store images in ```/var/lib/docker/``` which 
usually resides in the ```/``` partition that will probably be small. If not enough space is available:

* Stop the docker service
* Move the contents of ```/var/lib/docker/``` to another partition
* Create a symlink to the new location: ```ln -s /path/to/new/docker/folder /var/lib/docker/```
* Start docker

#### (Optional) Adjust users and permissions

The ```Dockerfile``` assumes the backup contains a user called 'bitcoin' and changes the permission 
of its home folder. You may need to comment that line or add adjust it to your scenario.

#### (Optional) Ignore files or directories

Use the file ```.dockerignore``` to ignore folders/files from the backup when building the image. This is useful for large folders that are better suited to be attached as volumes to the container rather than be part of the image itself. Example, if your server includes a blockchain or a database with large quantities of data, this will bloat considerably the image and will require plenty of temporaty space to build the image.

#### Build the image

```
docker build -t image_name  .
```

### Final step 

Before running the container, disable SELinux. Make sure ```SELINUX=disabled``` is in ```/etc/selinux/config```, and reboot.

Note: It is possible to run a systemd enabled container with Selinux enabled; I prefer not to waste my time tinkering with it though.


Run the container:

```
docker run --name container-name --privileged --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /path/to/large_dir:/path/inside/container -td image_name
```

The last part ```-v /path/to/large_dir:/path/inside/container``` is optional, it's used when some of the backup files were ignored at build time, to be mounted later as a volume.

The container will run on the background, with support for systemd.

To attach to it, run:

```
docker exec -it --user bitcoin container-name zsh
```

Replace the user and the shell if necessary.



Presto! A container with an exact copy of the physical server. Although this procedure is for Fedora 28, it should work fine for 
other distros, provided the Dockerfile extends the same base image as before.

If this procedure help you, consider donating any amount to ```bc1qf5ndupggeqtpk5gf4leh4vcxecxakw067hel0z``` as a token of appreciation!

