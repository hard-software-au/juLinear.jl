NAME          BLEND

OBJSENSE
 MAX
 
ROWS
 N  PROF
 L  VVEG
 L  NVEG
 L  UHRD
 G  LHRD
 E  CONT
COLUMNS
    VEG01     PROF      -110.0    VVEG         1.0
    VEG01     UHRD         8.8    LHRD         8.8
    VEG01     CONT         1.0
    VEG02     PROF      -120.0    VVEG         1.0
    VEG02     UHRD         6.1    LHRD         6.1
    VEG02     CONT         1.0
    OIL01     PROF      -130.0    NVEG         1.0
    OIL01     UHRD         2.0    LHRD         2.0
    OIL01     CONT         1.0
    OIL02     PROF      -110.0    NVEG         1.0
    OIL02     UHRD         4.2    LHRD         4.2
    OIL02     CONT         1.0
    OIL03     PROF      -115.0    NVEG         1.0
    OIL03     UHRD         5.0    LHRD         5.0
    OIL03     CONT         1.0
    PROD      PROF       150.0    UHRD        -6.0
    PROD      LHRD        -3.0    CONT        -1.0
RHS
    RHS       VVEG       200.0
    RHS       NVEG       250.0
    RHS       UHRD         0.0
    RHS       LHRD         0.0
    RHS       CONT         0.0
ENDATA
"""

GLPK example dataset
const IS_MINIMIZE::Bool = false
const MPS_EXAMPLE::String = """
*NAME:         ALLOY
*ROWS:         22
*COLUMNS:      20
*NONZERO:      203
*OPT SOLN:     2149.247891
*SOURCE:       Linear Programming--Aluminium Alloy Blending
*              Data Processing Application. N.Y.: IBM Corp.
*APPLICATION:  Aluminium Alloy Blending
*COMMENTS:     fixed MPS format
*              encoded by Andrew Makhorin <mao@gnu.org>
*
NAME          ALLOY

OBJSENSE
 MAX
 
ROWS
 N  COST
 G  ZN  
 L  ZX  
 G  CN  
 L  CX  
 G  MN  
 L  MX  
 G  CHN 
 L  CHX 
 G  BN  
 L  BX  
 L  IX  
 L  SX  
 L  MGX 
 L  NX  
 L  TX  
 L  LX  
 L  TNX 
 L  BIX 
 L  GX  
 L  SCX 
 G  FL  
COLUMNS
* Pure Aluminium 1
    A1        COST             .28
    A1        IX               .0004
    A1        SX               .0005
    A1        FL              1.0
* Pure Aluminium 2
    A2        COST             .26
    A2        IX               .0006
    A2        SX               .0006
    A2        FL              1.0
* Pure Aluminium 3
    A3        COST             .25
    A3        IX               .0011
    A3        SX               .0007
    A3        FL              1.0
* PuA3 Aluminium 4
    A4        COST             .23
    A4        IX               .0026
    A4        SX               .0012
    A4        FL              1.0
* Pure Copper
    C         COST             .31
    C         CN              1.00
    C         CX              1.00
    C         FL              1.0
* Pure Magnesium
    M         COST             .38
    M         MN              1.00
    M         MX              1.00
    M         FL              1.0
* Beryllium/Aluminium Alloy
    B/A       COST            3.60
    B/A       BN              0.0600
    B/A       BX              0.0600
    B/A       FL              1.0
* Pure Zinc
    Z         COST             .22
    Z         ZN               .95
    Z         ZX               .95
    Z         FL              1.0
* Chromium Aluminium Alloy
    C/A       COST             .27
    C/A       CHN              .0300
    C/A       CHX              .0300
    C/A       FL              1.0
* Scrap 1
    SC1       COST             .21
    SC1       ZN               .0009
    SC1       ZX               .0009
    SC1       CN               .0444
    SC1       CX               .0444
    SC1       MN               .0042
    SC1       MX               .0042
    SC1       CHN              .0001
    SC1       CHX              .0001
    SC1       IX               .0024
    SC1       SX               .0101
    SC1       MGX              .0079
    SC1       NX               .0001
    SC1       TX               .0004
    SC1       LX               .0001
    SC1       TNX              .0001
    SC1       GX               .0001
    SC1       SCX             1.00
    SC1       FL              1.0
* Scrap 2
    SC2       COST             .20
    SC2       ZN               .0012
    SC2       ZX               .0012
    SC2       CN               .0026
    SC2       CX               .0026
    SC2       MN               .0060
    SC2       MX               .0060
    SC2       CHN              .0018
    SC2       CHX              .0018
    SC2       IX               .0026
    SC2       SX               .0106
    SC2       MGX              .0003
    SC2       NX               .0002
    SC2       TX               .0004
    SC2       LX               .0001
    SC2       TNX              .0001
    SC2       GX               .0002
    SC2       FL              1.0
* Scrap 3
    SC3       COST             .21
    SC3       ZN               .0568
    SC3       ZX               .0568
    SC3       CN               .0152
    SC3       CX               .0152
    SC3       MN               .0248
    SC3       MX               .0248
    SC3       CHN              .0020
    SC3       CHX              .0020
    SC3       IX               .0016
    SC3       SX               .0013
    SC3       MGX              .0005
    SC3       TX               .0004
    SC3       LX               .0003
    SC3       TNX              .0003
    SC3       FL              1.0
* Scrap 4
    SC4       COST             .20
    SC4       ZN               .0563
    SC4       ZX               .0563
    SC4       CN               .0149
    SC4       CX               .0149
    SC4       MN               .0238
    SC4       MX               .0238
    SC4       CHN              .0019
    SC4       CHX              .0019
    SC4       IX               .0019
    SC4       SX               .0011
    SC4       MGX              .0004
    SC4       TX               .0004
    SC4       LX               .0003
    SC4       TNX              .0003
    SC4       FL              1.0
* Scrap 5
    SC5       COST             .21
    SC5       ZN               .0460
    SC5       ZX               .0460
    SC5       CN               .0071
    SC5       CX               .0071
    SC5       MN               .0343
    SC5       MX               .0343
    SC5       CHN              .0013
    SC5       CHX              .0013
    SC5       IX               .0017
    SC5       SX               .0013
    SC5       MGX              .0018
    SC5       TX               .0002
    SC5       LX               .0002
    SC5       TNX              .0002
    SC5       FL              1.0
* Scrap 6
    SC6       COST             .20
    SC6       ZN               .0455
    SC6       ZX               .0455
    SC6       CN               .0071
    SC6       CX               .0071
    SC6       MN               .0343
    SC6       MX               .0343
    SC6       IX               .0016
    SC6       SX               .0011
    SC6       MGX              .0017
    SC6       TX               .0002
    SC6       LX               .0002
    SC6       TNX              .0002
    SC6       FL              1.0
* Scrap 7
    SC7       COST             .21
    SC7       ZN               .0009
    SC7       ZX               .0009
    SC7       CN               .0447
    SC7       CX               .0447
    SC7       MN               .0143
    SC7       MX               .0143
    SC7       IX               .0026
    SC7       SX               .0013
    SC7       MGX              .0052
    SC7       TX               .0003
    SC7       LX               .0001
    SC7       TNX              .0001
    SC7       FL              1.0
* Scrap 8
    SC8       COST             .20
    SC8       ZN               .0006
    SC8       ZX               .0006
    SC8       CN               .0623
    SC8       CX               .0623
    SC8       IX               .0017
    SC8       SX               .0010
    SC8       MGX              .0025
    SC8       TX               .0005
    SC8       LX               .0001
    SC8       TNX              .0001
    SC8       GX               .0025
    SC8       FL              1.0
* Scrap 9
    SC9       COST             .21
    SC9       ZN               .0009
    SC9       ZX               .0009
    SC9       CN               .0034
    SC9       CX               .0034
    SC9       MN               .0093
    SC9       MX               .0093
    SC9       CHN              .0019
    SC9       CHX              .0019
    SC9       IX               .0030
    SC9       SX               .0062
    SC9       MGX              .0002
    SC9       TX               .0003
    SC9       BIX              .0005
    SC9       FL              1.0
* Scrap 10
    SC10      COST             .20
    SC10       ZN               .0008
    SC10       ZX               .0008
    SC10       CN               .0003
    SC10       CX               .0003
    SC10       MN               .0249
    SC10       MX               .0249
    SC10       CHN              .0016
    SC10       CHX              .0016
    SC10       IX               .0015
    SC10       SX               .0011
    SC10       MGX              .0002
    SC10       FL              1.0
* Scrap 11
    SC11      COST             .21
    SC11      ZN               .0675
    SC11      ZX               .0675
    SC11      CN               .0195
    SC11      CX               .0195
    SC11      MN               .0265
    SC11      MX               .0265
    SC11      CHN              .0020
    SC11      CHX              .0020
    SC11      IX               .0014
    SC11      SX               .0008
    SC11      MGX              .0002
    SC11      FL              1.0
RHS
    RHS       ZN            555.
    RHS       ZX            590.
    RHS       CN            140.0
    RHS       CX            190.0
    RHS       MN            245.0
    RHS       MX            275.0
    RHS       CHN            19.0
    RHS       CHX            22.0
    RHS       BN              2.0
    RHS       BX              4.0
    RHS       IX             15.0
    RHS       SX             10.0
    RHS       MGX             3.0
    RHS       NX              2.0
    RHS       TX              2.0
    RHS       LX              2.0
    RHS       TNX             2.0
    RHS       BIX             8.0
    RHS       GX              8.0
    RHS       SCX           900.0
    RHS       FL          10000.
ENDATA
