# DispNet/FlowNet Docker Image

[![License](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)

This repository contains a Dockerfile and scripts to build and run neural networks for disparity and optical flow estimation in Docker containers. We also provide some example data to test the networks. 

If you use this project or parts of it in your research, please cite the DispNet's original paper:

    @InProceedings{dispnet,
      author    = "N. Mayer and E. Ilg and P. H{\"a}usser and P. Fischer and D. Cremers and A. Dosovitskiy and T. Brox",
      title     = "A Large Dataset to Train Convolutional Networks for Disparity, Optical Flow, and Scene Flow Estimation",
      booktitle = "IEEE International Conference on Computer Vision and Pattern Recognition (CVPR)",
      year      = "2016",
      note      = "arXiv:1512.02134",
      url       = "http://lmb.informatik.uni-freiburg.de/Publications/2016/MIFDB16"
    }

See the [paper website](http://lmb.informatik.uni-freiburg.de/Publications/2016/MIFDB16) and the [dataset website](https://lmb.informatik.uni-freiburg.de/resources/datasets/SceneFlowDatasets.en.html) for more details.

## 0. Requirements

To run the networks, you need an Nvidia GPU with >1GB or memory (at least Kepler).


## 1. Building the DN/FN Docker image

Simply run `make`. This will create two Docker images: The OS base (an Ubuntu 16.04 base extended by Nvidia, with CUDA 8.0), and the "dispflownet" image on top. In total, about 6GB of space will be needed after building. Build times are a little slow.


## 2. Running DN/FN containers

Make sure you have read/write rights for the current folder. Run the `run-network.sh` script. It will print some help text, but here are two examples to start from:

### 2.1 Disparity estimation
- we use the *DispNetCorr1D* variant with pretrained weights
- we assume that we are on a single-GPU system
- we want debug outputs, but not the whole network stdout

> $ ./dispflownet-dockerfiles/run-network.sh -n DispNetCorr1D -v data/disparity-left-images.txt data/disparity-right-images.txt data/disparity-outputs.txt


### 2.2 Optical flow estimation
- we use the *FlowNetC* variant with pretrained weights
- we want to use the second GPU on a multi-GPU system (i.e. the GPU with index "1" as reported by `nvidia-smi`)
- we want to see the full network stdout printfest

> $ ./dispflownet-dockerfiles/run-network.sh -n FlowNetC -g 1 -vv data/flow-first-images.txt data/flow-second-images.txt data/flow-outputs.txt


**NOTE:** All the network outputs will be files belonging to "root".  As a regular user, you cannot change these files, but you can copy them to files that belong to you, and then delete the originals:

    $ cp 0000000-disp.pfm user-owned-0000000-disp.pfm
    $ rm 0000000-disp.pfm


## 3. License
The files in this repository are under the [GNU General Public License v3.0](LICENSE.txt)

