# SPECFEM3D
ROCm implementation of SPECFEM3D

**PREREQUISITES**
- **Autotools**:
```bash
$sudo apt-get install autotools-dev autoconf
```
- **UNIX UTILITIES**:
```bash
$sudo apt-get install flex bison gfortran
```
- **MPI **(Open MPI)**:**
```bash
# cloning the ompi from GitHub
$git clone https://github.com/open-mpi/ompi.git -b v4.0.x
# Installation of ompi
$cd ompi/
$./autogen.pl
$./configure --prefix=/opt/ompi --enable-mpi-cxx
#/opt/ompi will be the installation path
$make
$make install
```
  
**CHANGES TO DO**
- Set the `HIP_INC` and `HIP_LIB` in cit_hip.m4 file in /m4 folder 
(Only if it is other than /opt/rocm/include and /opt/rocm/lib).
- Copy cit_hip.m4 file to m4/ folder.

**BUILDING STEPS**
```bash
$aclocal 
$autoreconf -i
$./configure --with-hip
$make all
$make realclean # For cleaning all the object and module files.
```

**FOR NVIDIA MACHINE**
```bash
#Before ./configure --with-hip step
$export HIP_PLATFORM=nvcc
$export CUDA_LIB=/usr/local/cuda/lib64 #change as per your requirement.
```

**TEST**
```bash
$make test
```

**TO RUN EXAMPLES**
```bash
$cd EXAMPLES/ 

# In each example there is DATA/Par_file
# In that file set  GPU_MODE   = .true.

# Most of the examples can be run by running the script
# for some, we need to follow README.md file in respective example folder.
```
