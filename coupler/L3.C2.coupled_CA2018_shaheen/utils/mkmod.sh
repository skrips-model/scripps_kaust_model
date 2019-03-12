#!/bin/csh -f
#
#$Id: mkmod.sh,v 1.13 2004/03/18 22:19:16 cnh Exp $
#$Name:  $
#
# Script to create modules for an MITgcm production code instance
# Run this script after the CPP stage of the standard genmake2 
# build
# 
# Script does following
# Selects a set of "module" files with the .f suffix. 
# The set of module files includes all the source files except
# main.f and a small number of runtime library files.
# The module file set is then placed within a module of a given name.
# A single argument to the script is used to create a module prefix
# allowing the same source tree to be used for multiple modules with
# differing names and dirrent sized static data objects.
#
# 
# Set module prefix 
if ( $# == 1 ) then
set mpref_s = ( $1 )
else
set mpref_s = ( atm )
endif
set mpref_l = ( mitgcm_org_${mpref_s} )

# Set output directory - this is the directory where the compile and link 
#                        objects that other builds (ESMF drivers etc..) use
set outdir = ( mmout )

# Get the genmake generated Makefile to create the .f files
echo "Creating small f files"
make small_f

echo "Building list of .f files"
ls -1 *.f > flist
cp flist flist1
set mitgcmrtl   = ( mds_byteswapr4.f mds_byteswapr8.f fool_the_compiler.f )
set excludelist = ( main.f ${mitgcmrtl} )
foreach f ( $excludelist )
 cat flist1 | grep -v "^$f" > flist2
 cp flist2   flist1
end
cp flist1 flist
set flist = (`cat flist`)

echo "Joining .f into ${mpref_s}_mod.F"
\rm ${mpref_l}_mod.Ftmp ${mpref_l}_mod.F
foreach f ( $flist )
 cat $f >> ${mpref_l}_mod.Ftmp
 echo -n "."
end
echo " "

echo "Removing comments and blank lines"
cat ${mpref_l}_mod.Ftmp | grep -v '^ *$' | grep -v '^[a-zA-Z]' > ${mpref_l}_mod2.Ftmp

echo "Creating top lines for module source"
cat <<EOF > ${mpref_l}_mod.Ftmp
      MODULE ${mpref_l}
      ! USE ESMF_MOD
      PRIVATE
      PUBLIC MIT_INIT
      PUBLIC MIT_RUN
      PUBLIC GET_DOMAIN_SIZE
      PUBLIC GET_PARAMETERS
      PUBLIC GET_GRID_PARAMETERS
      PUBLIC GET_FIELD_PARAMETERS
      PUBLIC GET_TOTAL_PRECIP
      PUBLIC GET_THETA
      PUBLIC GET_UVOCE
      PUBLIC GET_SST_INI
      PUBLIC SET_SST_INI
      CONTAINS
EOF

echo "Putting END SUBROUTINE at end of subroutines"
cat ${mpref_l}_mod2.Ftmp | awk -f print_sub.awk  > ${mpref_l}_mod3.Ftmp
cat ${mpref_l}_mod3.Ftmp >> ${mpref_l}_mod.Ftmp

#
echo "Putting END FUNCTION at end of functions"
cat ${mpref_l}_mod2.Ftmp | awk -f print_func.awk > ${mpref_l}_mod4.Ftmp
cat ${mpref_l}_mod4.Ftmp >> ${mpref_l}_mod.Ftmp

#
echo "Write the end of the module"
cat ${mpref_l}_mod2.Ftmp | awk -f print_func.awk > ${mpref_l}_mod4.Ftmp
cat <<EOF >> ${mpref_l}_mod.Ftmp
      END MODULE ${mpref_l}
EOF

# Remove EXTERNAL refs for functions (some compilers say it is an error 
# to have EXTERNAL on these if they are in a module )
echo "Removing EXTERNAL refs for functions that are within the module"
set extDel = ( DIFFERENT_MULTIPLE IFNBLNK ILNBLNK TIMER_INDEX \
               IO_ERRCOUNT MDS_RECLEN PORT_RAND SBO_RHO NLATBND \
               EXF_BULKQSAT EXF_BULKCDN EXF_BULKRHN DIAGNOSTICS_IS_ON \
               DIAGS_MK_UNITS DIAGS_MK_TITLE DIAGS_RENAMED \
               DIFF_PHASE_MULTIPLE GAD_DIAG_SUFX DIAGS_GET_PARMS_I \
               GAD_ADVSCHEME_GET MASTER_CPU_IO FIND_GCD_N sw_temp \
               gsw_gibbs_pt0_pt0 gsw_ct_from_pt sw_adtg sw_ptmp \
               cal_IsLeap cal_intDays cal_intMonths cal_intYears \
               LAGRAN etime SEAICE_DIAG_SUFX THSICE_DIAG_SUFX \
               )

foreach e ( $extDel )
cat ${mpref_l}_mod.Ftmp | grep -iv "      EXTERNAL *${e}" > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
end

echo "Removing DUMMY functions within the module"
set dummyDel = ( MNCCDIR MNCFSIZE )

foreach e ( $dummyDel )
cat ${mpref_l}_mod.Ftmp | grep -iv "      CALL *${e}" > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
end

cp ${mpref_l}_mod.Ftmp f00.Ftmp

# Remove type declaarations for functions (some compilers say it is an error 
# to have TYPE in a routine for these if they are in a module )
echo "Removing type declarations for functions that are within the module"
cat ${mpref_l}_mod.Ftmp | grep -iv '      *LOGICAL *DIFFERENT_MULTIPLE' \
    > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *ILNBLNK' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *IFNBLNK' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *TIMER_INDEX' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *IO_ERRCOUNT' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *MDS_RECLEN' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *NLATBND' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *PORT_RAND' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *SBO_RHO' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *EXF_BULKQSAT' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *EXF_BULKCDN' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *EXF_BULKRHN' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *LOGICAL *DIAGNOSTICS_IS_ON' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*(16) *DIAGS_MK_UNITS' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*(80) *DIAGS_MK_TITLE' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*(8) *DIAGS_RENAMED' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *LOGICAL *DIFF_PHASE_MULTIPLE' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*4 *GAD_DIAG_SUFX' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *DIAGS_GET_PARMS_I' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *GAD_ADVSCHEME_GET' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *LOGICAL *MASTER_CPU_IO' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *FIND_GCD_N' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *gsw_gibbs_pt0_pt0' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *gsw_ct_from_pt' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *sw_adtg' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *sw_ptmp' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *sw_temp' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *cal_IsLeap' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *cal_intDays' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *cal_intMonths' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *INTEGER *cal_intYears' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *Real\*8 *LAGRAN' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *Real\*4 *etime' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*4 *THSICE_DIAG_SUFX' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*4 *SEAICE_DIAG_SUFX' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp

cat ${mpref_l}_mod.Ftmp | grep -iv '      *CHARACTER\*16 *DIAGS_MK_UNITS' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *REAL\*8 *IDEMIX_gofx2,IDEMIX_hofx1' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | grep -iv '      *logical *QUADROOT' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp

# Change all the common block names in the module to use the module prefix
cat ${mpref_l}_mod.Ftmp | sed s'z\( *COMMON[^/]*\)/\(.*\)/\([^/]*\)z      COMMON/C_'${mpref_s}'_\2/\3z' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | sed s'/\/MPIFCMB5/\/C_ocn_MPIFCMB5/'> f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | sed s'/\/MPIFCMB9/\/C_ocn_MPIFCMB9/'> f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp
cat ${mpref_l}_mod.Ftmp | sed s'/C_'${mpref_s}'_MPIPRIV/MPIPRIV/' > f1.Ftmp
cp f1.Ftmp ${mpref_l}_mod.Ftmp

# echo "Compiling code"
# source ${BUILDROOT}/mytools/comp_profile.BASE
# source ${BUILDROOT}/mytools/comp_profile.${COMP_PROF}
# 
# set compinc  = ( ${compinc} -I${BUILDROOT}/esmf_top )

# set comp     = /project_shared/Libraries/openmpi-2.1.1_pgi_fortran_17.5-0/bin/mpifort
# set cccommand = /project_shared/Libraries/openmpi-2.1.1_pgi_fortran_17.5-0/bin/mpicc

set comp      = ftn
set cccommand = cc
set compopts = (-DWORDLENGTH=4 -DALLOW_USE_MPI -DALWAYS_USE_MPI -DHAVE_SETRLSTK -DHAVE_SIGREG -DHAVE_STAT -DHAVE_FLUSH -g -convert big_endian -assume byterecl)
set compopts_num = ( $compopts )
set complibs = (-L/opt/cray/pe/netcdf/4.4.1.1.6/INTEL/16.0/lib -L/opt/cray/pe/parallel-netcdf/1.8.1.3/INTEL/16.0/lib -L/opt/cray/pe/mpt/7.7.0/gni/mpich-intel/16.0/lib -lnetcdf -lnetcdff -lpnetcdf)
set compinc = (-I/opt/cray/pe/netcdf/4.4.1.1.6/INTEL/16.0/include -I/opt/cray/pe/parallel-netcdf/1.8.1.3/INTEL/16.0/include -I/opt/cray/pe/mpt/7.7.0/gni/mpich-intel/16.0/include)
set ccopts = "-c"

set arcommand = ar
set aropts    = "-rsc"

echo "Compiling code 1"
# Create output directory
mkdir mmout

echo "Compiling code 2"
# Create runtime library archive
set mitgcmrtlo = ( )
foreach f ( $mitgcmrtl )
 echo " " | $comp $compopts_num -c ${f}
 set mitgcmrtlo = ( $mitgcmrtlo ${f:r}.o )
end
${cccommand} ${ccopts} tim.c
set mitgcmrtlo = ( $mitgcmrtlo tim.o )
\rm mmout/libmitgcmrtl.a
${arcommand} ${aropts} mmout/libmitgcmrtl.a $mitgcmrtlo
#ranlib mmout/libmitgcmrtl.a

echo "Compiling code 3"
# Create component library archive
mv ${mpref_l}_mod.Ftmp ${mpref_l}_mod.F
source scommand
mv foo.F ${mpref_l}_mod.F

echo "Compiling code 4"
sed -i "s/COMMON\/C_ocn_PTRACERS_SURFCOR_FIELDS\/ totSurfCorPTr, meanSurfCorPTr/COMMON\/C_ocn_PTRACERS_SURFCOR_FIELDS\/ totSurfCorPTr \n      COMMON\/C_ocn_PTRACERS_SURFCOR_FIELDS\/ meanSurfCorPTr/g" mitgcm_org_ocn_mod.F
echo "Compiling code 5"
echo " " | $comp $compopts_num -c ${mpref_l}_mod.F ${complibs} ${compinc}
echo "Compiling code 6"
mv ${mpref_l}_mod.F ${mpref_l}_mod.Ftmp
./template_comp.sh ${mpref_s}
${cccommand} ${ccopts} component_${mpref_s}_context.c
\rm mmout/lib${mpref_l}.a
${arcommand} ${aropts} mmout/lib${mpref_l}.a ${mpref_l}_mod.o component_${mpref_s}_context.o
#ranlib mmout/lib${mpref_l}.a
set modname = `echo ${mpref_l} | ${mkmodname}`
echo $modname
cp ${modname}.mod mmout
#\rm *mod