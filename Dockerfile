FROM fedora:28

# The rsync contents should be copied to the image/ folder where this Dockerfile resides
COPY backup/ /

# Enable systemd in the container, and change permissions:
RUN chown -R bitcoin.bitcoin /home/bitcoin && (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \ 
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;\
rm /lib/systemd/system/swap.target;\
rm /etc/fstab;

VOLUME [ "/sys/fs/cgroup" ] 

CMD ["/usr/sbin/init"]


EXPOSE 8333 8332
