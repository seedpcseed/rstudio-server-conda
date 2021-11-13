#!/bin/bash

# See also https://www.rocker-project.org/use/singularity/

# Main parameters for the script with default values
PORT=${PORT:-8787}
USER=$(whoami)
PASSWORD=${PASSWORD:-notsafe}
TMPDIR=${TMPDIR:-tmp}
CONTAINER="rstudio_latest.sif"  # path to singularity container (will be automatically downloaded)

# Set-up temporary paths
RSTUDIO_TMP="${TMPDIR}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
sudo mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio/data}

CONDA_PREFIX=$RSTUDIO_TMP/rstudioConda
sudo mkdir -p $CONDA_PREFIX

R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity build --fakeroot $CONTAINER Singularity
fi

if [ -z "$CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo "Starting rstudio service on port $PORT ..."
singularity run \
	--bind /mnt \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind database.conf:/etc/rstudio/database.conf \
	--bind rsession.conf:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
	--bind $RSTUDIO_TMP/local-share-rstudio/data:/data \
	--bind ${CONDA_PREFIX}:/rstudioConda \
	--env CONDA_PREFIX=$CONDA_PREFIX \
	--env RSTUDIO_WHICH_R=$R_BIN \
	--env RETICULATE_PYTHON=$PY_BIN \
	--env PASSWORD=$PASSWORD \
	--env PORT=$PORT \
	--env USER=$USER \
	rstudio_latest.sif \
	rserver \
	    --www-address=127.0.0.1 \
	    --www-port=$PORT \
	    --auth-timeout-minutes=0 --auth-stay-signed-in-days=30  \
	    --auth-none=0  --auth-pam-helper-path=pam-helper \
	    --server-user $USER

	# singularity -vv exec \
	# 	--bind /mnt:$HOME \
	# 	--bind $RSTUDIO_TMP/run:/run \
	# 	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	# 	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	# 	--bind database.conf:/etc/rstudio/database.conf \
	# 	--bind rsession.conf:/etc/rstudio/rsession.conf \
	# 	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	# 	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
	# 	--bind ${CONDA_PREFIX}:${CONDA_PREFIX} \
	#   --bind /data:/data \
	# 	--env CONDA_PREFIX=$CONDA_PREFIX \
	# 	--env RSTUDIO_WHICH_R=$R_BIN \
	# 	--env RETICULATE_PYTHON=$PY_BIN \
	# 	--env PASSWORD=$PASSWORD \
	# 	--env PORT=$PORT \
	# 	--env USER=$USER \
	# 	rstudio_latest.sif \
	# 	/init.sh
	#--rsession-which-r=$RSTUDIO_WHICH_R \
