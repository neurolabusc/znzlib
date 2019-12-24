
## About

[znzlib](https://nifti.nimh.nih.gov/pub/dist/src/znzlib/) provides an interface to both compressed (gzip/zlib) and
uncompressed (normal) file IO. Written by Mark Jenkinson in 2004 and released into the public domain, it is used by many popular tools in the neuroimaging community including [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/) and [AFNI](https://github.com/afni/afni/tree/master/src/nifti). While reading compressed gzip files is very fast, creating these files is very slow. Modern neuroimaging methods like multi-band mean that fMRI and DWI datasets are often huge, and tools can spend a considerable amount of time compressing images. Indeed, for some stages of processing such as Gaussian blurring the majority of time can simply be spent [compressing the modified images](https://github.com/neurolabusc/niiSmooth).

This repository modifies the traditional repository to dramatically accelerate creation of gzip files. Since these methods are embedded into znzlib, it provides a simple method to improve the performance of many tools. This library modifies the znzlib in two ways:

1. The traditional zlib is replaced with the [CloudFlare](https://github.com/cloudflare/zlib) zlib. This doubles the compression speed by leveraging instructions available in modern (since 2009) x86-64 CPUs from Intel and AMD.

2. [pigz](https://github.com/neurolabusc/pigz) accelerates compression by use the fact that modern computers can run many threads simultaneously. This parallel processing can dramatically speed up compression. Further, you can compile pigz to use the CloudFlare enhancements, speeding up compression an [additional 40%](https://github.com/neurolabusc/pigz). 

## Compiling

To compile the basic version, simply run make in the main folder.

```
make
```

Currently, the CloudFlare acceleration is only provided for MacOS. The code can be easily adpapted for Linux, by modifying this [cmake script](https://github.com/neurolabusc/pigz).

```
CF=1 make
```

You can also compile an optimized version of pigz on either MacOS or Linux (just make sure to copy this version in your path, replacing other versions).

```
git clone https://github.com/neurolabusc/pigz.git
cd pigz
mkdir build && cd build
```

Compiling on Windows is a bit more involved. The repository includes the CloudFlare zlib compiled for Windows MSVC Compiler 19. If you have a different compiler, you can use dcm2niix build script to build the zlib again. The compilation is as follows:

```
cl -o clib_01_read_write clib_01_read_write.c  niftilib/nifti1_io.c znzlib/znzlib.c -I./niftilib -I./znzlib win/zlibd.lib -I./win -DHAVE_ZLIB
```   

## Usage

Here is a simple demonstration, running on a four core (eight thread, 28w) MacBook laptop. Note that you enable pigz by defining "AFNI_COMPRESSOR=PIGZ" in your environment. In this example the single-threaded CloudFlare zlib is more than four times faster than the default single-threaded zlib in saving data. The parallel CloudFlare+pigz is more than 100 times faster. While this demonstrates the benefit, the magnitude of these benefits is atypical: the sample dataset has had air outside the brain set to zero to allow a small Github repository. Typically, CloudFlare doubles performance, while pigz provides an almost linear increase with the number of threads.

```
>make
>./clib_01_read_write -input test4D.nii.gz -output single.nii.gz
read time: 268 ms
write time: 4017 ms
>export AFNI_COMPRESSOR=PIGZ
>./clib_01_read_write -input test4D.nii.gz -output parallel.nii.gz
read time: 261 ms
write time: 39 ms
>export AFNI_COMPRESSOR=GZ
>CF=1 make
gcc -O3 -lm  -I./darwin ./darwin/libz.a	 -o clib_01_read_write clib_01_read_write.c  niftilib/nifti1_io.c znzlib/znzlib.c -I./niftilib -I./znzlib -DHAVE_ZLIB
>./clib_01_read_write -input test4D.nii.gz -output singleCF.nii.gz
read time: 273 ms
write time: 907 ms
```

Below is the same on a 4-Core (eight thread, 15w CPU) Windows laptop. Several people have compiled pigz for Windows, but you want to make sure you have version 2.34 or later (prior versions do not support piped file creation). You can get version 2.4 compiled for Windows [here](http://binaries.przemoc.net). Note that in this example pigz has not been compiled for CloudFlare, while the main executable has been.

```
>set AFNI_COMPRESSOR=PIGZ
>clib_01_read_write -input test4D.nii.gz -output parallel.nii.gz
read time: 796 ms
write time: 828 ms
>set AFNI_COMPRESSOR=GZ
>clib_01_read_write -input test4D.nii.gz -output serial.nii.gz
read time: 793 ms
write time: 2825 ms 
```


## License

This code is released to the public domain. The primary author of znzlib was  was Mark Jenkinson, FMRIB Centre, University of Oxford (2004). The primary author of nifti1_io was Robert W Cox (2003). The source code lists additional contributors as well as the formal licenses. The pigz modifcations were by Chris Rorden (2019), who added a few lines to `nifti1_io.c`. The modifications are in the `ifdef pigz` blocks. 

Note that none of the code is changed for the CloudFlare zlib. The compiler is simply directed to use that library instead of the system zlib library.