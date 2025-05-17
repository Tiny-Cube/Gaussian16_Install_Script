# Gaussian16_Install_Script
Gaussian16_Install_Script

A script to install Gaussian16 on Linux.

## Usage
``` shell
chmod +x install_gaussian.sh

./install_gaussian.sh

```

```
./install_gaussian.sh -h
```

```
========================================
       Gaussian install script
========================================
current shell: bash
Instruction sets supported by the CPU:
avx avx2 sse4a 
usage: ./install_gaussian.sh [option]
options:
  -h, --help	        show help
  -f, --file <path>   Gaussian.tar.gz path to the installation package
  -d, --dir <path>    installed direction path
```

## or
```
./install_gaussian.sh -f parh/to/gausaian16_package -d path/to/gaussian16
```

## gaussian_scratch
``` 
export GAUSS_SCRDIR=$HOME/gaussian_scratch
```