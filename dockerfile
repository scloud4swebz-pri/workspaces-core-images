ARG BASE_IMAGE="ubuntu:18.04"
FROM $BASE_IMAGE AS install_tools
ARG DISTRO=ubuntu

LABEL "com.kasmweb.image"="true"

### Install common tools
COPY ./src/ubuntu/install/tools $INST_SCRIPTS/tools/
RUN bash $INST_SCRIPTS/tools/install_tools.sh && rm -rf $INST_SCRIPTS/tools/

### Environment config
ARG START_XFCE4=0
ARG START_PULSEAUDIO=0
ARG BG_IMG=bg_kasm.png
ARG EXTRA_SH=noop.sh
ARG DISTRO=ubuntu
ARG LANG='en_US.UTF-8'
ARG LANGUAGE='en_US:en'
ARG LC_ALL='en_US.UTF-8'
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_PORT=5901 \
    AUDIO_PORT=4901 \
    VNC_RESOLUTION=1280x720 \
    MAX_FRAME_RATE=24 \
    VNCOPTIONS="-PreferBandwidth -DynamicQualityMin=4 -DynamicQualityMax=7 -DLP_ClipDelay=0" \
    HOME=/home/kasm-default-profile \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/dockerstartup/install \
    KASM_VNC_PATH=/usr/share/kasmvnc \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY_PW=vncviewonlypassword \
    LD_LIBRARY_PATH=/opt/libjpeg-turbo/lib64/:/usr/local/lib/ \
    OMP_WAIT_POLICY=PASSIVE \
    SHELL=/bin/bash \
    START_XFCE4=$START_XFCE4 \
    START_PULSEAUDIO=$START_PULSEAUDIO \
    LANG=$LANG \
    LANGUAGE=$LANGUAGE \
    LC_ALL=$LC_ALL

EXPOSE $VNC_PORT \
       $NO_VNC_PORT \
       $UPLOAD_PORT \
       $AUDIO_PORT

WORKDIR $HOME
RUN mkdir -p $HOME/Desktop


### Install custom fonts
COPY ./src/ubuntu/install/fonts $INST_SCRIPTS/fonts/
RUN bash $INST_SCRIPTS/fonts/install_custom_fonts.sh && rm -rf $INST_SCRIPTS/fonts/

### Install xfce UI
COPY ./src/ubuntu/install/xfce $INST_SCRIPTS/xfce/
RUN bash $INST_SCRIPTS/xfce/install_xfce_ui.sh && rm -rf $INST_SCRIPTS/xfce/
ADD ./src/$DISTRO/xfce/.config/ $HOME/.config/
RUN mkdir -p /usr/share/extra/backgrounds/
RUN mkdir -p /usr/share/extra/icons/
ADD /src/common/resources/images/bg_kasm.png  /usr/share/extra/backgrounds/bg_kasm.png
ADD /src/common/resources/images/$BG_IMG  /usr/share/extra/backgrounds/bg_default.png
ADD /src/common/resources/images/icon_ubuntu.png /usr/share/extra/icons/icon_ubuntu.png
ADD /src/common/resources/images/icon_ubuntu.png /usr/share/extra/icons/icon_default.png
ADD /src/common/resources/images/icon_kasm.png /usr/share/extra/icons/icon_kasm.png

ADD ./src/common/xfce/window_manager_startup.sh $STARTUPDIR

### Install kasm_vnc dependencies and binaries
COPY ./src/ubuntu/install/kasm_vnc $INST_SCRIPTS/kasm_vnc/
RUN bash $INST_SCRIPTS/kasm_vnc/install_kasm_vnc.sh && rm -rf $INST_SCRIPTS/kasm_vnc/

### Install Kasm Upload Server
COPY ./src/ubuntu/install/kasm_upload_server $INST_SCRIPTS/kasm_upload_server/
RUN bash $INST_SCRIPTS/kasm_upload_server/install_kasm_upload_server.sh  && rm -rf $INST_SCRIPTS/kasm_upload_server/


### Install Audio
COPY ./src/ubuntu/install/audio $INST_SCRIPTS/audio/
RUN bash $INST_SCRIPTS/audio/install_audio.sh  && rm -rf $INST_SCRIPTS/audio/

### Install Audio Input
COPY ./src/ubuntu/install/audio_input $INST_SCRIPTS/audio_input/
RUN bash $INST_SCRIPTS/audio_input/install_audio_input.sh && rm -rf $INST_SCRIPTS/audio_input/

### Install custom cursors
COPY ./src/ubuntu/install/cursors $INST_SCRIPTS/cursors/
RUN bash $INST_SCRIPTS/cursors/install_cursors.sh && rm -rf $INST_SCRIPTS/cursors/

### Install Squid
COPY ./src/ubuntu/install/squid/install/ $INST_SCRIPTS/squid_install/
RUN bash $INST_SCRIPTS/squid_install/install_squid.sh && rm -rf $INST_SCRIPTS/squid_install/
COPY ./src/ubuntu/install/squid/resources/*.conf /etc/squid/
COPY ./src/ubuntu/install/squid/resources/start_squid.sh /etc/squid/start_squid.sh
COPY ./src/ubuntu/install/squid/resources/SN.png /usr/local/squid/share/icons/SN.png
RUN chown proxy:proxy /usr/local/squid/share/icons/SN.png
COPY ./src/ubuntu/install/squid/resources/error_message/access_denied.html /usr/local/squid/share/errors/en/ERR_ACCESS_DENIED
RUN chown proxy:proxy /usr/local/squid/share/errors/en/ERR_ACCESS_DENIED
RUN rm -rf $INST_SCRIPTS/resources/

RUN chmod +x /etc/squid/kasm_squid_adapter
RUN chmod +x /etc/squid/start_squid.sh && chmod 4755 /etc/squid/start_squid.sh

### Setup Container User - Libnss Wrapper
COPY ./src/ubuntu/install/libnss $INST_SCRIPTS/libnss/
RUN bash $INST_SCRIPTS/libnss/libnss_wrapper.sh  && rm -rf $INST_SCRIPTS/libnss/

### configure startup
COPY ./src/common/scripts/kasm_hook_scripts $STARTUPDIR
ADD ./src/common/startup_scripts $STARTUPDIR
RUN bash $STARTUPDIR/set_user_permission.sh $STARTUPDIR $HOME


### extra configurations needed per distro variant
COPY ./src/ubuntu/install/extra $INST_SCRIPTS/extra/
RUN bash $INST_SCRIPTS/extra/$EXTRA_SH  && rm -rf $INST_SCRIPTS/extra/

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

### FIX PERMISSIONS ## Objective is to change the owner of non-home paths to root, remove write permissions, and set execute where required
# these files are created on container first exec, by the default user, so we have to create them since default will not have write perm
RUN touch $STARTUPDIR/wm.log \
    && touch $STARTUPDIR/window_manager_startup.log \
    && touch $STARTUPDIR/vnc_startup.log \
    && touch $STARTUPDIR/no_vnc_startup.log \
    && chown -R root:root $STARTUPDIR \
    && find $STARTUPDIR -type d -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -exec chmod 644 {} \; \
    && find $STARTUPDIR -type f -iname "*.sh" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.py" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.rb" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.pl" -exec chmod 755 {} \; \
    && find $STARTUPDIR -type f -iname "*.log" -exec chmod 666 {} \; \
    && chmod 755 $STARTUPDIR/upload_server/kasm_upload_server \
    && chmod 755 $STARTUPDIR/audio_input/kasm_audio_input_server \
    && chmod 755 $STARTUPDIR/generate_container_user \
    && chmod +x $STARTUPDIR/jsmpeg/kasm_audio_out-linux \
    && rm -rf $STARTUPDIR/install \
    && mkdir -p $STARTUPDIR/kasmrx/Downloads \
    && chown 1000:1000 $STARTUPDIR/kasmrx/Downloads \
    && chown -R root:root /usr/local/bin

USER 1000

ENTRYPOINT ["/dockerstartup/kasm_default_profile.sh", "/dockerstartup/vnc_startup.sh", "/dockerstartup/kasm_startup.sh"]
CMD ["--wait"]
