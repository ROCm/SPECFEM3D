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

/* ----------------------------------------------------------------------------------------------- */

// Transfer functions

/* ----------------------------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------------------------- */

// for ELASTIC simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_fields_el_to_device,
              TRANSFER_FIELDS_EL_TO_DEVICE)(int* size, realw* displ, realw* veloc, realw* accel,long* Mesh_pointer) {

  TRACE("transfer_fields_el_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_displ,displ,sizeof(realw)*(*size),hipMemcpyHostToDevice),40003);
  print_CUDA_error_if_any(hipMemcpy(mp->d_veloc,veloc,sizeof(realw)*(*size),hipMemcpyHostToDevice),40004);
  print_CUDA_error_if_any(hipMemcpy(mp->d_accel,accel,sizeof(realw)*(*size),hipMemcpyHostToDevice),40005);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_fields_el_from_device,
              TRANSFER_FIELDS_EL_FROM_DEVICE)(int* size, realw* displ, realw* veloc, realw* accel,long* Mesh_pointer) {

  TRACE("transfer_fields_el_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(displ,mp->d_displ,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40006);
  print_CUDA_error_if_any(hipMemcpy(veloc,mp->d_veloc,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40007);
  print_CUDA_error_if_any(hipMemcpy(accel,mp->d_accel,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40008);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_fields_to_device,
              TRANSFER_B_FIELDS_TO_DEVICE)(int* size, realw* b_displ, realw* b_veloc, realw* b_accel,
                                           long* Mesh_pointer) {

  TRACE("transfer_b_fields_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_displ,b_displ,sizeof(realw)*(*size),hipMemcpyHostToDevice),41006);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_veloc,b_veloc,sizeof(realw)*(*size),hipMemcpyHostToDevice),41007);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_accel,b_accel,sizeof(realw)*(*size),hipMemcpyHostToDevice),41008);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_fields_from_device,
              TRANSFER_B_FIELDS_FROM_DEVICE)(int* size, realw* b_displ, realw* b_veloc, realw* b_accel,long* Mesh_pointer) {

  TRACE("transfer_b_fields_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(b_displ,mp->d_b_displ,sizeof(realw)*(*size),hipMemcpyDeviceToHost),42006);
  print_CUDA_error_if_any(hipMemcpy(b_veloc,mp->d_b_veloc,sizeof(realw)*(*size),hipMemcpyDeviceToHost),42007);
  print_CUDA_error_if_any(hipMemcpy(b_accel,mp->d_b_accel,sizeof(realw)*(*size),hipMemcpyDeviceToHost),42008);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_veloc_from_device,
              TRANSFER_VELOC_FROM_DEVICE)(int* size, realw* veloc, long* Mesh_pointer) {

  TRACE("transfer_veloc_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(veloc,mp->d_veloc,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40009);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_veloc_from_device,
              TRNASFER_B_VELOC_FROM_DEVICE)(int* size, realw* b_veloc,long* Mesh_pointer) {

  TRACE("transfer_b_veloc_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(b_veloc,mp->d_b_veloc,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40010);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_veloc_to_device,
              TRANSFER_B_VELOC_TO_DEVICE)(int* size, realw* b_veloc,long* Mesh_pointer) {

  TRACE("transfer_b_veloc_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_veloc,b_veloc,sizeof(realw)*(*size),hipMemcpyHostToDevice),40011);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_accel_to_device,
              TRNASFER_ACCEL_TO_DEVICE)(int* size, realw* accel,long* Mesh_pointer) {

  TRACE("transfer_accel_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_accel,accel,sizeof(realw)*(*size),hipMemcpyHostToDevice),40016);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_accel_from_device,
              TRANSFER_ACCEL_FROM_DEVICE)(int* size, realw* accel,long* Mesh_pointer) {

  TRACE("transfer_accel_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(accel,mp->d_accel,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40026);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_accel_from_device,
              TRNASFER_B_ACCEL_FROM_DEVICE)(int* size, realw* b_accel,long* Mesh_pointer) {

  TRACE("transfer_b_accel_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(b_accel,mp->d_b_accel,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40036);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_accel_to_device,
              TRANSFER_B_accel_to_DEVICE)(int* size, realw* b_accel,long* Mesh_pointer) {

  TRACE("transfer_b_accel_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_accel,b_accel,sizeof(realw)*(*size),hipMemcpyHostToDevice),40057);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_sigma_from_device,
              TRANSFER_SIGMA_FROM_DEVICE)(int* size, realw* sigma_kl,long* Mesh_pointer) {

  TRACE("transfer_sigma_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(sigma_kl,mp->d_sigma_kl,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40046);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_displ_from_device,
              TRANSFER_B_DISPL_FROM_DEVICE)(int* size, realw* b_displ,long* Mesh_pointer) {

  TRACE("transfer_b_displ_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(b_displ,mp->d_b_displ,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40056);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_displ_to_device,
              TRANSFER_B_DISPL_to_DEVICE)(int* size, realw* b_displ,long* Mesh_pointer) {

  TRACE("transfer_b_displ_to_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_displ,b_displ,sizeof(realw)*(*size),hipMemcpyHostToDevice),40057);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_displ_from_device,
              TRANSFER_DISPL_FROM_DEVICE)(int* size, realw* displ,long* Mesh_pointer) {

  TRACE("transfer_displ_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container

  print_CUDA_error_if_any(hipMemcpy(displ,mp->d_displ,sizeof(realw)*(*size),hipMemcpyDeviceToHost),40066);

}

/* ----------------------------------------------------------------------------------------------- */

// attenuation fields

extern "C"
void FC_FUNC_(transfer_b_fields_att_to_device,
              TRANSFER_B_FIELDS_ATT_TO_DEVICE)(long* Mesh_pointer,
                                               realw* b_R_xx,realw* b_R_yy,realw* b_R_xy,
                                               realw* b_R_xz,realw* b_R_yz,
                                               int* size_R,
                                               realw* b_epsilondev_xx,realw* b_epsilondev_yy,realw* b_epsilondev_xy,
                                               realw* b_epsilondev_xz,realw* b_epsilondev_yz,
                                               realw* b_R_trace,realw* b_epsilondev_trace,
                                               int* size_epsilondev) {

  TRACE("transfer_b_fields_att_to_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_xx,b_R_xx,*size_R*sizeof(realw),hipMemcpyHostToDevice),43011);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_yy,b_R_yy,*size_R*sizeof(realw),hipMemcpyHostToDevice),43012);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_xy,b_R_xy,*size_R*sizeof(realw),hipMemcpyHostToDevice),43013);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_xz,b_R_xz,*size_R*sizeof(realw),hipMemcpyHostToDevice),43014);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_yz,b_R_yz,*size_R*sizeof(realw),hipMemcpyHostToDevice),43015);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_R_trace,b_R_trace,*size_R*sizeof(realw),hipMemcpyHostToDevice),43016);

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_xx,b_epsilondev_xx,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43116);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_yy,b_epsilondev_yy,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43117);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_xy,b_epsilondev_xy,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43118);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_xz,b_epsilondev_xz,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43119);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_yz,b_epsilondev_yz,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43120);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_epsilondev_trace,b_epsilondev_trace,*size_epsilondev*sizeof(realw),hipMemcpyHostToDevice),43121);

  GPU_ERROR_CHECKING("after transfer_b_fields_att_to_device");
}

/* ----------------------------------------------------------------------------------------------- */

// attenuation fields

extern "C"
void FC_FUNC_(transfer_fields_att_from_device,
              TRANSFER_FIELDS_ATT_FROM_DEVICE)(long* Mesh_pointer,
                                               realw* R_xx,realw* R_yy,realw* R_xy,realw* R_xz,realw* R_yz,
                                               int* size_R,
                                               realw* epsilondev_xx,realw* epsilondev_yy,realw* epsilondev_xy,
                                               realw* epsilondev_xz,realw* epsilondev_yz,
                                               realw* R_trace,realw* epsilondev_trace,
                                               int* size_epsilondev) {
  TRACE("transfer_fields_att_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(R_xx,mp->d_R_xx,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43021);
  print_CUDA_error_if_any(hipMemcpy(R_yy,mp->d_R_yy,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43022);
  print_CUDA_error_if_any(hipMemcpy(R_xy,mp->d_R_xy,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43023);
  print_CUDA_error_if_any(hipMemcpy(R_xz,mp->d_R_xz,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43024);
  print_CUDA_error_if_any(hipMemcpy(R_yz,mp->d_R_yz,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43025);
  print_CUDA_error_if_any(hipMemcpy(R_trace,mp->d_R_trace,*size_R*sizeof(realw),hipMemcpyDeviceToHost),43026);

  print_CUDA_error_if_any(hipMemcpy(epsilondev_xx,mp->d_epsilondev_xx,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43126);
  print_CUDA_error_if_any(hipMemcpy(epsilondev_yy,mp->d_epsilondev_yy,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43127);
  print_CUDA_error_if_any(hipMemcpy(epsilondev_xy,mp->d_epsilondev_xy,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43128);
  print_CUDA_error_if_any(hipMemcpy(epsilondev_xz,mp->d_epsilondev_xz,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43129);
  print_CUDA_error_if_any(hipMemcpy(epsilondev_yz,mp->d_epsilondev_yz,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43130);
  print_CUDA_error_if_any(hipMemcpy(epsilondev_trace,mp->d_epsilondev_trace,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost),43131);

  GPU_ERROR_CHECKING("after transfer_fields_att_from_device");
}

// JC JC here we will need to add GPU support for the new C-PML routines

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_kernels_el_to_host,
              TRANSFER_KERNELS_EL_TO_HOST)(long* Mesh_pointer,
                                            realw* h_rho_kl,
                                            realw* h_mu_kl,
                                            realw* h_kappa_kl,
                                            realw* h_cijkl_kl,
                                            int* NSPEC_AB) {
  TRACE("transfer_kernels_el_to_host");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(h_rho_kl,mp->d_rho_kl,*NSPEC_AB*NGLL3*sizeof(realw),
                                     hipMemcpyDeviceToHost),40101);
  if (mp->anisotropic_kl ){
    print_CUDA_error_if_any(hipMemcpy(h_cijkl_kl,mp->d_cijkl_kl,*NSPEC_AB*21*NGLL3*sizeof(realw),
                                       hipMemcpyDeviceToHost),40102);
  }else{
    print_CUDA_error_if_any(hipMemcpy(h_mu_kl,mp->d_mu_kl,*NSPEC_AB*NGLL3*sizeof(realw),
                                       hipMemcpyDeviceToHost),40102);
    print_CUDA_error_if_any(hipMemcpy(h_kappa_kl,mp->d_kappa_kl,*NSPEC_AB*NGLL3*sizeof(realw),
                                       hipMemcpyDeviceToHost),40103);
  }
}

/* ----------------------------------------------------------------------------------------------- */

// for NOISE simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_kernels_noise_to_host,
              TRANSFER_KERNELS_NOISE_TO_HOST)(long* Mesh_pointer,
                                              realw* h_sigma_kl,
                                              int* NSPEC_AB) {
  TRACE("transfer_kernels_noise_to_host");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(h_sigma_kl,mp->d_sigma_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),40201);

}


/* ----------------------------------------------------------------------------------------------- */

// for ACOUSTIC simulations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_fields_ac_to_device,
              TRANSFER_FIELDS_AC_TO_DEVICE)(int* size,
                                            field* potential_acoustic,
                                            field* potential_dot_acoustic,
                                            field* potential_dot_dot_acoustic,
                                            long* Mesh_pointer) {

  TRACE("transfer_fields_ac_to_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(mp->d_potential_acoustic,potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),50110);
  print_CUDA_error_if_any(hipMemcpy(mp->d_potential_dot_acoustic,potential_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),50120);
  print_CUDA_error_if_any(hipMemcpy(mp->d_potential_dot_dot_acoustic,potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),50130);

  GPU_ERROR_CHECKING("after transfer_fields_ac_to_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_fields_ac_to_device,
              TRANSFER_B_FIELDS_AC_TO_DEVICE)(int* size,
                                              field* b_potential_acoustic,
                                              field* b_potential_dot_acoustic,
                                              field* b_potential_dot_dot_acoustic,
                                              long* Mesh_pointer) {

  TRACE("transfer_b_fields_ac_to_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_potential_acoustic,b_potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),51110);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_potential_dot_acoustic,b_potential_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),51120);
  print_CUDA_error_if_any(hipMemcpy(mp->d_b_potential_dot_dot_acoustic,b_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),51130);

  GPU_ERROR_CHECKING("after transfer_b_fields_ac_to_device");
}


/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_fields_ac_from_device,
              TRANSFER_FIELDS_AC_FROM_DEVICE)(int* size,
                                              field* potential_acoustic,
                                              field* potential_dot_acoustic,
                                              field* potential_dot_dot_acoustic,
                                              long* Mesh_pointer) {
  TRACE("transfer_fields_ac_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(potential_acoustic,mp->d_potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),52111);
  print_CUDA_error_if_any(hipMemcpy(potential_dot_acoustic,mp->d_potential_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),52121);
  print_CUDA_error_if_any(hipMemcpy(potential_dot_dot_acoustic,mp->d_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),52131);

  GPU_ERROR_CHECKING("after transfer_fields_ac_from_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_fields_ac_from_device,
              TRANSFER_B_FIELDS_AC_FROM_DEVICE)(int* size,
                                                field* b_potential_acoustic,
                                                field* b_potential_dot_acoustic,
                                                field* b_potential_dot_dot_acoustic,
                                                long* Mesh_pointer) {
  TRACE("transfer_b_fields_ac_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(b_potential_acoustic,mp->d_b_potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),53111);
  print_CUDA_error_if_any(hipMemcpy(b_potential_dot_acoustic,mp->d_b_potential_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),53121);
  print_CUDA_error_if_any(hipMemcpy(b_potential_dot_dot_acoustic,mp->d_b_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),53131);

  GPU_ERROR_CHECKING("after transfer_b_fields_ac_from_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_potential_ac_from_device,
              TRANSFER_B_potentical_AC_FROM_DEVICE)(int* size,
                                                    field* b_potential_acoustic,
                                                    long* Mesh_pointer) {
  TRACE("transfer_b_potential_ac_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(b_potential_acoustic,mp->d_b_potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),53111);

  GPU_ERROR_CHECKING("after transfer_b_potential_ac_from_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_potential_dot_dot_ac_from_device,
              TRANSFER_B_potentical_DOT_DOT_AC_FROM_DEVICE)(int* size,
                                                            field* b_potential_dot_dot_acoustic,
                                                            long* Mesh_pointer) {
  TRACE("transfer_b_potential_dot_dot_ac_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(b_potential_dot_dot_acoustic,mp->d_b_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),53112);

  GPU_ERROR_CHECKING("after transfer_b_potential_dot_dot_ac_from_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_potential_ac_to_device,
              TRANSFER_B_potentical_AC_TO_DEVICE)(int* size,
                                                  field* b_potential_acoustic,
                                                  long* Mesh_pointer) {
  TRACE("transfer_b_potential_ac_to_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_potential_acoustic,b_potential_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),53112);

  GPU_ERROR_CHECKING("after transfer_b_potential_ac_to_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_potential_dot_dot_ac_to_device,
              TRANSFER_B_potentical_DOT_DOT_AC_TO_DEVICE)(int* size,
                                                          field* b_potential_dot_dot_acoustic,
                                                          long* Mesh_pointer) {
  TRACE("transfer_b_potential_ac_to_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(mp->d_b_potential_dot_dot_acoustic,b_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyHostToDevice),53113);

  GPU_ERROR_CHECKING("after transfer_b_potential_dot_dot_ac_to_device");
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_dot_dot_from_device,
              TRNASFER_DOT_DOT_FROM_DEVICE)(int* size, field* potential_dot_dot_acoustic,long* Mesh_pointer) {

  TRACE("transfer_dot_dot_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(potential_dot_dot_acoustic,mp->d_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),50041);

}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_b_dot_dot_from_device,
              TRNASFER_B_DOT_DOT_FROM_DEVICE)(int* size, field* b_potential_dot_dot_acoustic,long* Mesh_pointer) {

  TRACE("transfer_b_dot_dot_from_device");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(b_potential_dot_dot_acoustic,mp->d_b_potential_dot_dot_acoustic,
                                     sizeof(field)*(*size),hipMemcpyDeviceToHost),50042);

}


/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_kernels_ac_to_host,
              TRANSFER_KERNELS_AC_TO_HOST)(long* Mesh_pointer,realw* h_rho_ac_kl,realw* h_kappa_ac_kl,int* NSPEC_AB) {

  TRACE("transfer_kernels_ac_to_host");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  int size = *NSPEC_AB*NGLL3;

  // copies kernel values over to CPU host
  print_CUDA_error_if_any(hipMemcpy(h_rho_ac_kl,mp->d_rho_ac_kl,size*sizeof(realw),
                                     hipMemcpyDeviceToHost),54101);
  print_CUDA_error_if_any(hipMemcpy(h_kappa_ac_kl,mp->d_kappa_ac_kl,size*sizeof(realw),
                                     hipMemcpyDeviceToHost),54102);
}

/* ----------------------------------------------------------------------------------------------- */

// for Hess kernel calculations

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_kernels_hess_el_tohost,
              TRANSFER_KERNELS_HESS_EL_TOHOST)(long* Mesh_pointer,
                 realw* h_hess_kl,
                 realw* h_hess_rho_kl,
                 realw* h_hess_kappa_kl,
                 realw* h_hess_mu_kl,
                 int* NSPEC_AB) {

  TRACE("transfer_kernels_hess_el_tohost");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(h_hess_kl,mp->d_hess_el_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),70201);

  print_CUDA_error_if_any(hipMemcpy(h_hess_rho_kl,mp->d_hess_rho_el_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),70202);

  print_CUDA_error_if_any(hipMemcpy(h_hess_kappa_kl,mp->d_hess_kappa_el_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
              hipMemcpyDeviceToHost),70203);

  print_CUDA_error_if_any(hipMemcpy(h_hess_mu_kl,mp->d_hess_mu_el_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
             hipMemcpyDeviceToHost),70204);

  //printf("%e %e \n",h_hess_kappa_kl[125], h_hess_mu_kl[125]);
}

/* ----------------------------------------------------------------------------------------------- */

extern "C"
void FC_FUNC_(transfer_kernels_hess_ac_tohost,
              TRANSFER_KERNELS_HESS_AC_TOHOST)(long* Mesh_pointer,
                 realw* h_hess_ac_kl,
                 realw* h_hess_rho_ac_kl,
                 realw* h_hess_kappa_ac_kl,
                 int* NSPEC_AB) {

  TRACE("transfer_kernels_hess_ac_tohost");

  //get mesh pointer out of fortran integer container
  Mesh* mp = (Mesh*)(*Mesh_pointer);

  print_CUDA_error_if_any(hipMemcpy(h_hess_ac_kl,mp->d_hess_ac_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),70212);

  print_CUDA_error_if_any(hipMemcpy(h_hess_rho_ac_kl,mp->d_hess_rho_ac_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),70213);

  print_CUDA_error_if_any(hipMemcpy(h_hess_kappa_ac_kl,mp->d_hess_kappa_ac_kl,NGLL3*(*NSPEC_AB)*sizeof(realw),
                                     hipMemcpyDeviceToHost),70214);

}

// unused...

/* ----------------------------------------------------------------------------------------------- */
/*
extern "C"
void FC_FUNC_(transfer_compute_kernel_answers_from_device,
              TRANSFER_COMPUTE_KERNEL_ANSWERS_FROM_DEVICE)(long* Mesh_pointer,
                                                           realw* rho_kl,int* size_rho,
                                                           realw* mu_kl, int* size_mu,
                                                           realw* kappa_kl, int* size_kappa) {
TRACE("transfer_compute_kernel_answers_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container
  hipMemcpy(rho_kl,mp->d_rho_kl,*size_rho*sizeof(realw),hipMemcpyDeviceToHost);
  if (! mp->anisotropic_kl ){
    hipMemcpy(mu_kl,mp->d_mu_kl,*size_mu*sizeof(realw),hipMemcpyDeviceToHost);
    hipMemcpy(kappa_kl,mp->d_kappa_kl,*size_kappa*sizeof(realw),hipMemcpyDeviceToHost);
  }
}
*/

/* ----------------------------------------------------------------------------------------------- */
/*
extern "C"
void FC_FUNC_(transfer_compute_kernel_fields_from_device,
              TRANSFER_COMPUTE_KERNEL_FIELDS_FROM_DEVICE)(long* Mesh_pointer,
                                                          realw* accel, int* size_accel,
                                                          realw* b_displ, int* size_b_displ,
                                                          realw* epsilondev_xx,realw* epsilondev_yy,realw* epsilondev_xy,
                                                          realw* epsilondev_xz,realw* epsilondev_yz,
                                                          int* size_epsilondev,
                                                          realw* b_epsilondev_xx,realw* b_epsilondev_yy,realw* b_epsilondev_xy,
                                                          realw* b_epsilondev_xz,realw* b_epsilondev_yz,
                                                          int* size_b_epsilondev,
                                                          realw* rho_kl,int* size_rho,
                                                          realw* mu_kl, int* size_mu,
                                                          realw* kappa_kl, int* size_kappa,
                                                          realw* epsilon_trace_over_3,
                                                          realw* b_epsilon_trace_over_3,
                                                          int* size_epsilon_trace_over_3) {
TRACE("transfer_compute_kernel_fields_from_device");

  Mesh* mp = (Mesh*)(*Mesh_pointer); //get mesh pointer out of fortran integer container
  hipMemcpy(accel,mp->d_accel,*size_accel*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_displ,mp->d_b_displ,*size_b_displ*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(epsilondev_xx,mp->d_epsilondev_xx,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(epsilondev_yy,mp->d_epsilondev_yy,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(epsilondev_xy,mp->d_epsilondev_xy,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(epsilondev_xz,mp->d_epsilondev_xz,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(epsilondev_yz,mp->d_epsilondev_yz,*size_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilondev_xx,mp->d_b_epsilondev_xx,*size_b_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilondev_yy,mp->d_b_epsilondev_yy,*size_b_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilondev_xy,mp->d_b_epsilondev_xy,*size_b_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilondev_xz,mp->d_b_epsilondev_xz,*size_b_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilondev_yz,mp->d_b_epsilondev_yz,*size_b_epsilondev*sizeof(realw),hipMemcpyDeviceToHost);
  hipMemcpy(rho_kl,mp->d_rho_kl,*size_rho*sizeof(realw),hipMemcpyDeviceToHost);

  if (! mp->anisotropic_kl ){
    hipMemcpy(mu_kl,mp->d_mu_kl,*size_mu*sizeof(realw),hipMemcpyDeviceToHost);
    hipMemcpy(kappa_kl,mp->d_kappa_kl,*size_kappa*sizeof(realw),hipMemcpyDeviceToHost);
  }

  hipMemcpy(epsilon_trace_over_3,mp->d_epsilon_trace_over_3,*size_epsilon_trace_over_3*sizeof(realw),
       hipMemcpyDeviceToHost);
  hipMemcpy(b_epsilon_trace_over_3,mp->d_b_epsilon_trace_over_3,*size_epsilon_trace_over_3*sizeof(realw),
       hipMemcpyDeviceToHost);

  GPU_ERROR_CHECKING("after transfer_compute_kernel_fields_from_device");
}
*/

/* ----------------------------------------------------------------------------------------------- */
// register host array for pinned memory

extern "C"
void FC_FUNC_(register_host_array,
              REGISTER_HOST_ARRAY)(int *size, realw *h_array) {

  TRACE("register_host_array");

  // page-locks the memory to automatically accelerate calls to functions such as hipMemcpy()
  // since the memory can be accessed directly by the device, it can be read or written with
  // much higher bandwidth than pageable memory that has not been registered.
  // Page-locking excessive amounts of memory may degrade system performance,
  // since it reduces the amount of memory available to the system for paging.
  // As a result, this function is best used sparingly to register staging areas for data exchange between host and device.

  print_CUDA_error_if_any(hipHostRegister(h_array, (*size)*sizeof(realw), 0),55001);

  GPU_ERROR_CHECKING ("after register_host_array");
}


extern "C"
void FC_FUNC_(unregister_host_array,
              UNREGISTER_HOST_ARRAY)(realw *h_array) {

  TRACE("unregister_host_array");

  print_CUDA_error_if_any(hipHostUnregister(h_array),55002);

  GPU_ERROR_CHECKING ("after unregister_host_array");
}
