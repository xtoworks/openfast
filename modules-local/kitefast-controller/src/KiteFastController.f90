!**********************************************************************************************************************************
!> ## SC
!! The KiteFastController  module implements a controller for the KiteFAST code. 
!! KiteFastController_Types will be auto-generated by the FAST registry program, based on the variables specified in the
!! KiteFastController_Registry.txt file.
!!
! ..................................................................................................................................
!! ## LICENSING 
!! Copyright (C) 2018  National Renewable Energy Laboratory
!!
!!    This file is part of KiteFAST.
!!
!! Licensed under the Apache License, Version 2.0 (the "License");
!! you may not use this file except in compliance with the License.
!! You may obtain a copy of the License at
!!
!!     http://www.apache.org/licenses/LICENSE-2.0
!!
!! Unless required by applicable law or agreed to in writing, software
!! distributed under the License is distributed on an "AS IS" BASIS,
!! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!! See the License for the specific language governing permissions and
!! limitations under the License.
!**********************************************************************************************************************************
module KiteFastController

   use KiteFastController_Types
   use NWTC_Library
   use, intrinsic :: ISO_C_Binding
   
   implicit none
   private
   
   integer,        parameter    :: IntfStrLen  = 1025       ! length of strings through the C interface
   type(ProgDesc), parameter    :: KFC_Ver = ProgDesc( 'KiteFast Controller', '', '' )

      !> Definition of the DLL Interface for the SuperController
      !! 
   abstract interface
      subroutine KFC_DLL_Init_PROC ( errStat, errMsg )  BIND(C)
         use, intrinsic :: ISO_C_Binding
         integer(C_INT),         intent(  out) :: errStat             !< error status code (uses NWTC_Library error codes)
         character(kind=C_CHAR), intent(inout) :: errMsg          (*) !< Error Message from DLL to simulation code        
      end subroutine KFC_DLL_Init_PROC   
   end interface   

   abstract interface
      subroutine KFC_DLL_Step_PROC ( dcm_g2b_c, pqr_c, acc_norm_c, Xg_c, Vg_c, Vb_c, Ag_c, Ab_c, rho_c, apparent_wind_c, &
         tether_force_c, wind_g_c, SFlp, PFlp, Rudr, SElv, PElv, GenSPyRtr, GenPPyRtr, errStat, errMsg )  BIND(C)
         use, intrinsic :: ISO_C_Binding
         real(C_DOUBLE),         intent(in   ) :: dcm_g2b_c(9)      
         real(C_DOUBLE),         intent(in   ) :: pqr_c(3)          
         real(C_DOUBLE),         intent(in   ) :: acc_norm_c(3)     
         real(C_DOUBLE),         intent(in   ) :: Xg_c(3)           
         real(C_DOUBLE),         intent(in   ) :: Vg_c(3)           
         real(C_DOUBLE),         intent(in   ) :: Vb_c(3)           
         real(C_DOUBLE),         intent(in   ) :: Ag_c(3)           
         real(C_DOUBLE),         intent(in   ) :: Ab_c(3)           
         real(C_DOUBLE),         intent(in   ) :: rho_c          
         real(C_DOUBLE),         intent(in   ) :: apparent_wind_c(3)
         real(C_DOUBLE),         intent(in   ) :: tether_force_c(3) 
         real(C_DOUBLE),         intent(in   ) :: wind_g_c(3) 
         real(C_DOUBLE),         intent(  out) :: SFlp(3)           
         real(C_DOUBLE),         intent(  out) :: PFlp(3)           
         real(C_DOUBLE),         intent(  out) :: Rudr(2)           
         real(C_DOUBLE),         intent(  out) :: SElv(2)           
         real(C_DOUBLE),         intent(  out) :: PElv(2)           
         real(C_DOUBLE),         intent(  out) :: GenSPyRtr(4)
         real(C_DOUBLE),         intent(  out) :: GenPPyRtr(4)
         integer(C_INT),         intent(inout) :: errStat           !< error status code (uses NWTC_Library error codes)
         character(kind=C_CHAR), intent(inout) :: errMsg(1025)      !< Error Message from DLL to simulation code        
      end subroutine KFC_DLL_Step_PROC   
   end interface   
 
   abstract interface
      subroutine KFC_DLL_END_PROC ( errStat, errMsg )  BIND(C)
         use, intrinsic :: ISO_C_Binding
         integer(C_INT),         intent(  out) :: errStat             !< error status code (uses NWTC_Library error codes)
         character(kind=C_CHAR), intent(inout) :: errMsg          (*) !< Error Message from DLL to simulation code        
      end subroutine KFC_DLL_END_PROC   
   end interface   

   public :: KFC_Init                     ! Initialization routine
   public :: KFC_End                      ! Ending routine (includes clean up)
   public :: KFC_CalcOutput               ! Routine for computing outputs and internally updating states
  
   contains   
   
   
   subroutine KFC_End(p, errStat, errMsg)

      type(KFC_ParameterType),        intent(inout)  :: p               !< Parameters
      integer(IntKi),                 intent(  out)  :: errStat         !< Error status of the operation
      character(*),                   intent(  out)  :: errMsg          !< Error message if ErrStat /= ErrID_None

         ! local variables
      character(*), parameter                        :: routineName = 'KFC_End'
      integer(IntKi)                                 :: errStat2       ! The error status code
      character(ErrMsgLen)                           :: errMsg2        ! The error message, if an error occurred
      procedure(KFC_DLL_END_PROC),pointer            :: DLL_KFC_End_Subroutine       ! The address of the controller cc_end procedure in the DLL
      character(kind=C_CHAR)                         :: errMsg_c(IntfStrLen)
      errStat = ErrID_None
      errMsg= ''
      
         ! Call the DLL's end subroutine:
      call C_F_PROCPOINTER( p%DLL_Trgt%ProcAddr(3), DLL_KFC_End_Subroutine) 
      call DLL_KFC_End_Subroutine ( errStat, errMsg_c ) 
      call c_to_fortran_string(errMsg_c, errMsg)
      
      ! TODO: Check errors
      
         ! Free the library
      call FreeDynamicLib( p%DLL_Trgt, errStat2, errMsg2 )  
         call SetErrStat( errStat2, errMsg2, errStat, errMsg, routineName )
  
   end subroutine KFC_End

   subroutine KFC_Init(InitInp, p, InitOut, errStat, errMsg )
      type(KFC_InitInputType),      intent(in   )  :: InitInp     !< Input data for initialization routine
      type(KFC_ParameterType),      intent(  out)  :: p           !< Parameters
      type(KFC_InitOutputType),     intent(  out)  :: InitOut     !< Initialization output data
      integer(IntKi),               intent(  out)  :: errStat     !< Error status of the operation
      character(1024),              intent(  out)  :: errMsg      !< Error message if ErrStat /= ErrID_None

   
         ! local variables
      character(*), parameter                 :: routineName = 'KFC_Init'
      integer(IntKi)                          :: errStat2                     ! The error status code
      character(ErrMsgLen)                    :: errMsg2                      ! The error message, if an error occurred
      procedure(KFC_DLL_Init_PROC),pointer    :: DLL_KFC_Init_Subroutine       ! The address of the controller cc_init procedure in the DLL
      
      integer(IntKi)                          :: nParams
      character(kind=C_CHAR)                  :: errMsg_c(IntfStrLen)
      
      errStat2 = ErrID_None
      errMsg2  = ''
   
      call DispNVD( KFC_Ver )  ! Display the version of this interface
      
         ! Check that key Kite model components match the requirements of this controller interface.
      if (InitInp%numFlaps /= 3) call SetErrStat( ErrID_Fatal, 'The current KiteFAST controller interface requires numFlaps = 3', errStat, errMsg, routineName )
      if (InitInp%numPylons /= 2) call SetErrStat( ErrID_Fatal, 'The current KiteFAST controller interface requires numPylons = 2', errStat, errMsg, routineName )
      if (.not. EqualRealNos(InitInp%DT, 0.01_DbKi)) call SetErrStat( ErrID_Fatal, 'The current KiteFAST controller interface requires DT = 0.01 seconds', errStat, errMsg, routineName )
         if (errStat >= AbortErrLev ) return
         
      p%numFlaps  = InitInp%numFlaps
      p%numPylons = InitInp%numPylons
      p%DT        = InitInp%DT
      
      
     
         ! Define and load the DLL:

      p%DLL_Trgt%FileName = InitInp%DLL_FileName

      p%DLL_Trgt%ProcName = "" ! initialize all procedures to empty so we try to load only one
      p%DLL_Trgt%ProcName(1) = 'kfc_dll_init'
      p%DLL_Trgt%ProcName(2) = 'kfc_dll_step'
      p%DLL_Trgt%ProcName(3) = 'kfc_dll_end'
      
      call LoadDynamicLib ( p%DLL_Trgt, errStat2, errMsg2 )
         call SetErrStat( errStat2, errMsg2, errStat, errMsg, routineName )
      if (errStat >= AbortErrLev ) return

         
         ! Now that the library is loaded, call cc_init() 


         ! Call the DLL (first associate the address from the procedure in the DLL with the subroutine):
      call C_F_PROCPOINTER( p%DLL_Trgt%ProcAddr(1), DLL_KFC_Init_Subroutine) 
      call DLL_KFC_Init_Subroutine ( errStat, errMsg_c ) 
      call c_to_fortran_string(errMsg_c, errMsg)
      
      ! TODO: Check errors
           
      if (errStat >= AbortErrLev ) return

    
   end subroutine KFC_Init

   subroutine KFC_CalcOutput(t, u, p, y, errStat, errMsg )
      real(DbKi),                    intent(in   )  :: t           !< Current simulation time in seconds
      type(KFC_InputType),           intent(in   )  :: u           !< Inputs at Time t
      type(KFC_ParameterType),       intent(in   )  :: p           !< Parameters
      type(KFC_OutputType),          intent(inout)  :: y           !< Outputs computed at t (Input only so that mesh con-
                                                                   !!   nectivity information does not have to be recalculated)
      integer(IntKi),                intent(  out)  :: errStat     !< Error status of the operation
      character(*),                  intent(  out)  :: errMsg      !< Error message if ErrStat /= ErrID_None
   
      
      character(*), parameter                       :: routineName = 'KFC_CalcOutput'
      integer(IntKi)                                :: errStat2       ! The error status code
      character(ErrMsgLen)                          :: errMsg2        ! The error message, if an error occurred     
      procedure(KFC_DLL_Step_PROC),pointer          :: DLL_KFC_Step_Subroutine              ! The address of the supercontroller sc_calcoutputs procedure in the DLL
      real(C_DOUBLE)                                :: dcm_g2b_c(9)      
      real(C_DOUBLE)                                :: pqr_c(3)          
      real(C_DOUBLE)                                :: acc_norm_c(3)     
      real(C_DOUBLE)                                :: Xg_c(3)           
      real(C_DOUBLE)                                :: Vg_c(3)           
      real(C_DOUBLE)                                :: Vb_c(3)           
      real(C_DOUBLE)                                :: Ag_c(3)           
      real(C_DOUBLE)                                :: Ab_c(3)           
      real(C_DOUBLE)                                :: rho_c          
      real(C_DOUBLE)                                :: apparent_wind_c(3)
      real(C_DOUBLE)                                :: tether_force_c(3) 
      real(C_DOUBLE)                                :: wind_g_c(3)       
      character(kind=C_CHAR)                        :: errMsg_c(IntfStrLen)
      real(C_DOUBLE)                                :: SFlp_c(3)           
      real(C_DOUBLE)                                :: PFlp_c(3)           
      real(C_DOUBLE)                                :: Rudr_c(2)           
      real(C_DOUBLE)                                :: SElv_c(2)           
      real(C_DOUBLE)                                :: PElv_c(2)           
      real(C_DOUBLE)                                :: GenSPyRtr_c(4)
      real(C_DOUBLE)                                :: GenPPyRtr_c(4)

      errStat2 = ErrID_None
      errMsg2  = ''
      
         ! Cast and massage inputs to match DLL datatypes
      dcm_g2b_c       = reshape(u%dcm_g2b,(/9/))
      pqr_c           = u%pqr
      acc_norm_c      = u%acc_norm
      Xg_c            = u%Xg
      Vg_c            = u%Vg
      Vb_c            = u%Vb
      Ag_c            = u%Ag
      Ab_c            = u%Ab
      rho_c           = u%rho
      apparent_wind_c = u%apparent_wind
      tether_force_c  = u%tether_force
      wind_g_c        = u%wind_g
      GenSPyRtr_c     = reshape(y%GenSPyRtr,(/4/))
      GenPPyRtr_c     = reshape(y%GenPPyRtr,(/4/))

         ! Call the DLL (first associate the address from the procedure in the DLL with the subroutine):
      call C_F_PROCPOINTER( p%DLL_Trgt%ProcAddr(2), DLL_KFC_Step_Subroutine) 
      call DLL_KFC_Step_Subroutine ( dcm_g2b_c, pqr_c, acc_norm_c, Xg_c, Vg_c, Vb_c, Ag_c, Ab_c, rho_c, apparent_wind_c, tether_force_c, wind_g_c, SFlp_c, PFlp_c, Rudr_c, SElv_c, PElv_c, GenSPyRtr_c, GenPPyRtr_c, errStat, errMsg_c ) 
      call c_to_fortran_string(errMsg_c, errMsg)

         ! Convert the controller outputs into the KiteFAST Fortran-style controller outputs
      y%SFlp = SFlp_c
      y%SFlp = SFlp_c   
      y%Rudr = Rudr_c 
      y%SElv = SElv_c
      y%PElv = PElv_c   
      y%GenSPyRtr = reshape(GenSPyRtr_c,(/2,2/))
      y%GenPPyRtr = reshape(GenPPyRtr_c,(/2,2/))
      
         ! TODO Error checking
    
   end subroutine KFC_CalcOutput
   
   subroutine c_to_fortran_string(input, output)
      character(kind=C_CHAR), intent(in) :: input(IntfStrLen)
      character(*), intent(out) :: output
      character(1024) :: temp_string
      temp_string = transfer(input(1:1024), output)
      call RemoveNullChar(temp_string)
      output = trim(temp_string)
   end subroutine

end module KiteFastController
