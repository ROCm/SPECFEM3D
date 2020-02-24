# SPECFEM3D
ROCm implementation of SPECFEM3D


**PREREQUISITES**
- Set the variables `SET_MPI_LIB` and `SET_HIP_LIB` in Makefile.in
- Set the `HIP_INC` and `HIP_LIB` in cit_hip.m4 file in util folder.
- Copy `/utils/cit_hip.m4` file to `m4/` folder

**BUILDING STEPS**
```bash
aclocal 
autoreconf -i
./configure --with-hip
make all
```

**TEST**
```bash
make test
```

**TO RUN EXAMPLES**
```bash
cd EXAMPLES/ 

# In each example there is DATA/Par_file
# In that file set  GPU_MODE   = .true.

# Most of the examples can be run by running the script
# for some, we need to follow README.md file in respective example folder.
```
