ARG DEEPSTREAM_VERSION=6.0.1
FROM nvcr.io/nvidia/deepstream:${DEEPSTREAM_VERSION}-triton

MAINTAINER Xiangyang Kan <xiangyangkan@outlook.com>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PYTHON_VERSION=3.8

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# change timezone
ARG TZ="Asia/Shanghai"
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo ${TZ} > /etc/timezone


# install conda
ENV CONDA_DIR=/opt/conda
ENV PATH="${CONDA_DIR}/bin:${PATH}"
# ARG CONDA_MIRROR=https://github.com/conda-forge/miniforge/releases/latest/download
ARG CONDA_MIRROR=https://repo.anaconda.com/miniconda
# Specify Python 3.8 Version
ARG CONDA_VERSION=4.12.0
RUN set -x && \
    # Miniforge installer
    miniforge_arch=$(uname -m) && \
    # miniforge_installer="Mambaforge-Linux-${miniforge_arch}.sh" && \
    miniforge_installer="Miniconda3-py38_${CONDA_VERSION}-Linux-${miniforge_arch}.sh" && \
    wget --quiet "${CONDA_MIRROR}/${miniforge_installer}" && \
    /bin/bash "${miniforge_installer}" -f -b -p "${CONDA_DIR}" && \
    rm "${miniforge_installer}" && \
    # Conda configuration see https://conda.io/projects/conda/en/latest/configuration.html
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    # Using conda to update all packages: https://github.com/mamba-org/mamba/issues/1092
    conda update --all --quiet --yes && \
    conda install -y \
      numpy \
      conda-pack \
      jupyterlab \
      nodejs && \
    conda clean --all -f -y


# install gst-python and pyds
RUN sed -i "s/deb https\:\/\/developer/# deb https\:\/\/developer/g" /etc/apt/sources.list && \
    apt-get update --fix-missing && apt-get install --no-install-recommends --allow-unauthenticated -y \
      libpython${PYTHON_VERSION}-dev \
      python-gi-dev \
      libgirepository1.0-dev \
      libcairo2-dev \
      apt-transport-https \
      ca-certificates \
      ffmpeg  \
      && \
    update-ca-certificates && \
    cd samples && \
    git clone https://github.com/NVIDIA-AI-IOT/deepstream_python_apps.git && cd deepstream_python_apps && \
    git submodule update --init && cd 3rdparty/gst-python && \
    ./autogen.sh && make && make install && \
    cd ../../bindings && mkdir build && cd build && \
    cmake .. -DPYTHON_MAJOR_VERSION=3 -DPYTHON_MINOR_VERSION=8  \
      -DPIP_PLATFORM=linux_x86_64 -DS_PATH=/opt/nvidia/deepstream/deepstream && \
    make  && \
    pip3 install ./pyds-1.1.1-py3-none*.whl


# SSH config
RUN apt-get update --fix-missing && apt-get install --no-install-recommends --allow-unauthenticated -y \
    openssh-server pwgen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i "s/.*UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && \
    sed -i "s/.*UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && \
    sed -i "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config && \
    sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config
COPY set_root_pw.sh run_ssh.sh /
RUN chmod +x /*.sh && sed -i -e 's/\r$//' /*.sh
ENV AUTHORIZED_KEYS **None**
EXPOSE 22


# jupyter lab config
COPY jupyter_server_config.py /root/.jupyter/
COPY run_jupyter.sh /
RUN chmod +x /run_jupyter.sh && \
    pip install --no-cache-dir jupyter_http_over_ws && \
    jupyter serverextension enable --py jupyter_http_over_ws && \
    python -m ipykernel.kernelspec
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends --allow-unauthenticated npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    jupyter labextension install \
        @jupyter-widgets/jupyterlab-manager \
        @jupyterlab/hub-extension \
        jupyter-matplotlib \
        && \
    npm cache clean --force

# deal with vim and matplotlib Mojibake
COPY simhei.ttf /opt/conda/lib/python${PYTHON_VERSION}/site-packages/matplotlib/mpl-data/fonts/ttf/
RUN echo "set encoding=utf-8 nobomb" >> /etc/vim/vimrc && \
    echo "set termencoding=utf-8" >> /etc/vim/vimrc && \
    echo "set fileencodings=utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom" >> /etc/vim/vimrc && \
    echo "set fileformats=unix,dos,mac" >> /etc/vim/vimrc && \
    rm -rf /root/.cache/matplotlib

# supervisor config
RUN mkdir /var/run/sshd && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends --allow-unauthenticated supervisor
COPY supervisord.conf /

EXPOSE 8888

COPY bashrc /etc/bash.bashrc
RUN chmod a+rwx /etc/bash.bashrc
RUN env | egrep -v "^(LS_COLORS=|SSH_CONNECTION=|USER=|PWD=|HOME=|SSH_CLIENT=|SSH_TTY=|MAIL=|TERM=|SHELL=|SHLVL=|LOGNAME=|PS1=|_=)" > /etc/environment

ENTRYPOINT ["/usr/bin/supervisord", "-c"]

CMD ["/supervisord.conf"]