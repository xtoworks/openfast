!**********************************************************************************************************************************
! LICENSING
! Copyright (C) 2013-2015  National Renewable Energy Laboratory
!
!    This file is part of the NWTC Subroutine Library.
!
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
!
!     http://www.apache.org/licenses/LICENSE-2.0
!
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
!
!**********************************************************************************************************************************
! File last committed: $Date$
! (File) Revision #: $Rev$
! URL: $HeadURL$
!**********************************************************************************************************************************
MODULE SysSubs


   ! This module contains routines with system-specific logic and references, including all references to the console unit, CU.
   ! It also contains standard (but not system-specific) routines it uses.

   ! bjj: if compiling this to write to the Matlab command window using mexPrintf, you  must link with 
   !     libmex.lib in the matlab/extern/lib/{architecture}/{compiler} folder
   !      otherwise, use preprocessor definition CONSOLE_FILE to output everything to a file named CONSOLE.TXT
   
   ! nja: This was formatted for use with Intel Visual Fortran, and may need some small changes if compiling with gfortran

   ! It contains the following routines:

   !     FUNCTION    FileSize( Unit )                                         ! Returns the size (in bytes) of an open file.
   !     SUBROUTINE  FlushOut ( Unit )
   !     FUNCTION    NWTC_ERF( x )
   !     FUNCTION    NWTC_gamma( x )
   !     SUBROUTINE  GET_CWD( DirName, Status )
   !     FUNCTION    Is_NaN( DblNum )                                         ! Please use IEEE_IS_NAN() instead
   !     FUNCTION    NWTC_Gamma( x )                                          ! Returns the gamma value of its argument.   
   ! per MLB, this can be removed, but only if CU is OUTPUT_UNIT:
   !     SUBROUTINE  OpenCon     ! Actually, it can't be removed until we get Intel's FLUSH working. (mlb)
   !     SUBROUTINE  OpenUnfInpBEFile ( Un, InFile, RecLen, Error )
   !     SUBROUTINE  ProgExit ( StatCode )
   !     SUBROUTINE  Set_IEEE_Constants( NaN_D, Inf_D, NaN, Inf )   
   !     SUBROUTINE  UsrAlarm
   !     SUBROUTINE  WrNR ( Str )
   !     SUBROUTINE  WrOver ( Str )
   !     SUBROUTINE  WriteScr ( Str, Frm )
   !     SUBROUTINE LoadDynamicLib( DLL, ErrStat, ErrMsg )
   !     SUBROUTINE FreeDynamicLib( DLL, ErrStat, ErrMsg )



   USE                             NWTC_Base

   IMPLICIT                        NONE

   INTERFACE NWTC_gamma ! Returns the gamma value of its argument
      MODULE PROCEDURE NWTC_gammaR4
      MODULE PROCEDURE NWTC_gammaR8
      MODULE PROCEDURE NWTC_gammaR16
   END INTERFACE
   
   INTERFACE NWTC_ERF ! Returns the ERF value of its argument
      MODULE PROCEDURE NWTC_ERFR4
      MODULE PROCEDURE NWTC_ERFR8
      MODULE PROCEDURE NWTC_ERFR16
   END INTERFACE
   

!=======================================================================


   INTEGER, PARAMETER            :: ConRecL     = 120                               ! The record length for console output.
   INTEGER, PARAMETER            :: CU          = 6                                 ! The I/O unit for the console.  Unit 6 causes ADAMS to crash.
   INTEGER, PARAMETER            :: MaxWrScrLen = 98                                ! The maximum number of characters allowed to be written to a line in WrScr

   LOGICAL, PARAMETER            :: KBInputOK   = .FALSE.                           ! A flag to tell the program that keyboard input is allowed in the environment.

   CHARACTER(*),  PARAMETER      :: NewLine     = ACHAR(10)                         ! The delimiter for New Lines [ Windows is CHAR(13)//CHAR(10); MAC is CHAR(13); Unix is CHAR(10) {CHAR(13)=\r is a line feed, CHAR(10)=\n is a new line}]
   CHARACTER(*),  PARAMETER      :: OS_Desc     = 'Intel Visual Fortran for Mac' ! Description of the language/OS
   CHARACTER( 1), PARAMETER      :: PathSep     = '/'                               ! The path separator.
   CHARACTER( 1), PARAMETER      :: SwChar      = '-'                               ! The switch character for command-line options.
   CHARACTER(11), PARAMETER      :: UnfForm     = 'UNFORMATTED'                          ! The string to specify unformatted I/O files. (used in OpenUOutFile and OpenUInpFile [see TurbSim's .bin files])

CONTAINS

!=======================================================================
   FUNCTION FileSize( Unit )


      ! This function calls the portability routine, FSTAT, to obtain the file size
      ! in bytes corresponding to a file unit number or returns -1 on error.


   USE IFPORT


      ! Function declaration.

   INTEGER(B8Ki)                             :: FileSize                      ! The size of the file in bytes to be returned.


      ! Argument declarations:

   INTEGER, INTENT(IN)                       :: Unit                          ! The I/O unit number of the pre-opened file.


      ! Local declarations:

   INTEGER                                   :: StatArray(12)                 ! An array returned by FSTAT that includes the file size.
   INTEGER                                   :: Status                        ! The status returned by



   Status = FSTAT( INT( Unit, B4Ki ), StatArray )

   IF ( Status /= 0 ) THEN
      FileSize = -1
   ELSE
      FileSize = StatArray(8)
   END IF


   RETURN
   END FUNCTION FileSize ! ( Unit )
!=======================================================================
   SUBROUTINE FlushOut ( Unit )


      ! This subroutine flushes the buffer on the specified Unit.
      ! It is especially useful when printing "running..." type messages.

USE IFPORT, ONLY: FLUSH

      ! Argument declarations:

   INTEGER, INTENT(IN)          :: Unit                                         ! The unit number of the file being flushed.

CALL FLUSH ( INT(Unit, B4Ki) )

   RETURN
   END SUBROUTINE FlushOut ! ( Unit )
!=======================================================================
   SUBROUTINE Get_CWD ( DirName, Status )


      ! This routine retrieves the path of the current working directory.


   USE IFPORT, ONLY: GETCWD

   IMPLICIT                        NONE


      ! Passed variables.

   CHARACTER(*), INTENT(OUT)    :: DirName                                         ! A CHARACTER string containing the path of the current working directory.
   INTEGER,      INTENT(OUT)    :: Status                                          ! Status returned by the call to a portability routine.


   Status = GETCWD ( DirName )

   RETURN
   END SUBROUTINE Get_CWD

!=======================================================================
SUBROUTINE MKDIR ( new_directory_path )

   ! This routine creates a given directory if it does not exist.

   implicit none

   character(*), intent(in) :: new_directory_path
   character(1024)          :: make_command
   logical                  :: directory_exists

   ! Check if the directory exists first
   inquire( directory=trim(new_directory_path), exist=directory_exists )

   if ( .NOT. directory_exists ) then
      make_command = 'mkdir -p '//trim(new_directory_path)
      call system( make_command )
   endif

END SUBROUTINE MKDIR

!=======================================================================
   FUNCTION Is_NaN( DblNum )


      ! This routine determines if a REAL(DbKi) variable holds a proper number.
      ! BJJ: this routine is used in CRUNCH.
      ! It should be replaced with IEEE_IS_NAN in new code, but remains here for
      ! backwards compatibility.

  USE, INTRINSIC :: ieee_arithmetic

      ! Argument declarations.
   REAL(DbKi), INTENT(IN)       :: DblNum

      ! Function declaration.
   LOGICAL                      :: Is_Nan

   Is_NaN = IEEE_IS_NAN( DblNum )


   RETURN
   END FUNCTION Is_NaN ! ( DblNum )
!=======================================================================
   FUNCTION NWTC_ERFR4( x )
   
      ! Returns the ERF value of its argument. The result has a value equal  
      ! to the error function: 2/pi * integral_from_0_to_x of e^(-t^2) dt. 

      REAL(SiKi), INTENT(IN)     :: x           ! input 
      REAL(SiKi)                 :: NWTC_ERFR4  ! result
      
      
      NWTC_ERFR4 = ERF( x )
   
   END FUNCTION NWTC_ERFR4
!=======================================================================
   FUNCTION NWTC_ERFR8( x )
   
      ! Returns the ERF value of its argument. The result has a value equal  
      ! to the error function: 2/pi * integral_from_0_to_x of e^(-t^2) dt. 

      REAL(R8Ki), INTENT(IN)     :: x             ! input 
      REAL(R8Ki)                 :: NWTC_ERFR8    ! result
      
      
      NWTC_ERFR8 = ERF( x )
   
   END FUNCTION NWTC_ERFR8
!=======================================================================
   FUNCTION NWTC_ERFR16( x )
   
      ! Returns the ERF value of its argument. The result has a value equal  
      ! to the error function: 2/pi * integral_from_0_to_x of e^(-t^2) dt. 

      REAL(QuKi), INTENT(IN)     :: x             ! input 
      REAL(QuKi)                 :: NWTC_ERFR16   ! result
      
      
      NWTC_ERFR16 = ERF( x )
   
   END FUNCTION NWTC_ERFR16
!=======================================================================
   FUNCTION NWTC_GammaR4( x )
   
      ! Returns the gamma value of its argument. The result has a value equal  
      ! to a processor-dependent approximation to the gamma function of x. 

      REAL(SiKi), INTENT(IN)     :: x             ! input 
      REAL(SiKi)                 :: NWTC_GammaR4  ! result
      
      
      NWTC_GammaR4 = gamma( x )
   
   END FUNCTION NWTC_GammaR4
!=======================================================================
   FUNCTION NWTC_GammaR8( x )
   
      ! Returns the gamma value of its argument. The result has a value equal  
      ! to a processor-dependent approximation to the gamma function of x. 

      REAL(R8Ki), INTENT(IN)     :: x             ! input 
      REAL(R8Ki)                 :: NWTC_GammaR8  ! result
      
      
      NWTC_GammaR8 = gamma( x )
   
   END FUNCTION NWTC_GammaR8
!=======================================================================
   FUNCTION NWTC_GammaR16( x )
   
      ! Returns the gamma value of its argument. The result has a value equal  
      ! to a processor-dependent approximation to the gamma function of x. 

      REAL(QuKi), INTENT(IN)     :: x             ! input 
      REAL(QuKi)                 :: NWTC_GammaR16  ! result
      
      
      NWTC_GammaR16 = gamma( x )
   
   END FUNCTION NWTC_GammaR16
!=======================================================================
SUBROUTINE OpenCon

   ! This routine opens the console for standard output.

   USE IFPORT

!bjj: Because CU = 6 now, this statement is not necessary
!   OPEN ( CU , FILE='/dev/stdout' , STATUS='UNKNOWN' , CARRIAGECONTROL='FORTRAN', RECL=ConRecL )

   CALL FlushOut ( CU )

   RETURN
END SUBROUTINE OpenCon
!=======================================================================
   SUBROUTINE OpenUnfInpBEFile ( Un, InFile, RecLen, Error )


      ! This routine opens a binary input file with data stored in Big Endian format (created on a UNIX machine.)
      ! Data are stored in RecLen-byte records.

   IMPLICIT                        NONE

      ! Argument declarations.
   INTEGER, INTENT(IN)          :: Un                                           ! Logical unit for the input file.
   CHARACTER(*), INTENT(IN)     :: InFile                                       ! Name of the input file.
   INTEGER, INTENT(IN)          :: RecLen                                       ! Size of records in the input file, in bytes.
   LOGICAL, INTENT(OUT)         :: Error                                        ! Flag to indicate the open failed.
      ! Local declarations.
   INTEGER                      :: IOS                                          ! I/O status of OPEN.



   ! Open input file.  Make sure it worked.
   ! The non-standard CONVERT keyword allows us to read UNIX binary files, whose bytes are in reverse order (i.e., stored in BIG ENDIAN format).
   ! NOTE: using RecLen in bytes requires using the /assume:byterecl compiler option!

   OPEN ( Un, FILE=TRIM( InFile ), STATUS='OLD', FORM='UNFORMATTED', ACCESS='DIRECT', RECL=RecLen, IOSTAT=IOS, &
                 ACTION='READ'  )                                              ! Use this for UNIX systems.
                   ! ACTION='READ', CONVERT='BIG_ENDIAN' )                         ! Use this for PC systems.


   IF ( IOS /= 0 )  THEN
      Error = .TRUE.
   ELSE
      Error = .FALSE.
   END IF


   RETURN
   END SUBROUTINE OpenUnfInpBEFile
!=======================================================================
   SUBROUTINE ProgExit ( StatCode )


      ! This routine stops the program.  If the compiler supports the EXIT routine,
      ! pass the program status to it.  Otherwise, do a STOP.


      ! Argument declarations.

   INTEGER, INTENT(IN)          :: StatCode                                      ! The status code to pass to the OS.


   END SUBROUTINE ProgExit ! ( StatCode )
!=======================================================================
   SUBROUTINE Set_IEEE_Constants( NaN_D, Inf_D, NaN, Inf )   
   
      ! routine that sets the values of NaN_D, Inf_D, NaN, Inf (IEEE 
      ! values for not-a-number and infinity in sindle and double 
      ! precision) This uses standard F03 intrinsic routines,  
      ! however Gnu has not yet implemented it, so we've placed this
      ! routine in the system-specific code.
   
   
      USE, INTRINSIC :: ieee_arithmetic  ! use this for compilers that have implemented ieee_arithmetic from F03 standard (otherwise see logic in SysGnu*.f90)
   
      REAL(DbKi), INTENT(inout)           :: Inf_D          ! IEEE value for NaN (not-a-number) in double precision
      REAL(DbKi), INTENT(inout)           :: NaN_D          ! IEEE value for Inf (infinity) in double precision

      REAL(ReKi), INTENT(inout)           :: Inf            ! IEEE value for NaN (not-a-number)
      REAL(ReKi), INTENT(inout)           :: NaN            ! IEEE value for Inf (infinity)
   
      
      NaN_D = ieee_value(0.0_DbKi, ieee_quiet_nan)
      Inf_D = ieee_value(0.0_DbKi, ieee_positive_inf)
   
      NaN   = ieee_value(0.0_ReKi, ieee_quiet_nan)
      Inf   = ieee_value(0.0_ReKi, ieee_positive_inf)   
   
   
   END SUBROUTINE Set_IEEE_Constants  
!=======================================================================
   SUBROUTINE UsrAlarm

      ! This routine does nothing for the MATLAB environment.

   RETURN
   END SUBROUTINE UsrAlarm
!=======================================================================
   SUBROUTINE WrNR ( Str )

      ! This routine writes out a string to the screen without following it with a new line.
      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: Str                                          ! The string to write to the screen.
   INTEGER                      :: Stat                                         ! Number of characters printed
   INTEGER, EXTERNAL            :: mexPrintF                                    ! Matlab function to print to the command window
   CHARACTER(1024),SAVE         :: Str2                                         ! bjj: need static variable to print to Matlab command window

   Str2 = ' '//Str//C_NULL_CHAR  !bjj: not sure C_NULL_CHAR is necessary
   Stat = mexPrintF( Str2 )
   
   RETURN
   END SUBROUTINE WrNR ! ( Str )
!=======================================================================
   SUBROUTINE WrOver ( Str )


      ! This routine writes out a string that overwrites the previous line
      ! Argument declarations.

   CHARACTER(*), INTENT(IN)     :: Str                                          ! The string to write to the screen.
   CALL WriteScr( Str, '(A)' )

   RETURN
   END SUBROUTINE WrOver ! ( Str )
!=======================================================================
   SUBROUTINE WriteScr ( Str, Frm )

      ! This routine writes out a string to the screen.

   IMPLICIT                        NONE

      ! Argument declarations.
   CHARACTER(*), INTENT(IN)     :: Str                                         ! The input string to write to the screen.
   CHARACTER(*), INTENT(IN)     :: Frm                                         ! Format specifier for the output.
      ! Local variables
   INTEGER, EXTERNAL            :: mexPrintF                                   ! Matlab function to print to the command window
   INTEGER                      :: Stat                                        ! Number of characters printed to the screen
   CHARACTER( 1024 ), SAVE      :: Str2   ! A temporary string (Str written with the Frm Format specification) (bjj: this apparently needs to be a static variable so it writes to the Matlab command window)


   IF ( LEN_TRIM(Str)  < 1 ) THEN
      Str2=''
   ELSE
      WRITE (Str2,Frm, IOSTAT=Stat)  ADJUSTL( Str )
   END IF

   Str2 = trim(Str2)//NewLine//C_NULL_CHAR  !bjj: not sure C_NULL_CHAR is necessary
   Stat = mexPrintf( Str2 )
   !call mexEvalString("drawnow;");  ! !bjj: may have to call this to dump string to the screen immediately.

   END SUBROUTINE WriteScr ! ( Str )

!=======================================================================


!=======================================================================
SUBROUTINE LoadDynamicLib ( DLL, ErrStat, ErrMsg )

   ! This SUBROUTINE is used to dynamically load a DLL.

   TYPE (DLL_Type),           INTENT(INOUT)  :: DLL         ! The DLL to be loaded.
   INTEGER(IntKi),            INTENT(  OUT)  :: ErrStat     ! Error status of the operation
   CHARACTER(*),              INTENT(  OUT)  :: ErrMsg      ! Error message if ErrStat /= ErrID_None

#ifdef USE_DLL_INTERFACE         

!bjj: these are values I found on the web; I have no idea if they actually work...
!bjj: hopefully we can find them pre-defined in a header somewhere
   INTEGER(C_INT), PARAMETER :: RTLD_LAZY=1            ! "Perform lazy binding. Only resolve symbols as the code that references them is executed. If the symbol is never referenced, then it is never resolved. (Lazy binding is only performed for function references; references to variables are always immediately bound when the library is loaded.) "
   INTEGER(C_INT), PARAMETER :: RTLD_NOW=2             ! "If this value is specified, or the environment variable LD_BIND_NOW is set to a nonempty string, all undefined symbols in the library are resolved before dlopen() returns. If this cannot be done, an error is returned."
   INTEGER(C_INT), PARAMETER :: RTLD_GLOBAL=256        ! "The symbols defined by this library will be made available for symbol resolution of subsequently loaded libraries"
   INTEGER(C_INT), PARAMETER :: RTLD_LOCAL=0           ! "This is the converse of RTLD_GLOBAL, and the default if neither flag is specified. Symbols defined in this library are not made available to resolve references in subsequently loaded libraries."

   INTERFACE !linux API routines
      !bjj see http://linux.die.net/man/3/dlopen
      !    and https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/dlopen.3.html

      FUNCTION dlOpen(filename,mode) BIND(C,NAME="dlopen")
      ! void *dlopen(const char *filename, int mode);
         USE ISO_C_BINDING
         IMPLICIT NONE
         TYPE(C_PTR)                   :: dlOpen
         CHARACTER(C_CHAR), INTENT(IN) :: filename(*)
         INTEGER(C_INT), VALUE         :: mode
      END FUNCTION

   END INTERFACE

   ErrStat = ErrID_None
   ErrMsg = ''

   ! Load the DLL and get the file address:

   DLL%FileAddrX = dlOpen( TRIM(DLL%FileName)//C_NULL_CHAR, RTLD_LAZY )  !the "C_NULL_CHAR" converts the Fortran string to a C-type string (i.e., adds //CHAR(0) to the end)

   IF( .NOT. C_ASSOCIATED(DLL%FileAddrX) ) THEN
      ErrStat = ErrID_Fatal
      WRITE(ErrMsg,'(I2)') BITS_IN_ADDR
      ErrMsg  = 'The dynamic library '//TRIM(DLL%FileName)//' could not be loaded. Check that the file '// &
                'exists in the specified location and that it is compiled for '//TRIM(ErrMsg)//'-bit applications.'
      RETURN
   END IF

   ! Get the procedure address:

   CALL LoadDynamicLibProc ( DLL, ErrStat, ErrMsg )
#else

   ErrStat = ErrID_Fatal
   ErrMsg = ' LoadDynamicLib: Not compiled with -DUSE_DLL_INTERFACE for '//TRIM(OS_Desc)
      
#endif
   
   RETURN
END SUBROUTINE LoadDynamicLib
!=======================================================================
SUBROUTINE LoadDynamicLibProc ( DLL, ErrStat, ErrMsg )

   ! This SUBROUTINE is used to dynamically load a procedure from a DLL.

   TYPE (DLL_Type),           INTENT(INOUT)  :: DLL         ! The DLL to be loaded.
   INTEGER(IntKi),            INTENT(  OUT)  :: ErrStat     ! Error status of the operation
   CHARACTER(*),              INTENT(  OUT)  :: ErrMsg      ! Error message if ErrStat /= ErrID_None
   INTEGER(IntKi)                            :: i

#ifdef USE_DLL_INTERFACE           

   INTERFACE !linux API routines

      !bjj see http://linux.die.net/man/3/dlsym
      !    and https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/dlsym.3.html
      
      FUNCTION dlSym(handle,name) BIND(C,NAME="dlsym")
      ! void *dlsym(void *handle, const char *name);
         USE ISO_C_BINDING
         IMPLICIT NONE
         TYPE(C_FUNPTR)                :: dlSym ! A function pointer
         TYPE(C_PTR), VALUE            :: handle
         CHARACTER(C_CHAR), INTENT(IN) :: name(*)
      END FUNCTION

   END INTERFACE

   ErrStat = ErrID_None
   ErrMsg = ''

   do i=1,NWTC_MAX_DLL_PROC
      if ( len_trim( DLL%ProcName(i) ) > 0 ) then
   
         DLL%ProcAddr(i) = dlSym( DLL%FileAddrX, TRIM(DLL%ProcName(i))//C_NULL_CHAR )  !the "C_NULL_CHAR" converts the Fortran string to a C-type string (i.e., adds //CHAR(0) to the end)

         IF(.NOT. C_ASSOCIATED(DLL%ProcAddr(i))) THEN
            ErrStat = ErrID_Fatal
            ErrMsg  = 'The procedure '//TRIM(DLL%ProcName(i))//' in file '//TRIM(DLL%FileName)//' could not be loaded.'
            RETURN
         END IF
         
      end if
   end do
      
#else

   ErrStat = ErrID_Fatal
   ErrMsg = ' LoadDynamicLibProc: Not compiled with -DUSE_DLL_INTERFACE for '//TRIM(OS_Desc)
      
#endif
   
   RETURN
END SUBROUTINE LoadDynamicLibProc
!=======================================================================
SUBROUTINE FreeDynamicLib ( DLL, ErrStat, ErrMsg )

      ! This SUBROUTINE is used to free a dynamically loaded DLL (loaded in LoadDynamicLib).

      TYPE (DLL_Type),           INTENT(INOUT)  :: DLL         ! The DLL to be freed.
      INTEGER(IntKi),            INTENT(  OUT)  :: ErrStat     ! Error status of the operation
      CHARACTER(*),              INTENT(  OUT)  :: ErrMsg      ! Error message if ErrStat /= ErrID_None
      INTEGER(C_INT)                            :: Success     ! Whether or not the call to dlClose was successful
      INTEGER(C_INT), PARAMETER                 :: TRUE  = 0

#ifdef USE_DLL_INTERFACE           
!bjj: note that this is not tested.

   INTERFACE !linux API routine
      !bjj see http://linux.die.net/man/3/dlclose
      !    and https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/dlclose.3.html

      FUNCTION dlClose(handle) BIND(C,NAME="dlclose")
      ! int dlclose(void *handle);
         USE ISO_C_BINDING
         IMPLICIT NONE
         INTEGER(C_INT)       :: dlClose
         TYPE(C_PTR), VALUE   :: handle
      END FUNCTION

   END INTERFACE

   ! Close the library:

   IF( .NOT. C_ASSOCIATED(DLL%FileAddrX) ) RETURN
   Success = dlClose( DLL%FileAddrX ) !The function dlclose() returns 0 on success, and nonzero on error.

   IF ( Success /= TRUE ) THEN !bjj: note that this is not the same as LOGICAL .TRUE.
      ErrStat = ErrID_Fatal
      ErrMsg  = 'The dynamic library could not be freed.'
      RETURN
   ELSE
      ErrStat = ErrID_None
      ErrMsg = ''
      DLL%FileAddrX = C_NULL_PTR
   END IF
   
#else

      ErrStat = ErrID_Fatal
      ErrMsg = ' FreeDynamicLib: Not compiled with -DUSE_DLL_INTERFACE for '//TRIM(OS_Desc)
         
#endif
   
      RETURN
   END SUBROUTINE FreeDynamicLib
!=======================================================================
END MODULE SysSubs
