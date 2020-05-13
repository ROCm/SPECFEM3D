/*
 !=====================================================================
 !
 !               S p e c f e m 3 D  V e r s i o n  3 . 0
 !               ---------------------------------------
 !
 !     Main historical authors: Dimitri Komatitsch and Jeroen Tromp
 !                              CNRS, France
 !                       and Princeton University, USA
 !                 (there are currently many more authors!)
 !                           (c) October 2017
 !
 ! This program is free software; you can redistribute it and/or modify
 ! it under the terms of the GNU General Public License as published by
 ! the Free Software Foundation; either version 3 of the License, or
 ! (at your option) any later version.
 !
 ! This program is distributed in the hope that it will be useful,
 ! but WITHOUT ANY WARRANTY; without even the implied warranty of
 ! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 ! GNU General Public License for more details.
 !
 ! You should have received a copy of the GNU General Public License along
 ! with this program; if not, write to the Free Software Foundation, Inc.,
 ! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 !
 !=====================================================================
 */

#include "mesh_constants_cuda.h"
#include "prepare_constants_cuda.h"

/* ----------------------------------------------------------------------------------------------- */

  #ifdef USE_TEXTURES_FIELDS
    // elastic
    extern realw_texture d_displ_tex;
    extern realw_texture d_veloc_tex;
    extern realw_texture d_accel_tex;
    // backward/reconstructed
    extern realw_texture d_b_displ_tex;
    extern realw_texture d_b_veloc_tex;
    extern realw_texture d_b_accel_tex;
    // acoustic
    extern realw_texture d_potential_tex;
    extern realw_texture d_potential_dot_dot_tex;
    // backward/reconstructed
    extern realw_texture d_b_potential_tex;
    extern realw_texture d_b_potential_dot_dot_tex;
  #endif
  #ifdef USE_TEXTURES_CONSTANTS
    extern realw_texture d_hprime_xx_tex;
  #endif


/* ----------------------------------------------------------------------------------------------- */

// GPU preparation

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_constants_device,
              PREPARE_CONSTANTS_DEVICE)(long* Mesh_pointer,
                                        int* h_NGLLX, int* NSPEC_AB, int* NGLOB_AB,
                                        int* NSPEC_IRREGULAR,int* h_irregular_element_number,
                                        realw* h_xix, realw* h_xiy, realw* h_xiz,
                                        realw* h_etax, realw* h_etay, realw* h_etaz,
                                        realw* h_gammax, realw* h_gammay, realw* h_gammaz,
                                        realw* xix_regular, realw* jacobian_regular,
                                        int* h_ibool,
                                        int* num_interfaces_ext_mesh, int* max_nibool_interfaces_ext_mesh,
                                        int* h_nibool_interfaces_ext_mesh, int* h_ibool_interfaces_ext_mesh,
                                        realw* h_hprime_xx, realw* h_hprimewgll_xx,
                                        realw* h_wgllwgll_xy,realw* h_wgllwgll_xz,realw* h_wgllwgll_yz,
                                        int* ABSORBING_CONDITIONS,
                                        int* h_abs_boundary_ispec, int* h_abs_boundary_ijk,
                                        realw* h_abs_boundary_normal,
                                        realw* h_abs_boundary_jacobian2Dw,
                                        int* h_num_abs_boundary_faces,
                                        int* h_ispec_is_inner,
                                        int* NSOURCES, int* nsources_local_f,
                                        realw* h_sourcearrays,
                                        int* h_islice_selected_source, int* h_ispec_selected_source,
                                        int* h_ispec_selected_rec,
                                        int* nrec,int* nrec_local,
                                        int* SIMULATION_TYPE,
                                        int* USE_MESH_COLORING_GPU_f,
                                        int* nspec_acoustic,int* nspec_elastic,
                                        int* h_myrank,
                                        int* SAVE_FORWARD,
                                        realw* h_xir,realw* h_etar, realw* h_gammar,double * nu_rec,
                                        int* islice_selected_rec,
                                        int* NTSTEP_BETWEEN_OUTPUT_SEISMOS,
                                        int* SAVE_SEISMOGRAMS_DISPLACEMENT,int* SAVE_SEISMOGRAMS_VELOCITY,
                                        int* SAVE_SEISMOGRAMS_ACCELERATION,int* SAVE_SEISMOGRAMS_PRESSURE) {

  TRACE("prepare_constants_device");

  // allocates mesh parameter structure
  Mesh* mp = (Mesh*) malloc( sizeof(Mesh) );
  if (mp == NULL) exit_on_error("error allocating mesh pointer");
  *Mesh_pointer = (long)mp;

  // sets processes mpi rank
  mp->myrank = *h_myrank;

  // sets global parameters
  mp->NSPEC_AB = *NSPEC_AB;
  mp->NSPEC_IRREGULAR = *NSPEC_IRREGULAR;
  mp->NGLOB_AB = *NGLOB_AB;

  // constants
  mp->simulation_type = *SIMULATION_TYPE;
  mp->absorbing_conditions = *ABSORBING_CONDITIONS;
  mp->save_forward = *SAVE_FORWARD;

// DK DK August 2018: adding this test, following a suggestion by Etienne Bachmann
  if (*h_NGLLX != NGLLX) {
    exit_on_error("make sure that the NGLL constants are equal in the two files:\n" \
                  "  setup/constants.h and src/cuda/mesh_constants_cuda.h\n" \
                  "and then please re-compile; also make sure that the value of NGLL3_PADDED " \
                  "is consistent with the value of NGLL\n");
  }

  // sets constant arrays
  setConst_hprime_xx(h_hprime_xx,mp);
  // setConst_hprime_yy(h_hprime_yy,mp); // only needed if NGLLX != NGLLY != NGLLZ
  // setConst_hprime_zz(h_hprime_zz,mp); // only needed if NGLLX != NGLLY != NGLLZ

  setConst_hprimewgll_xx(h_hprimewgll_xx,mp);
  //setConst_hprimewgll_yy(h_hprimewgll_yy,mp); // only needed if NGLLX != NGLLY != NGLLZ
  //setConst_hprimewgll_zz(h_hprimewgll_zz,mp); // only needed if NGLLX != NGLLY != NGLLZ

  setConst_wgllwgll_xy(h_wgllwgll_xy,mp);
  setConst_wgllwgll_xz(h_wgllwgll_xz,mp);
  setConst_wgllwgll_yz(h_wgllwgll_yz,mp);

  // Using texture memory for the hprime-style constants is slower on
  // Fermi generation hardware, but *may* be faster on Kepler
  // generation. We will reevaluate this again, so might as well leave
  // in the code with with #USE_TEXTURES_FIELDS not-defined.
  #ifdef USE_TEXTURES_CONSTANTS
  {
      hipChannelFormatDesc channelDesc = hipCreateChannelDesc<float>();
      print_CUDA_error_if_any(hipBindTexture(0, &d_hprime_xx_tex, mp->d_hprime_xx, &channelDesc, sizeof(realw)*(NGLL2)), 4001);
  }
  #endif

  copy_todevice_int((void**)&mp->d_irregular_element_number,h_irregular_element_number,mp->NSPEC_AB);
  mp->xix_regular = *xix_regular;
  mp->jacobian_regular = *jacobian_regular;

  // mesh
  // Assuming NGLLX=5. Padded is then 128 (5^3+3)
  int size_padded = NGLL3_PADDED * (mp->NSPEC_IRREGULAR > 0 ? *NSPEC_IRREGULAR : 1);

  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_xix, size_padded*sizeof(realw)),1001);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_xiy, size_padded*sizeof(realw)),1002);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_xiz, size_padded*sizeof(realw)),1003);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_etax, size_padded*sizeof(realw)),1004);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_etay, size_padded*sizeof(realw)),1005);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_etaz, size_padded*sizeof(realw)),1006);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_gammax, size_padded*sizeof(realw)),1007);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_gammay, size_padded*sizeof(realw)),1008);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_gammaz, size_padded*sizeof(realw)),1009);

  // transfer constant element data with padding
  /*
  // way 1: slow...
  for(int i=0;i < mp->NSPEC_IRREGULAR;i++) {
    print_CUDA_error_if_any(hipMemcpy(mp->d_xix + i*NGLL3_PADDED, &h_xix[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1501);
    print_CUDA_error_if_any(hipMemcpy(mp->d_xiy+i*NGLL3_PADDED,   &h_xiy[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1502);
    print_CUDA_error_if_any(hipMemcpy(mp->d_xiz+i*NGLL3_PADDED,   &h_xiz[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1503);
    print_CUDA_error_if_any(hipMemcpy(mp->d_etax+i*NGLL3_PADDED,  &h_etax[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1504);
    print_CUDA_error_if_any(hipMemcpy(mp->d_etay+i*NGLL3_PADDED,  &h_etay[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1505);
    print_CUDA_error_if_any(hipMemcpy(mp->d_etaz+i*NGLL3_PADDED,  &h_etaz[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1506);
    print_CUDA_error_if_any(hipMemcpy(mp->d_gammax+i*NGLL3_PADDED,&h_gammax[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1507);
    print_CUDA_error_if_any(hipMemcpy(mp->d_gammay+i*NGLL3_PADDED,&h_gammay[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1508);
    print_CUDA_error_if_any(hipMemcpy(mp->d_gammaz+i*NGLL3_PADDED,&h_gammaz[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1509);
    print_CUDA_error_if_any(hipMemcpy(mp->d_kappav+i*NGLL3_PADDED,&h_kappav[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1510);
    print_CUDA_error_if_any(hipMemcpy(mp->d_muv+i*NGLL3_PADDED,   &h_muv[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),1511);
  }
  */
  // way 2: faster ....
  if (*NSPEC_IRREGULAR > 0 ){
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_xix, NGLL3_PADDED*sizeof(realw),
                                         h_xix, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1501);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_xiy, NGLL3_PADDED*sizeof(realw),
                                         h_xiy, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1502);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_xiz, NGLL3_PADDED*sizeof(realw),
                                         h_xiz, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1503);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_etax, NGLL3_PADDED*sizeof(realw),
                                         h_etax, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1504);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_etay, NGLL3_PADDED*sizeof(realw),
                                         h_etay, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1505);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_etaz, NGLL3_PADDED*sizeof(realw),
                                         h_etaz, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1506);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_gammax, NGLL3_PADDED*sizeof(realw),
                                         h_gammax, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1507);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_gammay, NGLL3_PADDED*sizeof(realw),
                                         h_gammay, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1508);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_gammaz, NGLL3_PADDED*sizeof(realw),
                                         h_gammaz, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_IRREGULAR, hipMemcpyHostToDevice),1509);
  }

  size_padded = NGLL3_PADDED * (mp->NSPEC_AB);

  // global indexing (padded)
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_ibool, size_padded*sizeof(int)),1600);
  print_CUDA_error_if_any(hipMemcpy2D(mp->d_ibool, NGLL3_PADDED*sizeof(int),
                                       h_ibool, NGLL3*sizeof(int), NGLL3*sizeof(int),
                                       mp->NSPEC_AB, hipMemcpyHostToDevice),1601);


  // prepare interprocess-edge exchange information
  mp->num_interfaces_ext_mesh = *num_interfaces_ext_mesh;
  mp->max_nibool_interfaces_ext_mesh = *max_nibool_interfaces_ext_mesh;
  if (mp->num_interfaces_ext_mesh > 0){
    copy_todevice_int((void**)&mp->d_nibool_interfaces_ext_mesh,h_nibool_interfaces_ext_mesh,
                      mp->num_interfaces_ext_mesh);
    copy_todevice_int((void**)&mp->d_ibool_interfaces_ext_mesh,h_ibool_interfaces_ext_mesh,
                      (mp->num_interfaces_ext_mesh)*(mp->max_nibool_interfaces_ext_mesh));
  }

  // setup two streams, one for compute and one for host<->device memory copies
  // compute stream
  hipStreamCreate(&mp->compute_stream);
  // copy stream (needed to transfer mpi buffers)
  if (mp->num_interfaces_ext_mesh * mp->max_nibool_interfaces_ext_mesh > 0){
    hipStreamCreate(&mp->copy_stream);
  }

  // inner elements
  copy_todevice_int((void**)&mp->d_ispec_is_inner,h_ispec_is_inner,mp->NSPEC_AB);

  // absorbing boundaries
  mp->d_num_abs_boundary_faces = *h_num_abs_boundary_faces;
  if (mp->absorbing_conditions && mp->d_num_abs_boundary_faces > 0){
    copy_todevice_int((void**)&mp->d_abs_boundary_ispec,h_abs_boundary_ispec,mp->d_num_abs_boundary_faces);
    copy_todevice_int((void**)&mp->d_abs_boundary_ijk,h_abs_boundary_ijk,
                      3*NGLL2*(mp->d_num_abs_boundary_faces));
    copy_todevice_realw((void**)&mp->d_abs_boundary_normal,h_abs_boundary_normal,
                        NDIM*NGLL2*(mp->d_num_abs_boundary_faces));
    copy_todevice_realw((void**)&mp->d_abs_boundary_jacobian2Dw,h_abs_boundary_jacobian2Dw,
                        NGLL2*(mp->d_num_abs_boundary_faces));
  }

  // sources
  mp->nsources_local = *nsources_local_f;
  if (mp->simulation_type == 1  || mp->simulation_type == 3){
    // not needed in case of pure adjoint simulations (SIMULATION_TYPE == 2)
    copy_todevice_realw((void**)&mp->d_sourcearrays,h_sourcearrays,(*NSOURCES)*NDIM*NGLL3);

    // buffer for source time function values
    print_CUDA_error_if_any(hipMalloc((void**)&mp->d_stf_pre_compute,(*NSOURCES)*sizeof(field)),1303);
  }
  copy_todevice_int((void**)&mp->d_islice_selected_source,h_islice_selected_source,(*NSOURCES));
  copy_todevice_int((void**)&mp->d_ispec_selected_source,h_ispec_selected_source,(*NSOURCES));


  // receiver stations
  mp->save_seismograms_d = *SAVE_SEISMOGRAMS_DISPLACEMENT;
  mp->save_seismograms_v = *SAVE_SEISMOGRAMS_VELOCITY;
  mp->save_seismograms_a = *SAVE_SEISMOGRAMS_ACCELERATION;
  mp->save_seismograms_p = *SAVE_SEISMOGRAMS_PRESSURE;

  mp->nrec_local = *nrec_local; // number of receiver located in this partition
  // note that:
  // size(ispec_selected_rec) = nrec
  if (mp->nrec_local > 0){
    copy_todevice_realw((void**)&mp->d_hxir,h_xir,NGLLX*mp->nrec_local);
    copy_todevice_realw((void**)&mp->d_hetar,h_etar,NGLLY*mp->nrec_local);
    copy_todevice_realw((void**)&mp->d_hgammar,h_gammar,NGLLZ*mp->nrec_local);

    // stores only local receiver rotations in d_nu_rec
    realw* h_nu_rec;
    h_nu_rec = (realw*)malloc(NDIM * NDIM * mp->nrec_local * sizeof(realw));
    int irec_loc = 0;
    for (int i=0;i < (*nrec);i++){
      if (mp->myrank == islice_selected_rec[i]){
         for (int j = 0; j < 9; j++) h_nu_rec[j + NDIM * NDIM * irec_loc] = (realw)nu_rec[j + NDIM * NDIM * i];
         irec_loc = irec_loc + 1;
      }
    }
    copy_todevice_realw((void**)&mp->d_nu_rec,h_nu_rec,NDIM * NDIM * (*nrec_local));
    free(h_nu_rec);

    // seismograms
    int size =  (*NTSTEP_BETWEEN_OUTPUT_SEISMOS) * (*nrec_local);

    if (mp->save_seismograms_d)
      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_d,NDIM * size * sizeof(realw)),1801);
    if (mp->save_seismograms_v)
      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_v,NDIM * size * sizeof(realw)),1802);
    if (mp->save_seismograms_a)
      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_a,NDIM * size * sizeof(realw)),1803);
    if (mp->save_seismograms_p)
      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_p,size * sizeof(field)),1804);

    int *ispec_selected_rec_loc;
    ispec_selected_rec_loc = (int*)malloc(mp->nrec_local * sizeof(int));
    irec_loc = 0;
    for(int i=0;i<*nrec;i++) {
      if ( mp->myrank == islice_selected_rec[i]){
        ispec_selected_rec_loc[irec_loc] = h_ispec_selected_rec[i];
        irec_loc = irec_loc+1;
      }
    }
    copy_todevice_int((void**)&mp->d_ispec_selected_rec_loc,ispec_selected_rec_loc,mp->nrec_local);
    free(ispec_selected_rec_loc);
  }
  copy_todevice_int((void**)&mp->d_ispec_selected_rec,h_ispec_selected_rec,(*nrec));

#ifdef USE_MESH_COLORING_GPUX
  mp->use_mesh_coloring_gpu = 1;
  if (! *USE_MESH_COLORING_GPU_f) exit_on_error("error with USE_MESH_COLORING_GPU constant; please re-compile\n");
#else
  // mesh coloring
  // note: this here passes the coloring as an option to the kernel routines
  //          the performance seems to be the same if one uses the pre-processing directives above or not
  mp->use_mesh_coloring_gpu = *USE_MESH_COLORING_GPU_f;
#endif

  // number of elements per domain
  mp->nspec_acoustic = *nspec_acoustic;
  mp->nspec_elastic = *nspec_elastic;

  // gravity flag initialization
  mp->gravity = 0;
  // Kelvin_voigt initialization
  mp->Kelvin_Voigt_damping = 0;
  // JC JC here we will need to add GPU support for the new C-PML routines

  GPU_ERROR_CHECKING("prepare_constants_device");
}


/* ----------------------------------------------------------------------------------------------- */

// for ACOUSTIC simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_acoustic_device,
              PREPARE_FIELDS_ACOUSTIC_DEVICE)(long* Mesh_pointer,
                                              realw* rmass_acoustic, realw* rhostore, realw* kappastore,
                                              int* num_phase_ispec_acoustic, int* phase_ispec_inner_acoustic,
                                              int* ispec_is_acoustic,
                                              int* NOISE_TOMOGRAPHY,
                                              int* num_free_surface_faces,
                                              int* free_surface_ispec,
                                              int* free_surface_ijk,
                                              int* b_reclen_potential, realw* b_absorb_potential,
                                              int* ELASTIC_SIMULATION,
                                              int* num_coupling_ac_el_faces,
                                              int* coupling_ac_el_ispec,
                                              int* coupling_ac_el_ijk,
                                              realw* coupling_ac_el_normal,
                                              realw* coupling_ac_el_jacobian2Dw,
                                              int* num_colors_outer_acoustic,
                                              int* num_colors_inner_acoustic,
                                              int* num_elem_colors_acoustic) {

  TRACE("prepare_fields_acoustic_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);

  // allocates arrays on device (GPU)
  int size = mp->NGLOB_AB;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_potential_acoustic),sizeof(field)*size),2001);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_potential_dot_acoustic),sizeof(field)*size),2002);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_potential_dot_dot_acoustic),sizeof(field)*size),2003);
  // initializes values to zero
  //print_CUDA_error_if_any(hipMemset(mp->d_potential_acoustic,0,sizeof(field)*size),2007);
  //print_CUDA_error_if_any(hipMemset(mp->d_potential_dot_acoustic,0,sizeof(field)*size),2007);
  //print_CUDA_error_if_any(hipMemset(mp->d_potential_dot_dot_acoustic,0,sizeof(field)*size),2007);

  #ifdef USE_TEXTURES_FIELDS
  {
      hipChannelFormatDesc channelDesc = hipCreateChannelDesc<float>();
      print_CUDA_error_if_any(hipBindTexture(0, &d_potential_tex, mp->d_potential_acoustic, &channelDesc, sizeof(realw)*size), 2001);
      print_CUDA_error_if_any(hipBindTexture(0, &d_potential_dot_dot_tex, mp->d_potential_dot_dot_acoustic, &channelDesc, sizeof(realw)*size), 2003);
  }
  #endif

  // mpi buffer
  mp->size_mpi_buffer_potential = (mp->num_interfaces_ext_mesh) * (mp->max_nibool_interfaces_ext_mesh);
  if (mp->size_mpi_buffer_potential > 0){
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_send_potential_dot_dot_buffer),mp->size_mpi_buffer_potential *sizeof(field)),2004);
  }

  // mass matrix
  copy_todevice_realw((void**)&mp->d_rmass_acoustic,rmass_acoustic,mp->NGLOB_AB);

  // density
  // padded array
  // Assuming NGLLX==5. Padded is then 128 (5^3+3)
  int size_padded = NGLL3_PADDED * mp->NSPEC_AB;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_rhostore),size_padded*sizeof(realw)),2006);
  // transfer constant element data with padding
  /*
  // way 1: slow...
  for(int i=0; i < mp->NSPEC_AB; i++) {
    print_CUDA_error_if_any(hipMemcpy(mp->d_rhostore+i*NGLL3_PADDED, &rhostore[i*NGLL3],
                                       NGLL3*sizeof(realw),hipMemcpyHostToDevice),2106);
  }
  */
  // way 2: faster ...
  print_CUDA_error_if_any(hipMemcpy2D(mp->d_rhostore, NGLL3_PADDED*sizeof(realw),
                                       rhostore, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                       mp->NSPEC_AB, hipMemcpyHostToDevice),2106);

  // non-padded array
  copy_todevice_realw((void**)&mp->d_kappastore,kappastore,NGLL3*mp->NSPEC_AB);

  // phase elements
  mp->num_phase_ispec_acoustic = *num_phase_ispec_acoustic;
  copy_todevice_int((void**)&mp->d_phase_ispec_inner_acoustic,phase_ispec_inner_acoustic,
                    2*mp->num_phase_ispec_acoustic);
  copy_todevice_int((void**)&mp->d_ispec_is_acoustic,ispec_is_acoustic,mp->NSPEC_AB);

  // free surface
  if (*NOISE_TOMOGRAPHY == 0){
    // allocate surface arrays
    mp->num_free_surface_faces = *num_free_surface_faces;
    if (mp->num_free_surface_faces > 0){
      copy_todevice_int((void**)&mp->d_free_surface_ispec,free_surface_ispec,mp->num_free_surface_faces);
      copy_todevice_int((void**)&mp->d_free_surface_ijk,free_surface_ijk,
                        3*NGLL2*mp->num_free_surface_faces);
    }
  }

  // absorbing boundaries
  if (mp->absorbing_conditions && mp->d_num_abs_boundary_faces > 0){
    // absorb_field array used for file i/o
    if (mp->simulation_type == 3 || ( mp->simulation_type == 1 && mp->save_forward )){
      // note: b_reclen_potential is record length in bytes ( CUSTOM_REAL * NGLLSQUARE * num_abs_boundary_faces )
      mp->d_b_reclen_potential = *b_reclen_potential;
      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_b_absorb_potential,mp->d_b_reclen_potential),2201);
      print_CUDA_error_if_any(hipMemcpy(mp->d_b_absorb_potential,b_absorb_potential,mp->d_b_reclen_potential,hipMemcpyHostToDevice),2202);
    }
  }

  // coupling with elastic parts
  if (*ELASTIC_SIMULATION && *num_coupling_ac_el_faces > 0){
    copy_todevice_int((void**)&mp->d_coupling_ac_el_ispec,coupling_ac_el_ispec,(*num_coupling_ac_el_faces));
    copy_todevice_int((void**)&mp->d_coupling_ac_el_ijk,coupling_ac_el_ijk,3*NGLL2*(*num_coupling_ac_el_faces));
    copy_todevice_realw((void**)&mp->d_coupling_ac_el_normal,coupling_ac_el_normal,
                        3*NGLL2*(*num_coupling_ac_el_faces));
    copy_todevice_realw((void**)&mp->d_coupling_ac_el_jacobian2Dw,coupling_ac_el_jacobian2Dw,
                        NGLL2*(*num_coupling_ac_el_faces));
  }

  // mesh coloring
  if (mp->use_mesh_coloring_gpu ){
    mp->num_colors_outer_acoustic = *num_colors_outer_acoustic;
    mp->num_colors_inner_acoustic = *num_colors_inner_acoustic;
    mp->h_num_elem_colors_acoustic = (int*) num_elem_colors_acoustic;
  }

  GPU_ERROR_CHECKING("prepare_fields_acoustic_device");
}


/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_acoustic_adj_dev,
              PREPARE_FIELDS_ACOUSTIC_ADJ_DEV)(long* Mesh_pointer,
                                              int* APPROXIMATE_HESS_KL) {

  TRACE("prepare_fields_acoustic_adj_dev");

  Mesh* mp = (Mesh*)(*Mesh_pointer);

  // kernel simulations
  if (mp->simulation_type != 3) return;

  // allocates backward/reconstructed arrays on device (GPU)
  int size = mp->NGLOB_AB;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_potential_acoustic),sizeof(field)*size),3014);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_potential_dot_acoustic),sizeof(field)*size),3015);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_potential_dot_dot_acoustic),sizeof(field)*size),3016);
  // initializes values to zero
  //print_CUDA_error_if_any(hipMemset(mp->d_b_potential_acoustic,0,sizeof(realw)*size),3007);
  //print_CUDA_error_if_any(hipMemset(mp->d_b_potential_dot_acoustic,0,sizeof(realw)*size),3007);
  //print_CUDA_error_if_any(hipMemset(mp->d_b_potential_dot_dot_acoustic,0,sizeof(realw)*size),3007);

  #ifdef USE_TEXTURES_FIELDS
  {
      hipChannelFormatDesc channelDesc = hipCreateChannelDesc<float>();
      print_CUDA_error_if_any(hipBindTexture(0, &d_b_potential_tex, mp->d_b_potential_acoustic, &channelDesc, sizeof(realw)*size), 3001);
      print_CUDA_error_if_any(hipBindTexture(0, &d_b_potential_dot_dot_tex, mp->d_b_potential_dot_dot_acoustic, &channelDesc, sizeof(realw)*size), 3003);
  }
  #endif

  // allocates kernels
  size = NGLL3*mp->NSPEC_AB;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_rho_ac_kl),size*sizeof(realw)),3017);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_kappa_ac_kl),size*sizeof(realw)),3018);
  // initializes kernel values to zero
  print_CUDA_error_if_any(hipMemset(mp->d_rho_ac_kl,0,size*sizeof(realw)),3019);
  print_CUDA_error_if_any(hipMemset(mp->d_kappa_ac_kl,0,size*sizeof(realw)),3020);

  // preconditioner
  if (*APPROXIMATE_HESS_KL ){
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_ac_kl),size*sizeof(realw)),3030);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_rho_ac_kl),size*sizeof(realw)),3032);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_kappa_ac_kl),size*sizeof(realw)),3033);

    // initializes with zeros
    print_CUDA_error_if_any(hipMemset(mp->d_hess_ac_kl,0,size*sizeof(realw)),3031);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_rho_ac_kl,0,size*sizeof(realw)),3034);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_kappa_ac_kl,0,size*sizeof(realw)),3035);

  }

  // mpi buffer
  if (mp->size_mpi_buffer_potential > 0){
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_send_potential_dot_dot_buffer),mp->size_mpi_buffer_potential*sizeof(field)),3014);
  }

  GPU_ERROR_CHECKING("prepare_fields_acoustic_adj_dev");
}


/* ----------------------------------------------------------------------------------------------- */

// for ELASTIC simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_elastic_device,
              PREPARE_FIELDS_ELASTIC_DEVICE)(long* Mesh_pointer,
                                             realw* rmassx, realw* rmassy, realw* rmassz,
                                             realw* rho_vp, realw* rho_vs,
                                             realw* h_kappav, realw* h_muv,
                                             int* num_phase_ispec_elastic,
                                             int* phase_ispec_inner_elastic,
                                             int* ispec_is_elastic,
                                             realw* b_absorb_field, int* b_reclen_field,
                                             int* COMPUTE_AND_STORE_STRAIN,
                                             realw* epsilondev_xx,realw* epsilondev_yy,realw* epsilondev_xy,
                                             realw* epsilondev_xz,realw* epsilondev_yz,
                                             int* ATTENUATION,
                                             int* R_size,
                                             realw* R_xx,realw* R_yy,realw* R_xy,realw* R_xz,realw* R_yz,
                                             realw* factor_common,
                                             realw* R_trace,realw* epsilondev_trace,
                                             realw* factor_common_kappa,
                                             realw* alphaval,realw* betaval,realw* gammaval,
                                             int* APPROXIMATE_OCEAN_LOAD,
                                             realw* rmass_ocean_load,
                                             int* NOISE_TOMOGRAPHY,
                                             realw* free_surface_normal,
                                             int* free_surface_ispec,
                                             int* free_surface_ijk,
                                             int* num_free_surface_faces,
                                             int* ACOUSTIC_SIMULATION,
                                             int* num_colors_outer_elastic,
                                             int* num_colors_inner_elastic,
                                             int* num_elem_colors_elastic,
                                             int* ANISOTROPY,
                                             realw *c11store,realw *c12store,realw *c13store,
                                             realw *c14store,realw *c15store,realw *c16store,
                                             realw *c22store,realw *c23store,realw *c24store,
                                             realw *c25store,realw *c26store,realw *c33store,
                                             realw *c34store,realw *c35store,realw *c36store,
                                             realw *c44store,realw *c45store,realw *c46store,
                                             realw *c55store,realw *c56store,realw *c66store ){

  TRACE("prepare_fields_elastic_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);
  int size;

  // debug
  //printf("prepare_fields_elastic_device: rank %d - wavefield setup\n",mp->myrank);
  //synchronize_mpi();

  // elastic wavefields
  size = NDIM * mp->NGLOB_AB;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_displ),sizeof(realw)*size),4001);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_veloc),sizeof(realw)*size),4002);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_accel),sizeof(realw)*size),4003);
  // initializes values to zero
  //print_CUDA_error_if_any(hipMemset(mp->d_displ,0,sizeof(realw)*size),4007);
  //print_CUDA_error_if_any(hipMemset(mp->d_veloc,0,sizeof(realw)*size),4007);
  //print_CUDA_error_if_any(hipMemset(mp->d_accel,0,sizeof(realw)*size),4007);

  #ifdef USE_TEXTURES_FIELDS
  {
      hipChannelFormatDesc channelDesc = hipCreateChannelDesc<float>();
      print_CUDA_error_if_any(hipBindTexture(0, &d_displ_tex, mp->d_displ, &channelDesc, sizeof(realw)*size), 4001);
      print_CUDA_error_if_any(hipBindTexture(0, &d_veloc_tex, mp->d_veloc, &channelDesc, sizeof(realw)*size), 4002);
      print_CUDA_error_if_any(hipBindTexture(0, &d_accel_tex, mp->d_accel, &channelDesc, sizeof(realw)*size), 4003);
  }
  #endif

  // debug
  //synchronize_mpi();

  // MPI buffer
  mp->size_mpi_buffer = NDIM * (mp->num_interfaces_ext_mesh) * (mp->max_nibool_interfaces_ext_mesh);
  if (mp->size_mpi_buffer > 0){
    // note: Allocate pinned mpi-buffers.
    //       MPI buffers use pinned memory allocated by hipHostMalloc, which
    //       enables the use of asynchronous memory copies from host <-> device
    // send buffer
    print_CUDA_error_if_any(hipHostMalloc((void**)&(mp->h_send_accel_buffer),sizeof(float)*(mp->size_mpi_buffer)),8004);
    //mp->send_buffer = (float*)malloc((mp->size_mpi_buffer)*sizeof(float));
    // adjoint
    //print_CUDA_error_if_any(hipHostMalloc((void**)&(mp->h_send_b_accel_buffer),sizeof(float)*(mp->size_mpi_buffer)),8004);
    // mp->b_send_buffer = (float*)malloc((size_mpi_buffer)*sizeof(float));
    // receive buffer
    print_CUDA_error_if_any(hipHostMalloc((void**)&(mp->h_recv_accel_buffer),sizeof(float)*(mp->size_mpi_buffer)),8004);
    mp->recv_buffer = (float*)malloc((mp->size_mpi_buffer)*sizeof(float));

    // non-pinned buffer
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_send_accel_buffer),mp->size_mpi_buffer*sizeof(realw)),4004);
    // adjoint
    if (mp->simulation_type == 3){
      print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_send_accel_buffer),mp->size_mpi_buffer*sizeof(realw)),4004);
    }
  }

  // debug
  //printf("prepare_fields_elastic_device: rank %d - mass matrix\n",mp->myrank);
  //synchronize_mpi();

  // mass matrix
  copy_todevice_realw((void**)&mp->d_rmassx,rmassx,mp->NGLOB_AB);
  copy_todevice_realw((void**)&mp->d_rmassy,rmassy,mp->NGLOB_AB);
  copy_todevice_realw((void**)&mp->d_rmassz,rmassz,mp->NGLOB_AB);

  // element indices
  copy_todevice_int((void**)&mp->d_ispec_is_elastic,ispec_is_elastic,mp->NSPEC_AB);

  // phase elements
  mp->num_phase_ispec_elastic = *num_phase_ispec_elastic;

  copy_todevice_int((void**)&mp->d_phase_ispec_inner_elastic,phase_ispec_inner_elastic,2*mp->num_phase_ispec_elastic);

  // debug
  //synchronize_mpi();

  // absorbing conditions
  if (mp->absorbing_conditions && mp->d_num_abs_boundary_faces > 0){

    // debug
    //printf("prepare_fields_elastic_device: rank %d - absorbing boundary setup\n",mp->myrank);

    // non-padded arrays
    // rho_vp, rho_vs non-padded; they are needed for stacey boundary condition
    copy_todevice_realw((void**)&mp->d_rho_vp,rho_vp,NGLL3*mp->NSPEC_AB);
    copy_todevice_realw((void**)&mp->d_rho_vs,rho_vs,NGLL3*mp->NSPEC_AB);

    // absorb_field array used for file i/o
    if (mp->simulation_type == 3 || ( mp->simulation_type == 1 && mp->save_forward )){
      // note: b_reclen_field is length in bytes already (CUSTOM_REAL * NDIM * NGLLSQUARE * num_abs_boundary_faces )
      mp->d_b_reclen_field = *b_reclen_field;

      // debug
      //printf("prepare_fields_elastic_device: rank %d - absorbing boundary i/o %d\n",mp->myrank,mp->d_b_reclen_field);

      print_CUDA_error_if_any(hipMalloc((void**)&mp->d_b_absorb_field,mp->d_b_reclen_field),4101);
      print_CUDA_error_if_any(hipMemcpy(mp->d_b_absorb_field,b_absorb_field,mp->d_b_reclen_field,hipMemcpyHostToDevice),4102);

    }
  }
  int size_padded = NGLL3_PADDED*mp->NSPEC_AB;
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_kappav, size_padded*sizeof(realw)),1010);
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_muv, size_padded*sizeof(realw)),1011);
  print_CUDA_error_if_any(hipMemcpy2D(mp->d_kappav, NGLL3_PADDED*sizeof(realw),
                                       h_kappav, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                       mp->NSPEC_AB, hipMemcpyHostToDevice),1510);
  print_CUDA_error_if_any(hipMemcpy2D(mp->d_muv, NGLL3_PADDED*sizeof(realw),
                                       h_muv, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                       mp->NSPEC_AB, hipMemcpyHostToDevice),1511);

  // debug
  //synchronize_mpi();

  // strains used for attenuation and kernel simulations
  if (*COMPUTE_AND_STORE_STRAIN ){
    // debug
    //printf("prepare_fields_elastic_device: rank %d - strain setup\n",mp->myrank);
    //synchronize_mpi();

    // strains
    size = NGLL3 * mp->NSPEC_AB; // note: non-aligned; if align, check memcpy below and indexing
    copy_todevice_realw((void**)&mp->d_epsilondev_xx,epsilondev_xx,size);
    copy_todevice_realw((void**)&mp->d_epsilondev_yy,epsilondev_yy,size);
    copy_todevice_realw((void**)&mp->d_epsilondev_xy,epsilondev_xy,size);
    copy_todevice_realw((void**)&mp->d_epsilondev_xz,epsilondev_xz,size);
    copy_todevice_realw((void**)&mp->d_epsilondev_yz,epsilondev_yz,size);
    copy_todevice_realw((void**)&mp->d_epsilondev_trace,epsilondev_trace,size);
  }

  // attenuation memory variables
  if (*ATTENUATION ){
    // debug
    //printf("prepare_fields_elastic_device: rank %d - attenuation setup\n",mp->myrank);
    //synchronize_mpi();

    // memory arrays
    size = *R_size;
    copy_todevice_realw((void**)&mp->d_R_xx,R_xx,size);
    copy_todevice_realw((void**)&mp->d_R_yy,R_yy,size);
    copy_todevice_realw((void**)&mp->d_R_xy,R_xy,size);
    copy_todevice_realw((void**)&mp->d_R_xz,R_xz,size);
    copy_todevice_realw((void**)&mp->d_R_yz,R_yz,size);
    copy_todevice_realw((void**)&mp->d_R_trace,R_trace,size);

    // attenuation factors
    copy_todevice_realw((void**)&mp->d_factor_common,factor_common,N_SLS*NGLL3*mp->NSPEC_AB);
    copy_todevice_realw((void**)&mp->d_factor_common_kappa,factor_common_kappa,N_SLS*NGLL3*mp->NSPEC_AB);

    // alpha,beta,gamma factors
    copy_todevice_realw((void**)&mp->d_alphaval,alphaval,N_SLS);
    copy_todevice_realw((void**)&mp->d_betaval,betaval,N_SLS);
    copy_todevice_realw((void**)&mp->d_gammaval,gammaval,N_SLS);
  }

  // anisotropy
  if (*ANISOTROPY ){
    // debug
    //printf("prepare_fields_elastic_device: rank %d - attenuation setup\n",mp->myrank);
    //synchronize_mpi();

    // Assuming NGLLX==5. Padded is then 128 (5^3+3)
    size_padded = NGLL3_PADDED * (mp->NSPEC_AB);

    // allocates memory on GPU
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c11store),size_padded*sizeof(realw)),4700);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c12store),size_padded*sizeof(realw)),4701);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c13store),size_padded*sizeof(realw)),4702);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c14store),size_padded*sizeof(realw)),4703);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c15store),size_padded*sizeof(realw)),4704);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c16store),size_padded*sizeof(realw)),4705);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c22store),size_padded*sizeof(realw)),4706);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c23store),size_padded*sizeof(realw)),4707);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c24store),size_padded*sizeof(realw)),4708);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c25store),size_padded*sizeof(realw)),4709);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c26store),size_padded*sizeof(realw)),4710);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c33store),size_padded*sizeof(realw)),4711);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c34store),size_padded*sizeof(realw)),4712);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c35store),size_padded*sizeof(realw)),4713);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c36store),size_padded*sizeof(realw)),4714);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c44store),size_padded*sizeof(realw)),4715);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c45store),size_padded*sizeof(realw)),4716);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c46store),size_padded*sizeof(realw)),4717);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c55store),size_padded*sizeof(realw)),4718);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c56store),size_padded*sizeof(realw)),4719);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_c66store),size_padded*sizeof(realw)),4720);

    // transfer constant element data with padding
    /*
    // way 1: slower ...
    for(int i=0;i < mp->NSPEC_AB;i++) {
      print_CUDA_error_if_any(hipMemcpy(mp->d_c11store + i*NGLL3_PADDED, &c11store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4800);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c12store + i*NGLL3_PADDED, &c12store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4801);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c13store + i*NGLL3_PADDED, &c13store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4802);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c14store + i*NGLL3_PADDED, &c14store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4803);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c15store + i*NGLL3_PADDED, &c15store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4804);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c16store + i*NGLL3_PADDED, &c16store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4805);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c22store + i*NGLL3_PADDED, &c22store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4806);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c23store + i*NGLL3_PADDED, &c23store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4807);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c24store + i*NGLL3_PADDED, &c24store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4808);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c25store + i*NGLL3_PADDED, &c25store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4809);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c26store + i*NGLL3_PADDED, &c26store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4810);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c33store + i*NGLL3_PADDED, &c33store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4811);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c34store + i*NGLL3_PADDED, &c34store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4812);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c35store + i*NGLL3_PADDED, &c35store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4813);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c36store + i*NGLL3_PADDED, &c36store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4814);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c44store + i*NGLL3_PADDED, &c44store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4815);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c45store + i*NGLL3_PADDED, &c45store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4816);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c46store + i*NGLL3_PADDED, &c46store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4817);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c55store + i*NGLL3_PADDED, &c55store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4818);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c56store + i*NGLL3_PADDED, &c56store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4819);
      print_CUDA_error_if_any(hipMemcpy(mp->d_c66store + i*NGLL3_PADDED, &c66store[i*NGLL3],
                                         NGLL3*sizeof(realw),hipMemcpyHostToDevice),4820);
    }
    */
    // way 2: faster ...
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c11store, NGLL3_PADDED*sizeof(realw),
                                         c11store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c12store, NGLL3_PADDED*sizeof(realw),
                                         c12store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c13store, NGLL3_PADDED*sizeof(realw),
                                         c13store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c14store, NGLL3_PADDED*sizeof(realw),
                                         c14store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c15store, NGLL3_PADDED*sizeof(realw),
                                         c15store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c16store, NGLL3_PADDED*sizeof(realw),
                                         c16store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c22store, NGLL3_PADDED*sizeof(realw),
                                         c22store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c23store, NGLL3_PADDED*sizeof(realw),
                                         c23store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c24store, NGLL3_PADDED*sizeof(realw),
                                         c24store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c25store, NGLL3_PADDED*sizeof(realw),
                                         c25store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c26store, NGLL3_PADDED*sizeof(realw),
                                         c26store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c33store, NGLL3_PADDED*sizeof(realw),
                                         c33store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c34store, NGLL3_PADDED*sizeof(realw),
                                         c34store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c35store, NGLL3_PADDED*sizeof(realw),
                                         c35store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c36store, NGLL3_PADDED*sizeof(realw),
                                         c36store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c44store, NGLL3_PADDED*sizeof(realw),
                                         c44store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c45store, NGLL3_PADDED*sizeof(realw),
                                         c45store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c46store, NGLL3_PADDED*sizeof(realw),
                                         c46store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c55store, NGLL3_PADDED*sizeof(realw),
                                         c55store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c56store, NGLL3_PADDED*sizeof(realw),
                                         c56store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    print_CUDA_error_if_any(hipMemcpy2D(mp->d_c66store, NGLL3_PADDED*sizeof(realw),
                                         c66store, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                         mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
  }

  // ocean load approximation
  if (*APPROXIMATE_OCEAN_LOAD ){
    // debug
    //printf("prepare_fields_elastic_device: rank %d - ocean load setup\n",mp->myrank);
    //synchronize_mpi();

    // oceans needs a free surface
    mp->num_free_surface_faces = *num_free_surface_faces;
    if (mp->num_free_surface_faces > 0){
      // mass matrix
      copy_todevice_realw((void**)&mp->d_rmass_ocean_load,rmass_ocean_load,mp->NGLOB_AB);
      // surface normal
      copy_todevice_realw((void**)&mp->d_free_surface_normal,free_surface_normal,
                          3*NGLL2*(mp->num_free_surface_faces));
      // temporary global array: used to synchronize updates on global accel array
      print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_updated_dof_ocean_load),
                                         sizeof(int)*mp->NGLOB_AB),4505);

      if (*NOISE_TOMOGRAPHY == 0 && *ACOUSTIC_SIMULATION == 0){
        copy_todevice_int((void**)&mp->d_free_surface_ispec,free_surface_ispec,mp->num_free_surface_faces);
        copy_todevice_int((void**)&mp->d_free_surface_ijk,free_surface_ijk,
                          3*NGLL2*mp->num_free_surface_faces);
      }
    }
  }

  // mesh coloring
  if (mp->use_mesh_coloring_gpu ){
    mp->num_colors_outer_elastic = *num_colors_outer_elastic;
    mp->num_colors_inner_elastic = *num_colors_inner_elastic;
    mp->h_num_elem_colors_elastic = (int*) num_elem_colors_elastic;
  }

  // JC JC here we will need to add GPU support for the new C-PML routines

  // debug
  //printf("prepare_fields_elastic_device: rank %d - done\n",mp->myrank);
  //synchronize_mpi();

  GPU_ERROR_CHECKING("prepare_fields_elastic_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_elastic_adj_dev,
              PREPARE_FIELDS_ELASTIC_ADJ_DEV)(long* Mesh_pointer,
                                             int* size_f,
                                             int* COMPUTE_AND_STORE_STRAIN,
                                             realw* epsilon_trace_over_3,
                                             realw* b_epsilondev_xx,realw* b_epsilondev_yy,realw* b_epsilondev_xy,
                                             realw* b_epsilondev_xz,realw* b_epsilondev_yz,
                                             realw* b_epsilon_trace_over_3,
                                             int* ATTENUATION,
                                             int* R_size,
                                             realw* b_R_xx,realw* b_R_yy,realw* b_R_xy,realw* b_R_xz,realw* b_R_yz,
                                             realw* b_R_trace,realw* b_epsilondev_trace,
                                             realw* b_alphaval,realw* b_betaval,realw* b_gammaval,
                                             int* ANISOTROPIC_KL,
                                             int* APPROXIMATE_HESS_KL){

  TRACE("prepare_fields_elastic_adj_dev");

  Mesh* mp = (Mesh*)(*Mesh_pointer);
  int size;

  // checks if kernel simulation
  if (mp->simulation_type != 3) return;

  // kernel simulations
  // debug
  //printf("prepare_fields_elastic_adj_dev: rank %d - kernel setup\n",mp->myrank);
  //synchronize_mpi();

  // backward/reconstructed wavefields
  // allocates backward/reconstructed arrays on device (GPU)
  size = *size_f;
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_displ),sizeof(realw)*size),5201);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_veloc),sizeof(realw)*size),5202);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_b_accel),sizeof(realw)*size),5203);
  // initializes values to zero
  //print_CUDA_error_if_any(hipMemset(mp->d_b_displ,0,sizeof(realw)*size),5207);
  //print_CUDA_error_if_any(hipMemset(mp->d_b_veloc,0,sizeof(realw)*size),5207);
  //print_CUDA_error_if_any(hipMemset(mp->d_b_accel,0,sizeof(realw)*size),5207);

  #ifdef USE_TEXTURES_FIELDS
  {
      hipChannelFormatDesc channelDesc = hipCreateChannelDesc<float>();
      print_CUDA_error_if_any(hipBindTexture(0, &d_b_displ_tex, mp->d_b_displ, &channelDesc, sizeof(realw)*size), 4001);
      print_CUDA_error_if_any(hipBindTexture(0, &d_b_veloc_tex, mp->d_b_veloc, &channelDesc, sizeof(realw)*size), 4002);
      print_CUDA_error_if_any(hipBindTexture(0, &d_b_accel_tex, mp->d_b_accel, &channelDesc, sizeof(realw)*size), 4003);
  }
  #endif


  // anisotropic kernel flag
  mp->anisotropic_kl = *ANISOTROPIC_KL;

  // anisotropic/isotropic kernels
  // debug
  //printf("prepare_fields_elastic_adj_dev: rank %d -  anisotropic/isotropic kernels\n",mp->myrank);
  //synchronize_mpi();

  // allocates kernels
  size = NGLL3 * mp->NSPEC_AB; // note: non-aligned; if align, check memcpy below and indexing
  // density kernel
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_rho_kl),size*sizeof(realw)),5204);
  // initializes kernel values to zero
  print_CUDA_error_if_any(hipMemset(mp->d_rho_kl,0,size*sizeof(realw)),5214);

  if (mp->anisotropic_kl ){
    // anisotropic kernels
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_cijkl_kl),21*size*sizeof(realw)),5205);
    print_CUDA_error_if_any(hipMemset(mp->d_cijkl_kl,0,21*size*sizeof(realw)),5215);

  }else{
    // isotropic kernels
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_mu_kl),size*sizeof(realw)),5206);
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_kappa_kl),size*sizeof(realw)),5207);
    print_CUDA_error_if_any(hipMemset(mp->d_mu_kl,0,size*sizeof(realw)),5216);
    print_CUDA_error_if_any(hipMemset(mp->d_kappa_kl,0,size*sizeof(realw)),5217);
  }

  // strains used for attenuation and kernel simulations
  if (*COMPUTE_AND_STORE_STRAIN ){
    // strains
    // debug
    //printf("prepare_fields_elastic_adj_dev: rank %d - strains\n",mp->myrank);
    //synchronize_mpi();

    size = NGLL3 * mp->NSPEC_AB; // note: non-aligned; if align, check memcpy below and indexing

    // solid pressure
    copy_todevice_realw((void**)&mp->d_epsilon_trace_over_3,epsilon_trace_over_3,size);

    // backward solid pressure
    copy_todevice_realw((void**)&mp->d_b_epsilon_trace_over_3,b_epsilon_trace_over_3,size);

    // prepares backward strains
    copy_todevice_realw((void**)&mp->d_b_epsilondev_xx,b_epsilondev_xx,size);
    copy_todevice_realw((void**)&mp->d_b_epsilondev_yy,b_epsilondev_yy,size);
    copy_todevice_realw((void**)&mp->d_b_epsilondev_xy,b_epsilondev_xy,size);
    copy_todevice_realw((void**)&mp->d_b_epsilondev_xz,b_epsilondev_xz,size);
    copy_todevice_realw((void**)&mp->d_b_epsilondev_yz,b_epsilondev_yz,size);
    copy_todevice_realw((void**)&mp->d_b_epsilondev_trace,b_epsilondev_trace,size);
  }

  // attenuation memory variables
  if (*ATTENUATION ){
    // debug
    //printf("prepare_fields_elastic_adj_dev: rank %d - attenuation\n",mp->myrank);
    //synchronize_mpi();

    size = *R_size;

    copy_todevice_realw((void**)&mp->d_b_R_xx,b_R_xx,size);
    copy_todevice_realw((void**)&mp->d_b_R_yy,b_R_yy,size);
    copy_todevice_realw((void**)&mp->d_b_R_xy,b_R_xy,size);
    copy_todevice_realw((void**)&mp->d_b_R_xz,b_R_xz,size);
    copy_todevice_realw((void**)&mp->d_b_R_yz,b_R_yz,size);
    copy_todevice_realw((void**)&mp->d_b_R_trace,b_R_trace,size);

    // alpha,beta,gamma factors for backward fields
    copy_todevice_realw((void**)&mp->d_b_alphaval,b_alphaval,N_SLS);
    copy_todevice_realw((void**)&mp->d_b_betaval,b_betaval,N_SLS);
    copy_todevice_realw((void**)&mp->d_b_gammaval,b_gammaval,N_SLS);
  }

  // approximate hessian kernel
  if (*APPROXIMATE_HESS_KL ){
    // debug
    //printf("prepare_fields_elastic_adj_dev: rank %d - hessian kernel\n",mp->myrank);
    //synchronize_mpi();

    size = NGLL3 * mp->NSPEC_AB; // note: non-aligned; if align, check memcpy below and indexing
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_el_kl),size*sizeof(realw)),5450);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_el_kl,0,size*sizeof(realw)),5451);

    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_rho_el_kl),size*sizeof(realw)),5452);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_rho_el_kl,0,size*sizeof(realw)),5453);

    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_kappa_el_kl),size*sizeof(realw)),5454);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_kappa_el_kl,0,size*sizeof(realw)),5455);

    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hess_mu_el_kl),size*sizeof(realw)),5456);
    print_CUDA_error_if_any(hipMemset(mp->d_hess_mu_el_kl,0,size*sizeof(realw)),5457);
  }

  // debug
  //printf("prepare_fields_elastic_adj_dev: rank %d - done\n",mp->myrank);
  //synchronize_mpi();

  GPU_ERROR_CHECKING("prepare_fields_elastic_adj_dev");
}

/* ----------------------------------------------------------------------------------------------- */

// purely adjoint & kernel simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_sim2_or_3_const_device,
              PREPARE_SIM2_OR_3_CONST_DEVICE)(long* Mesh_pointer,int *nadj_rec_local, int* NTSTEP_BETWEEN_READ_ADJSRC) {

  TRACE("prepare_sim2_or_3_const_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);

  // adjoint source arrays
  mp->nadj_rec_local = *nadj_rec_local;
  if (mp->nadj_rec_local > 0){
    print_CUDA_error_if_any(hipMalloc((void**)&mp->d_source_adjoint,
                                       (mp->nadj_rec_local)* NDIM * sizeof(field) * (*NTSTEP_BETWEEN_READ_ADJSRC)),6005);
  }

  GPU_ERROR_CHECKING("prepare_sim2_or_3_const_device");
}


/* ----------------------------------------------------------------------------------------------- */

// for NOISE simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_noise_device,
              PREPARE_FIELDS_NOISE_DEVICE)(long* Mesh_pointer,
                                           int* NSPEC_AB, int* NGLOB_AB,
                                           int* free_surface_ispec,
                                           int* free_surface_ijk,
                                           int* num_free_surface_faces,
                                           int* NOISE_TOMOGRAPHY,
                                           int* NSTEP,
                                           realw* noise_sourcearray,
                                           realw* normal_x_noise, realw* normal_y_noise, realw* normal_z_noise,
                                           realw* mask_noise,
                                           realw* free_surface_jacobian2Dw) {

  TRACE("prepare_fields_noise_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);

  // free surface
  mp->num_free_surface_faces = *num_free_surface_faces;

  copy_todevice_int((void**)&mp->d_free_surface_ispec,free_surface_ispec,mp->num_free_surface_faces);
  copy_todevice_int((void**)&mp->d_free_surface_ijk,free_surface_ijk,
                    3*NGLL2*mp->num_free_surface_faces);

  // alloc storage for the surface buffer to be copied
  print_CUDA_error_if_any(hipMalloc((void**) &mp->d_noise_surface_movie,
                                     3*NGLL2*mp->num_free_surface_faces*sizeof(realw)),7005);

  // prepares noise source array
  if (*NOISE_TOMOGRAPHY == 1){
    copy_todevice_realw((void**)&mp->d_noise_sourcearray,noise_sourcearray,
                        3*NGLL3*(*NSTEP));
  }

  // prepares noise directions
  if (*NOISE_TOMOGRAPHY > 1){
    int nface_size = NGLL2*(*num_free_surface_faces);
    // allocates memory on GPU
    copy_todevice_realw((void**)&mp->d_normal_x_noise,normal_x_noise,nface_size);
    copy_todevice_realw((void**)&mp->d_normal_y_noise,normal_y_noise,nface_size);
    copy_todevice_realw((void**)&mp->d_normal_z_noise,normal_z_noise,nface_size);
    copy_todevice_realw((void**)&mp->d_mask_noise,mask_noise,nface_size);
    copy_todevice_realw((void**)&mp->d_free_surface_jacobian2Dw,free_surface_jacobian2Dw,nface_size);
  }

  // prepares noise strength kernel
  if (*NOISE_TOMOGRAPHY == 3){
    print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_sigma_kl),NGLL3*(mp->NSPEC_AB)*sizeof(realw)),7401);
    // initializes kernel values to zero
    print_CUDA_error_if_any(hipMemset(mp->d_sigma_kl,0,NGLL3*mp->NSPEC_AB*sizeof(realw)),7403);
  }

  //printf("jacobian_size = %d\n",25*(*num_free_surface_faces));
  GPU_ERROR_CHECKING("prepare_fields_noise_device");
}

/* ----------------------------------------------------------------------------------------------- */

// GRAVITY simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fields_gravity_device,
              PREPARE_FIELDS_gravity_DEVICE)(long* Mesh_pointer,
                                             int* GRAVITY,
                                             realw* minus_deriv_gravity,
                                             realw* minus_g,
                                             realw* h_wgll_cube,
                                             int* ACOUSTIC_SIMULATION,
                                             realw* rhostore) {

  TRACE("prepare_fields_gravity_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);

  setConst_wgll_cube(h_wgll_cube,mp);

  mp->gravity = *GRAVITY;
  if (mp->gravity ){

    copy_todevice_realw((void**)&mp->d_minus_deriv_gravity,minus_deriv_gravity,mp->NGLOB_AB);
    copy_todevice_realw((void**)&mp->d_minus_g,minus_g,mp->NGLOB_AB);

    if (*ACOUSTIC_SIMULATION == 0){
      // density
      // rhostore not allocated yet
      int size_padded = NGLL3_PADDED * (mp->NSPEC_AB);
      // padded array
      print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_rhostore),size_padded*sizeof(realw)),8006);
      // transfer constant element data with padding
      /*
      // way 1: slower ...
      for(int i=0; i < mp->NSPEC_AB; i++) {
        print_CUDA_error_if_any(hipMemcpy(mp->d_rhostore+i*NGLL3_PADDED, &rhostore[i*NGLL3],
                                           NGLL3*sizeof(realw),hipMemcpyHostToDevice),8007);
      }
      */
      // way 2: faster...
      print_CUDA_error_if_any(hipMemcpy2D(mp->d_rhostore, NGLL3_PADDED*sizeof(realw),
                                           rhostore, NGLL3*sizeof(realw), NGLL3*sizeof(realw),
                                           mp->NSPEC_AB, hipMemcpyHostToDevice),4800);
    }
  }

  GPU_ERROR_CHECKING("prepare_fields_gravity_device");
}

/* ----------------------------------------------------------------------------------------------- */

// unused yet...

/*
extern "C"
void FC_FUNC_(prepare_seismogram_fields,
              PREPARE_SEISMOGRAM_FIELDS)(long* Mesh_pointer,int* nrec_local, double* nu_rec, double* hxir, double* hetar, double* hgammar) {

  TRACE("prepare_constants_device");
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_nu_rec),3*3*(*nrec_local)*sizeof(double)),8100);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hxir),5*(*nrec_local)*sizeof(double)),8100);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hetar),5*(*nrec_local)*sizeof(double)),8100);
  print_CUDA_error_if_any(hipMalloc((void**)&(mp->d_hgammar),5*(*nrec_local)*sizeof(double)),8100);

  print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_d,3*(*nrec_local)*sizeof(realw)),8101);
  print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_v,3*(*nrec_local)*sizeof(realw)),8101);
  print_CUDA_error_if_any(hipMalloc((void**)&mp->d_seismograms_a,3*(*nrec_local)*sizeof(realw)),8101);

  print_CUDA_error_if_any(hipMemcpy(mp->d_nu_rec,nu_rec,3*3*(*nrec_local)*sizeof(double),hipMemcpyHostToDevice),8101);
  print_CUDA_error_if_any(hipMemcpy(mp->d_hxir,hxir,5*(*nrec_local)*sizeof(double),hipMemcpyHostToDevice),8101);
  print_CUDA_error_if_any(hipMemcpy(mp->d_hetar,hetar,5*(*nrec_local)*sizeof(double),hipMemcpyHostToDevice),8101);
  print_CUDA_error_if_any(hipMemcpy(mp->d_hgammar,hgammar,5*(*nrec_local)*sizeof(double),hipMemcpyHostToDevice),8101);

  hipHostMalloc((void**)&mp->h_seismograms_d_it,3**nrec_local*sizeof(realw));
  hipHostMalloc((void**)&mp->h_seismograms_v_it,3**nrec_local*sizeof(realw));
  hipHostMalloc((void**)&mp->h_seismograms_a_it,3**nrec_local*sizeof(realw));
}
*/





/* ----------------------------------------------------------------------------------------------- */

// FAULT simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_fault_device,
              PREPARE_FAULT_DEVICE)(long* Mesh_pointer,
                                    int* KELVIN_VOIGT_DAMPING,
//                            int* testtrue,
                                    realw* Kelvin_Voigt_eta) {

  TRACE("prepare_fault_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer);
  mp -> Kelvin_Voigt_damping = *KELVIN_VOIGT_DAMPING ;
  if (mp-> Kelvin_Voigt_damping ){
//    if(*testtrue) printf("\ntesttrue!\n");
//    if(! (*KELVIN_VOIGT_DAMPING)) printf("\nKV test pass!\n");
//    printf("myrank = %d , size of damping = %6d, isAllocated? = %d\n",mp->myrank,sizeof(Kelvin_Voigt_eta),mp -> Kelvin_Voigt_damping);
    copy_todevice_realw((void**)&mp->d_Kelvin_Voigt_eta,Kelvin_Voigt_eta,mp-> NSPEC_AB);
  }
}


/* ----------------------------------------------------------------------------------------------- */

// cleanup

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(prepare_cleanup_device,
              PREPARE_CLEANUP_DEVICE)(long* Mesh_pointer,
                                      int* ACOUSTIC_SIMULATION,
                                      int* ELASTIC_SIMULATION,
                                      int* ABSORBING_CONDITIONS,
                                      int* NOISE_TOMOGRAPHY,
                                      int* COMPUTE_AND_STORE_STRAIN,
                                      int* ATTENUATION,
                                      int* ANISOTROPY,
                                      int* APPROXIMATE_OCEAN_LOAD,
                                      int* APPROXIMATE_HESS_KL) {

TRACE("prepare_cleanup_device");

  // frees allocated memory arrays
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  hipFree(mp->d_irregular_element_number);

  // frees memory on GPU
  // mesh
  hipFree(mp->d_xix);
  hipFree(mp->d_xiy);
  hipFree(mp->d_xiz);
  hipFree(mp->d_etax);
  hipFree(mp->d_etay);
  hipFree(mp->d_etaz);
  hipFree(mp->d_gammax);
  hipFree(mp->d_gammay);
  hipFree(mp->d_gammaz);

  // absorbing boundaries
  if (*ABSORBING_CONDITIONS && mp->d_num_abs_boundary_faces > 0){
    hipFree(mp->d_abs_boundary_ispec);
    hipFree(mp->d_abs_boundary_ijk);
    hipFree(mp->d_abs_boundary_normal);
    hipFree(mp->d_abs_boundary_jacobian2Dw);
  }

  // interfaces
  if (mp->num_interfaces_ext_mesh > 0){
    hipFree(mp->d_nibool_interfaces_ext_mesh);
    hipFree(mp->d_ibool_interfaces_ext_mesh);
  }

  // global indexing
  hipFree(mp->d_ispec_is_inner);
  hipFree(mp->d_ibool);

  // sources
  if (mp->simulation_type == 1  || mp->simulation_type == 3){
    hipFree(mp->d_sourcearrays);
    hipFree(mp->d_stf_pre_compute);
  }

  hipFree(mp->d_islice_selected_source);
  hipFree(mp->d_ispec_selected_source);

  // receivers
  if (mp->nrec_local > 0){
    hipFree(mp->d_hxir);
    hipFree(mp->d_hetar);
    hipFree(mp->d_hgammar);
    if (mp->save_seismograms_d) hipFree(mp->d_seismograms_d);
    if (mp->save_seismograms_v) hipFree(mp->d_seismograms_v);
    if (mp->save_seismograms_a) hipFree(mp->d_seismograms_a);
    if (mp->save_seismograms_p) hipFree(mp->d_seismograms_p);
    hipFree(mp->d_nu_rec);
    hipFree(mp->d_ispec_selected_rec_loc);
    }
    hipFree(mp->d_ispec_selected_rec);

  // ACOUSTIC arrays
  if (*ACOUSTIC_SIMULATION ){
    hipFree(mp->d_potential_acoustic);
    hipFree(mp->d_potential_dot_acoustic);
    hipFree(mp->d_potential_dot_dot_acoustic);
    hipFree(mp->d_send_potential_dot_dot_buffer);
    hipFree(mp->d_rmass_acoustic);
    hipFree(mp->d_rhostore);
    hipFree(mp->d_kappastore);
    hipFree(mp->d_phase_ispec_inner_acoustic);
    hipFree(mp->d_ispec_is_acoustic);

    if (*NOISE_TOMOGRAPHY == 0){
      hipFree(mp->d_free_surface_ispec);
      hipFree(mp->d_free_surface_ijk);
    }

    if (*ABSORBING_CONDITIONS) hipFree(mp->d_b_absorb_potential);

    if (mp->simulation_type == 3) {
      hipFree(mp->d_b_potential_acoustic);
      hipFree(mp->d_b_potential_dot_acoustic);
      hipFree(mp->d_b_potential_dot_dot_acoustic);
      hipFree(mp->d_rho_ac_kl);
      hipFree(mp->d_kappa_ac_kl);
      if (*APPROXIMATE_HESS_KL) {
        hipFree(mp->d_hess_ac_kl);
        hipFree(mp->d_hess_rho_ac_kl);
        hipFree(mp->d_hess_kappa_ac_kl);
      }
    }

  } // ACOUSTIC_SIMULATION

  // ELASTIC arrays
  if (*ELASTIC_SIMULATION ){
    hipFree(mp->d_displ);
    hipFree(mp->d_veloc);
    hipFree(mp->d_accel);

    hipFree(mp->d_send_accel_buffer);
    if (mp->simulation_type == 3) hipFree(mp->d_b_send_accel_buffer);

    hipFree(mp->d_rmassx);
    hipFree(mp->d_rmassy);
    hipFree(mp->d_rmassz);

    hipFree(mp->d_phase_ispec_inner_elastic);
    hipFree(mp->d_ispec_is_elastic);

    if (*ABSORBING_CONDITIONS && mp->d_num_abs_boundary_faces > 0){
      hipFree(mp->d_rho_vp);
      hipFree(mp->d_rho_vs);

      if (mp->simulation_type == 3 || ( mp->simulation_type == 1 && mp->save_forward ))
          hipFree(mp->d_b_absorb_field);
    }

    hipFree(mp->d_kappav);
    hipFree(mp->d_muv);

    if (mp->simulation_type == 3) {
      hipFree(mp->d_b_displ);
      hipFree(mp->d_b_veloc);
      hipFree(mp->d_b_accel);
      hipFree(mp->d_rho_kl);
      if (mp->anisotropic_kl ){
        hipFree(mp->d_cijkl_kl);
      }else{
        hipFree(mp->d_mu_kl);
        hipFree(mp->d_kappa_kl);
      }
      if (*APPROXIMATE_HESS_KL) {
        hipFree(mp->d_hess_el_kl);
        hipFree(mp->d_hess_rho_el_kl);
        hipFree(mp->d_hess_kappa_el_kl);
        hipFree(mp->d_hess_mu_el_kl);
      }
    }

    if (*COMPUTE_AND_STORE_STRAIN ){
      hipFree(mp->d_epsilondev_xx);
      hipFree(mp->d_epsilondev_yy);
      hipFree(mp->d_epsilondev_xy);
      hipFree(mp->d_epsilondev_xz);
      hipFree(mp->d_epsilondev_yz);
      hipFree(mp->d_epsilondev_trace);
      if (mp->simulation_type == 3){
        hipFree(mp->d_epsilon_trace_over_3);
        hipFree(mp->d_b_epsilon_trace_over_3);
        hipFree(mp->d_b_epsilondev_xx);
        hipFree(mp->d_b_epsilondev_yy);
        hipFree(mp->d_b_epsilondev_xy);
        hipFree(mp->d_b_epsilondev_xz);
        hipFree(mp->d_b_epsilondev_yz);
        hipFree(mp->d_b_epsilondev_trace);
      }
    }

    if (*ATTENUATION ){
      hipFree(mp->d_factor_common);
      hipFree(mp->d_factor_common_kappa);
      hipFree(mp->d_alphaval);
      hipFree(mp->d_betaval);
      hipFree(mp->d_gammaval);
      hipFree(mp->d_R_xx);
      hipFree(mp->d_R_yy);
      hipFree(mp->d_R_xy);
      hipFree(mp->d_R_xz);
      hipFree(mp->d_R_yz);
      hipFree(mp->d_R_trace);
      if (mp->simulation_type == 3){
        hipFree(mp->d_b_R_xx);
        hipFree(mp->d_b_R_yy);
        hipFree(mp->d_b_R_xy);
        hipFree(mp->d_b_R_xz);
        hipFree(mp->d_b_R_yz);
        hipFree(mp->d_b_R_trace);
        hipFree(mp->d_b_alphaval);
        hipFree(mp->d_b_betaval);
        hipFree(mp->d_b_gammaval);
      }
    }

    if (*ANISOTROPY ){
      hipFree(mp->d_c11store);
      hipFree(mp->d_c12store);
      hipFree(mp->d_c13store);
      hipFree(mp->d_c14store);
      hipFree(mp->d_c15store);
      hipFree(mp->d_c16store);
      hipFree(mp->d_c22store);
      hipFree(mp->d_c23store);
      hipFree(mp->d_c24store);
      hipFree(mp->d_c25store);
      hipFree(mp->d_c26store);
      hipFree(mp->d_c33store);
      hipFree(mp->d_c34store);
      hipFree(mp->d_c35store);
      hipFree(mp->d_c36store);
      hipFree(mp->d_c44store);
      hipFree(mp->d_c45store);
      hipFree(mp->d_c46store);
      hipFree(mp->d_c55store);
      hipFree(mp->d_c56store);
      hipFree(mp->d_c66store);
    }

    if (*APPROXIMATE_OCEAN_LOAD ){
      if (mp->num_free_surface_faces > 0){
        hipFree(mp->d_rmass_ocean_load);
        hipFree(mp->d_free_surface_normal);
        hipFree(mp->d_updated_dof_ocean_load);
        if (*NOISE_TOMOGRAPHY == 0){
          hipFree(mp->d_free_surface_ispec);
          hipFree(mp->d_free_surface_ijk);
        }
      }
    }
  } // ELASTIC_SIMULATION

  // purely adjoint & kernel array
  if (mp->simulation_type == 2 || mp->simulation_type == 3){
    if (mp->nadj_rec_local > 0){
      hipFree(mp->d_source_adjoint);
    }
  }

  // NOISE arrays
  if (*NOISE_TOMOGRAPHY > 0){
    hipFree(mp->d_free_surface_ispec);
    hipFree(mp->d_free_surface_ijk);
    hipFree(mp->d_noise_surface_movie);
    if (*NOISE_TOMOGRAPHY == 1) hipFree(mp->d_noise_sourcearray);
    if (*NOISE_TOMOGRAPHY > 1){
      hipFree(mp->d_normal_x_noise);
      hipFree(mp->d_normal_y_noise);
      hipFree(mp->d_normal_z_noise);
      hipFree(mp->d_mask_noise);
      hipFree(mp->d_free_surface_jacobian2Dw);
    }
    if (*NOISE_TOMOGRAPHY == 3) hipFree(mp->d_sigma_kl);
  }

  // mesh pointer - not needed anymore
  free(mp);
}


