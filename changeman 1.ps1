Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


####################################################################################
#  Definitions                                                                     #
####################################################################################
$user = 'XZ0670'
#
$lblMainWindowTxt = 'ChangeMan'
$lblPackageTxt    = 'Package'
$lblUserTxt       = 'User'
$btnPullTxt       = 'Pull'
$btnPushTxt       = 'Push'
$btnExitTxt       = 'Exit'
$btnListTxt       = 'List'
$txtPackageTxt    = 'CORE'
####################################################################################
#                                 listPackageComponents                            #
####################################################################################
function listPackageComponents() {

    Write-Host " > listPackageComponents"

    $progressBar.Value = 1
    $progressBar.Maximum = 9
    $progressBar.Refresh

    $listViewComponents.Items.Clear()
    $progressBar.Value = 2

    if ($txtBoxPackage.Text.Length -ne 9){
        $txtboxPackageNumber = $txtBoxPackage.Text.substring(4)
        ##Write-Host $txtboxPackageNumber
        $txtboxPackageNumberMax = $txtboxPackageNumber.padleft(6,'0')
        ##Write-Host $txtboxPackageNumberMax
        ##$txtboxPackage = $txtBoxPackage.Text.substring(0,4) + $txtboxPackageNumberMax
        ##Write-Host $txtboxPackage
        $packageNumber = $txtboxPackageNumberMax
        $txtBoxPackage.Text = $txtBoxPackage.Text.substring(0,4) + $txtboxPackageNumberMax
    }
    else{
        $packageNumber = $txtBoxPackage.Text.substring($txtBoxPackage.Text.Length - 6)
    }
    Write-Host "   | " $txtBoxPackage.Text

    $progressBar.Value = 3
    $progressBar.Refresh

    $lstPrograms = @()
    $lstCopybooks = @()
    $lstUnloads = @()

    $progressBar.Value = 4
    $progressBar.Refresh

    $componentList = @(zowe zos-files list data-set "CMNP.MG1D.STG.CORE.#$packageNumber")

    $progressBar.Value = 5
    $progressBar.Refresh

    for ($i = 0; $i -lt $componentList.Length; $i++) {
        switch ($componentList[$i].substring($componentList[$i].Length - 3)) {
            'SRC' {
                $lstPrograms = @(zowe zos-files list all-members $componentList[$i])
            }
            'CPY' {
                $lstCopybooks = @(zowe zos-files list all-members $componentList[$i])
            }
            'UNL' {
                $lstUnloads = @(zowe zos-files list all-members $componentList[$i])
            }
        }
    }

    $progressBar.Value = 6
    $progressBar.Refresh

    for ($i = 0; $i -lt $lstPrograms.Length; $i++) {
        if ($lstPrograms[$i] -ne "") {
            $componentItem = New-Object System.Windows.Forms.ListViewItem
            $componentItem.Text = $lstPrograms[$i]
            $componentItem.SubItems.Add("SRC")
            $componentItem.SubItems.Add("-")
            $componentItem.SubItems.Add("")
            $listViewComponents.Items.Add($componentItem)
        }
    }

    $progressBar.Value = 7
    $progressBar.Refresh

    for ($i = 0; $i -lt $lstCopybooks.Length; $i++) {
        if ($lstCopybooks[$i] -ne "") {
            $componentItem = New-Object System.Windows.Forms.ListViewItem
            $componentItem.Text = $lstCopybooks[$i]
            $componentItem.SubItems.Add("CPY")
            $componentItem.SubItems.Add("-")
            $componentItem.SubItems.Add("")
            $listViewComponents.Items.Add($componentItem)
        }
    }

    $progressBar.Value = 8
    $progressBar.Refresh

    for ($i = 0; $i -lt $lstUnloads.Length; $i++) {
        if ($lstPrograms[$i] -ne "") {
            $componentItem = New-Object System.Windows.Forms.ListViewItem
            $componentItem.Text = $lstUnloads[$i]
            $componentItem.SubItems.Add("UNL")
            $componentItem.SubItems.Add("-")
            $componentItem.SubItems.Add("")
            $listViewComponents.Items.Add($componentItem)
        }
    }

    $progressBar.Value = 9
    $progressBar.Refresh

    refreshList
}
####################################################################################
#                                   pushComponent
####################################################################################
function pushComponent() {

    Write-Host " > pushComponent"

    $progressBar.Maximum = 5
    $packageNumber = $txtBoxPackage.Text.Substring(4, 6)
    $userName = $txtBoxUser.Text


    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {
        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        Write-Host "   | " $componentName'.'$componentExtension
        $progressBar.Value = 1

        if ($componentExtension -eq "cpy") {
            $componentType = "COPY"
            $job = "//" + $userName + "PS JOB (851,985,995),'Push - $componentName',
//         MSGCLASS=X,CLASS=D
//*
//*
//JOBLIB   DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//*)IM CMNSRVC
//*
//CMNSRVC EXEC PGM=CMNVSRVC,
//             COND=(4,LT),
//             PARM='SUBSYS=P,USER=$userName'
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SERRPLY  DD  SYSOUT=*,
//             DCB=(RECFM=VB,LRECL=4080,BLKSIZE=0)
//SERPRINT DD  SYSOUT=*                             TRACE OUTPUT
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  *
OBJ=CMPONENT,MSG=CHECKIN,PKN=CORE$packageNumber,
LTP=$componentExtension,CKF=1,SLT=6,
LIB=$userName.LIB.$componentType,
LOK=N,SPV=Y,CCD=                               ,
SUP=N,
TMN=$componentName,
CNT=00001"
        }
        elseif ($componentExtension -eq "src") {
            $componentType = "SOURCE"
            $sourceType = ""

            if ($componentName.substring(2, 1) -eq "I") {

                if ($componentName.substring(5, 3) -in ("020" -or "040" -or "060" -or "080")) {
                    # online
                    $sourceType = "UO1=  Y       ,UO2=          ,UHS=N,"
                }
                else {
                    # Rotina online
                    $sourceType = "Rotina Online"
                }

            }
            elseif ($componentName.substring(2, 1) -eq "B") {
                # batch
                $sourceType = "UO1=        Y ,UO2=          ,UHS=N,"
            }
            elseif ($componentName.substring(2, 1) -eq "R") {
                # Rotina batch
                $sourceType = "Rotina Batch"
            }
            else {
                $sourceType = $componentName.substring(2, 1)
            }

            $job = "//" + $userName + "PS JOB (851,985,995),'Push - $componentName',
//         MSGCLASS=X,CLASS=D
//*
//*        -----------------------------------------------------------
//*        IEBCOPY: COPIA DE ELEMENTO DE UM UTILIZADOR PARA O PACOTE
//*        -----------------------------------------------------------
//*        -----------------------------------------------------------
//JOBLIB   DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//*)IM CMNSRVC
//*
//DELFILE EXEC PGM=IDCAMS
//SYSPRINT DD   SYSOUT=*
//SYSIN    DD   *
  DELETE (CMNP.TEMP.CORE.#$packageNumber.$componentName.S1) NONVSAM
  SET MAXCC = 0
/*
//*
//CMNSRVC EXEC PGM=CMNVSRVC,
//             COND=(4,LT),
//             PARM='SUBSYS=P,USER=$userName'
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SERRPLY  DD  SYSOUT=*,
//             DCB=(RECFM=VB,LRECL=4080,BLKSIZE=0)
//SERPRINT DD  DISP=(,CATLG),
//             DSN=CMNP.TEMP.CORE.#$packageNumber.$componentName.S1,
//             UNIT=SYSDA,SPACE=(CYL,(5,5),RLSE),
//             DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  *
OBJ=CMPONENT,MSG=CHECKIN,PKN=CORE$packageNumber,
LTP=$componentExtension,CKF=1,SLT=6,
LIB=$userName.LIB.$componentType,
LOK=N,SPV=Y,CCD=                               ,
SUP=N,
TMN=$componentName,
CNT=00001
OBJ=CMPONENT,MSG=BUILD,PKN=CORE$packageNumber,
LTP=$componentExtension,PRC=BMPCOBE ,LNG=COBOLE  ,
$sourceType
DB2=Y,DBS=DB2D,DBL=SYS1.DB2.SDSNLOAD                           ,
JC1=//" + $userName + "B JOB ,'Compilar CORE$packageNumber',MSGCLASS=X,
JC2=//         NOTIFY=XZ0670,CLASS=N
JC3=//*
JC4=//*
SUP=N,
UPN=CMNUSR01,
IJN=N,
DSN=CMNP.MG1D.STG.CORE.#$packageNumber.$componentExtension,
CMP=$componentName,
CNT=00001"
        }
        elseif ($componentExtension -eq "unload") {
            $componentType = "UNLOAD"
        }
        $progressBar.Value = 2

        $job | Out-file -encoding ASCII -noNewline -FilePath "$env:TEMP\Job.JCL"

        $progressBar.Value = 3

        jobSubmit 'Push'

        $progressBar.Value = 5
    }

    refreshList
}

####################################################################################
#                                   pullComponent                                  #
####################################################################################
function pullComponent() {

    Write-Host " > pullComponent"

    $progressBar.Maximum = 6
    $packageNumber = $txtBoxPackage.Text.Substring(4, 6)

    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {

        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        Write-Host "   | " $componentName'.'$componentExtension

        $progressBar.Value = 1

        if ($componentExtension -eq "cpy") {
            $componentType = "COPY"
        }
        elseif ($componentExtension -eq "src") {
            $componentType = "SOURCE"
        }
        elseif ($componentExtension -eq "unload") {
            $componentType = "UNLOAD"
        }

        $progressBar.Value = 2

        $userName = $txtBoxUser.Text

        $progressBar.Value = 3

        $job = "//" + $userName + "PL JOB (851,985,995),'Pull - $componentName',
//         MSGCLASS=X,CLASS=D
//*
//*        -----------------------------------------------------------
//*        IEBCOPY: COPIA DE ELEMENTO DE UM PACOTE PARA O UTILIZADOR
//*        -----------------------------------------------------------
//*        -----------------------------------------------------------
//COPIA    EXEC PGM=IEBCOPY,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//IN       DD DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#$packageNumber.$componentExtension
//OUT      DD DISP=SHR,DSN=$userName.LIB.$componentType
//SYSIN    DD *
  COPY     INDD=IN,OUTDD=OUT
  SELECT   MEMBER=(($componentName,,R))
//*"
        $progressBar.Value = 4
        $job | Out-file -encoding ASCII -noNewline -FilePath "$env:TEMP\Job.JCL"
        $progressBar.Value = 5

        jobSubmit 'Pull'

        $progressBar.Value = 6
    }

    refreshList

}
####################################################################################
#                                   jobSubmit                                      #
####################################################################################
function jobSubmit() {
    Param($jobType)

    $outputJCL = @(zowe jobs submit local-file "$env:TEMP\Job.JCL" --response-format-json --view-all-spool-content --reject-unauthorized false)
    $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = $jobType + ' Ok'
    $progressBar.Value = 4

    Write-Host   $outputJCL

    $data = $outputJCL | ConvertFrom-Json

    $data.stdout

    if ($jobType -eq 'Push'){
        $jobRC = $userName + "PS ENDED - RC="
    }else
    {
        $jobRC = $userName + "PL ENDED - RC="}

    $jobRCPosition = $data.stdout.LastIndexOf($jobRC)
    $returnCode = $data.stdout.Substring($jobRCPosition+$jobRC.Length,4)
    $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = $returnCode
    if ($returnCode -ne '0000'){
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = $jobType + ' Not Ok'
    }
}
####################################################################################
#                       refreshList                                                #
####################################################################################
function refreshList {
    $progressBar.Value = 0
    $progressBar.Refresh

    $listViewComponents.SelectedItems.Clear()
    $listViewComponents.Refresh()

    $listViewComponents.Columns[0].Width = -1
    $listViewComponents.Columns[1].Width = -2
    $listViewComponents.Columns[2].Width = -2
    $listViewComponents.Columns[3].Width = -2
}

####################################################################################
#                                 Promote10                                        #
####################################################################################

function promote10() {

    Write-Host " > promote10"

    $dec = $packageNumber
    $hex = $dec.ToString("x")
    Write-Host $hex

    $progressBar.Maximum = 5
    $packageNumber = $txtBoxPackage.Text.Substring(4, 6)
    $userName = $txtBoxUser.Text


    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {
        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        Write-Host "   | " $componentName'.'$componentExtension
        $progressBar.Value = 1

        if ($componentExtension -eq "src") {
            $componentType = "SRC"

            if ($componentName.substring(2, 1) -eq "I") {

                if ($componentName.substring(5, 3) -in ("020" -or "040" -or "060" -or "080")) {
            $job = "//" + $userName + "PS JOB (851,985,995),'Push - $componentName',
//         MSGCLASS=X,NOTIFY=" + $userName + ",CLASS=D
//*
//*
//*
//* THE ABOVE JOB CARDS CAME FROM THE IMBED OF SKEL CMN$$JCD
//*)IM CMN$$JCD
//*
//*  JOB REQUESTED BY " + $userName + " ON 2023/12/12 AT 09:58
//*
//*)IM CMN$$DSN
//* LANG    =
//* PROC    = BMPCOBE
//* SIGYCMP = SYS1.ADCOB.SIGYCOMP
//*)IM CMN$$JBL
//JOBLIB   DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//*)IM CMN$$PRM
//*)IM CMN$$PSQ
//*)IM CMN$$PSV
//*)IM CMN$$PRB
//*
//* PROMFUN = SELPROM
//* TYPERUN =
//* RUNBIND =
//* REBPKG  =
//* RUNDB2PL = YES
//*
//*
//* PROMFUN = SELPROM
//* TYPERUN = PROMOTE
//* RUNBIND = Y
//* REBPKG  =
//* RUNDB2PL = YES
//*
//* STREMT  = MG1D
//* RPMSITE = LOCAL
//* STEPSUF =
//* STBINDF =
//* STSLOD  = SYS1.DB2.SDSNLOAD
//*
//* NTSSYS  = DB2D
//* STSSYS  = CM2P
//* NTREMT  = LOCAL
//* RPMSITE = LOCAL
//* NTBINDF = YES
//* STBINDF =
//* BNLOGSB =
//* NTNNAM  = TEST
//*
//* DBBSTG  = NO
//* 1 DB2SUBT = R
//* MODCNT  = 0
//* STATUS  = *SELECT*
//* TYPERUN = PROMOTE
//* REBIND  =
//*
//* PKGSTG  = YES
//* DBRSTG  = YES
//*
//* STSSYS  = CM2D
//* STREMT  = LOCAL
//* STBINDF = YES
//* STSLOD  = SYS1.DB2.SDSNLOAD
//* STEPSUF =
//* RPMSITE = LOCAL
//* LIBTYPE = ODL
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 1 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* 4-CONTADR = 1 CNTPSD = 0 CNTPKG = 0
//* 4-BNDESPY =  BNDESPN =
//* LIBTYPE = ONL
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 2 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* 4-CONTADR = 2 CNTPSD = 0 CNTPKG = 0
//* 4-BNDESPY =  BNDESPN =
//* LIBTYPE = PKG
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT = P
//* 1-CONTADR = 3 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* ESQUELETO CMN$$PRB PARA HACER BIND ESTANDAR CMNDB2PL
//* 3-CONTADR = 3 CNTPSD = 0 CNTPKG = 1
//* 3-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 3 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//* LIBTYPE = SRC
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 4 CNTPSD = 0 CNTPKG = 1
//* 1-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 4 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//* LIBTYPE = DBR
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT = R
//* 1-CONTADR = 5 CNTPSD = 0 CNTPKG = 1
//* 1-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 5 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//DB2PLY  EXEC PGM=CMNDB2PL, *** DETERMINE DB2 BIND REQUIREMENTS
//             REGION=0M,    *** WHERE BIND FAIL SIGNIF IS YES
//             COND=(4,LT)
//*)IM CMN$$JBL
//STEPLIB  DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//*)IM CMN$$D2X
//*)IM CMN$$D2X END
//         DD  DISP=SHR,DSN=SYSU.DB2D.SDSNEXIT
//         DD  DISP=SHR,DSN=SYS1.DB2.SDSNLOAD
//SYSPRINT DD  SYSOUT=*
//SYSTERM  DD  SYSOUT=*
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//CMNPLCTL DD  *
TYPE=PROMOTE
AUTHORITY=OWNER,INSERT
*AUTHORITY=OWNER
INSERTQUAL
*EARLYCHECK
*IGNORENOSUBSYS
*TRACE
USEREXIT=(ASM,NOUNLOAD)
USERID=" + $userName + "
PACKAGE=CORE" + $packageNumber+ "
PROJECT=CORE
NOBASEDBBRC=12
WARNINGRC=4
USEDB2PACKAGE
*NODB2PLAN
*FREEPLAN
CREATECC
*IGNORENODBRM
PKLTEMPLATE
DB2ID=CM2D
LOGICAL=BEMD
PLANTGT=
PLANSRC=
PKGETGT=CBEMD^
PKGESRC=
LOCNTGT=LOCCMD
LOCNSRC=
QUALIFIER=BEMD
QUALTGT=BEMD
QUALSRC=
OWNER=DESENV
OWNRTGT=DESENV
OWNRSRC=
REMOTEID=LOCAL
//CMNPLDBB DD  *               PLAN BIND COMPONENTS IN PACKAGE
//CMNPLPKG DD  *               PACKAGE BIND COMPONENTS IN PACKAGE
MBR=" + $componentName + "
//CMNPLDBR DD  *                DBRM COMPONENTS IN PACKAGE
MBR=" + $componentName + "
//SERPRINT DD  SYSOUT=*
//*
//*
//DBBSBAS  DD  DISP=(,PASS),DSN=&&TPROMDBB,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=QUAL.LIB.DBBLIB
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBB
//*
//PKGSSTG  DD  DISP=(,PASS),DSN=&&TSTGEPKG,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//*
//PKGSBAS  DD  DISP=(,PASS),DSN=&&TPROMPKG,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//*
//CM2DBCTL DD  DISP=(,PASS),DSN=&&CM2DBCTL,
//             UNIT=SYSDA,SPACE=(TRK,(15,1),RLSE),
//             DCB=(DSORG=PS,LRECL=80,RECFM=FB,BLKSIZE=0)
//*
//* LIST THE TEMPLATED BIND PARAMETERS WHICH WILL BE USED BY THE BIND
//*
//CM2DLSTY EXEC PGM=IEBGENER,COND=(4,LT)
//SYSPRINT DD   DUMMY
//SYSUT1   DD   DISP=(OLD,PASS),DSN=&&CM2DBCTL
//SYSUT2   DD   SYSOUT=*
//SYSIN    DD   DUMMY
//*
//CM2DBNDY EXEC PGM=IKJEFT1A,  *** PERFORM CM2D BINDS
//             COND=(4,LT),    *** WHERE BIND FAIL SIGNIF IS YES
//             DYNAMNBR=20
//*)IM CMN$$D2X
//*)IM CMN$$D2X END
//STEPLIB  DD  DISP=SHR,DSN=SYSU.DB2D.SDSNEXIT
//         DD  DISP=SHR,DSN=SYS1.DB2.SDSNLOAD
//DBRMLIB  DD  DISP=(,PASS),DSN=&&TPROMDBR,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=DESV.LIB.DBRMLIB
//         DD  DISP=SHR,DSN=QUAL.LIB.DBRMLIB
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//*
//SYSPRINT DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//SYSTSIN  DD  DISP=(OLD,DELETE),DSN=&&CM2DBCTL
//*
//* STSSYS  = DB2D
//* STREMT  = LOCAL
//* STBINDF = YES
//* STSLOD  = SYS1.DB2.SDSNLOAD
//* STEPSUF = Y
//* RPMSITE = LOCAL
//* LIBTYPE = ODL
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 1 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* 4-CONTADR = 1 CNTPSD = 0 CNTPKG = 0
//* 4-BNDESPY =  BNDESPN =
//* LIBTYPE = ONL
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 2 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* 4-CONTADR = 2 CNTPSD = 0 CNTPKG = 0
//* 4-BNDESPY =  BNDESPN =
//* LIBTYPE = PKG
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT = P
//* 1-CONTADR = 3 CNTPSD = 0 CNTPKG = 0
//* 1-BNDESPY =  BNDESPN =
//* ESQUELETO CMN$$PRB PARA HACER BIND ESTANDAR CMNDB2PL
//* 3-CONTADR = 3 CNTPSD = 0 CNTPKG = 1
//* 3-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 3 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//* LIBTYPE = SRC
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT =
//* 1-CONTADR = 4 CNTPSD = 0 CNTPKG = 1
//* 1-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 4 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//* LIBTYPE = DBR
//* LRPMSTE = LOCAL
//* LRPMLVL = 10
//* LRPMNME = DESV
//* MODCNT  = 1
//* DB2SUBT = R
//* 1-CONTADR = 5 CNTPSD = 0 CNTPKG = 1
//* 1-BNDESPY =  BNDESPN = Y
//* 4-CONTADR = 5 CNTPSD = 0 CNTPKG = 1
//* 4-BNDESPY =  BNDESPN = Y
//DB2PLY  EXEC PGM=CMNDB2PL, *** DETERMINE DB2 BIND REQUIREMENTS
//             REGION=0M,    *** WHERE BIND FAIL SIGNIF IS YES
//             COND=(4,LT)
//*)IM CMN$$JBL
//STEPLIB  DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//*)IM CMN$$D2X
//*)IM CMN$$D2X END
//         DD  DISP=SHR,DSN=SYSU.DB2D.SDSNEXIT
//         DD  DISP=SHR,DSN=SYS1.DB2.SDSNLOAD
//SYSPRINT DD  SYSOUT=*
//SYSTERM  DD  SYSOUT=*
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//CMNPLCTL DD  *
TYPE=PROMOTE
AUTHORITY=OWNER,INSERT
*AUTHORITY=OWNER
INSERTQUAL
*EARLYCHECK
*IGNORENOSUBSYS
*TRACE
USEREXIT=(ASM,NOUNLOAD)
USERID=" + $userName + "
PACKAGE=CORE" + $packageNumber+ "
PROJECT=CORE
NOBASEDBBRC=12
WARNINGRC=4
USEDB2PACKAGE
*NODB2PLAN
*FREEPLAN
CREATECC
*IGNORENODBRM
PKLTEMPLATE
DB2ID=DB2D
LOGICAL=DESV
PLANTGT=
PLANSRC=
PKGETGT=CDESV^
PKGESRC=
LOCNTGT=LOCD
LOCNSRC=
QUALIFIER=DESV
QUALTGT=DESV
QUALSRC=
OWNER=DESENV
OWNRTGT=DESENV
OWNRSRC=
REMOTEID=LOCAL
DB2ID=DB2D
LOGICAL=TEST
PLANTGT=
PLANSRC=
PKGETGT=CTEST^
PKGESRC=
LOCNTGT=LOCD
LOCNSRC=
QUALIFIER=TEST
QUALTGT=TEST
QUALSRC=
OWNER=TESTES
OWNRTGT=TESTES
OWNRSRC=
REMOTEID=LOCAL
//CMNPLDBB DD  *               PLAN BIND COMPONENTS IN PACKAGE
//CMNPLPKG DD  *               PACKAGE BIND COMPONENTS IN PACKAGE
MBR=" + $componentName + "
//CMNPLDBR DD  *                DBRM COMPONENTS IN PACKAGE
MBR=" + $componentName + "
//SERPRINT DD  SYSOUT=*
//*
//*
//DBBSBAS  DD  DISP=(,PASS),DSN=&&TPROMDBB,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=QUAL.LIB.DBBLIB
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBB
//*
//PKGSSTG  DD  DISP=(,PASS),DSN=&&TSTGEPKG,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//*
//PKGSBAS  DD  DISP=(,PASS),DSN=&&TPROMPKG,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.PKG
//*
//DB2DBCTL DD  DISP=(,PASS),DSN=&&DB2DBCTL,
//             UNIT=SYSDA,SPACE=(TRK,(15,1),RLSE),
//             DCB=(DSORG=PS,LRECL=80,RECFM=FB,BLKSIZE=0)
//*
//* LIST THE TEMPLATED BIND PARAMETERS WHICH WILL BE USED BY THE BIND
//*
//DB2DLSTY EXEC PGM=IEBGENER,COND=(4,LT)
//SYSPRINT DD   DUMMY
//SYSUT1   DD   DISP=(OLD,PASS),DSN=&&DB2DBCTL
//SYSUT2   DD   SYSOUT=*
//SYSIN    DD   DUMMY
//STEM0402 EXEC PROC=DSORT,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SORTIN   DD *
CORE" + $hex + "
//*
//SORTOUT  DD *
//SYSIN    DD *
//*
//DB2DBNDY EXEC PGM=IKJEFT1A,  *** PERFORM DB2D BINDS
//             COND=(4,LT),    *** WHERE BIND FAIL SIGNIF IS YES
//             DYNAMNBR=20
//*)IM CMN$$D2X
//*)IM CMN$$D2X END
//STEPLIB  DD  DISP=SHR,DSN=SYSU.DB2D.SDSNEXIT
//         DD  DISP=SHR,DSN=SYS1.DB2.SDSNLOAD
//DBRMLIB  DD  DISP=(,PASS),DSN=&&TPROMDBR,
//             UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0)
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//         DD  DISP=SHR,DSN=DESV.LIB.DBRMLIB
//         DD  DISP=SHR,DSN=QUAL.LIB.DBRMLIB
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//         DD  DISP=SHR,DSN=CMNP.MG1D.BSL.LIB.DBR
//*
//SYSPRINT DD  SYSOUT=*
//SYSTSPRT DD  SYSOUT=*
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//SYSTSIN  DD  DISP=(OLD,DELETE),DSN=&&DB2DBCTL
//*
//*
//* PROMOTE PACKAGE CORE" + $packageNumber+ " TO DESV LVL 10 AT LOCAL SITE
//*
//* CMN$$PSR
//*)IM CMN$$PRO
//CPY1ODL EXEC PGM=IEBCOPY,    *** PROMOTION OF ODL
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//*)IM CMN$$ENQ
//SYSUT3   DD  DISP=(MOD,DELETE),
//             DSN=DESV.LIB.ONLINE.SYSDEBUG.ENQ,
//             UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//STGODL   DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".ODL
//PRMODL   DD  DISP=SHR,DSN=DESV.LIB.ONLINE.SYSDEBUG
//SYSIN    DD  *
  COPY INDD=((STGODL,R)),OUTDD=PRMODL
  SELECT MEMBER=" + $componentName + "
//*)IM CMN$$PRO
//CPY1ONL EXEC PGM=IEBCOPY,    *** PROMOTION OF ONL
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//*)IM CMN$$ENQ
//SYSUT3   DD  DISP=(MOD,DELETE),
//             DSN=DESV.LIB.ONLINE.LOAD.ENQ,
//             UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//STGONL   DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".ONL
//PRMONL   DD  DISP=SHR,DSN=DESV.LIB.ONLINE.LOAD
//SYSIN    DD  *
  COPYMOD INDD=((STGONL,R)),OUTDD=PRMONL
  SELECT MEMBER=" + $componentName + "
//*)IM CMN$$PRO
//CPY1PKG EXEC PGM=IEBCOPY,    *** PROMOTION OF PKG
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//*)IM CMN$$ENQ
//SYSUT3   DD  DISP=(MOD,DELETE),
//             DSN=DESV.LIB.PKGLIB.ENQ,
//             UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//STGPKG   DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".PKG
//PRMPKG   DD  DISP=SHR,DSN=DESV.LIB.PKGLIB
//SYSIN    DD  *
  COPY INDD=((STGPKG,R)),OUTDD=PRMPKG
  SELECT MEMBER=" + $componentName + "
//*)IM CMN$$PRO
//CPY1SRC EXEC PGM=IEBCOPY,    *** PROMOTION OF SRC
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//*)IM CMN$$ENQ
//SYSUT3   DD  DISP=(MOD,DELETE),
//             DSN=DESV.LIB.SOURCE.ENQ,
//             UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//STGSRC   DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".SRC
//PRMSRC   DD  DISP=SHR,DSN=DESV.LIB.SOURCE
//SYSIN    DD  *
  COPY INDD=((STGSRC,R)),OUTDD=PRMSRC
  SELECT MEMBER=" + $componentName + "
//*)IM CMN$$PRO
//CPY1DBR EXEC PGM=IEBCOPY,    *** PROMOTION OF DBR
//             COND=(4,LT)
//SYSPRINT DD  SYSOUT=*
//*)IM CMN$$ENQ
//SYSUT3   DD  DISP=(MOD,DELETE),
//             DSN=DESV.LIB.DBRMLIB.ENQ,
//             UNIT=SYSDA,SPACE=(CYL,(5,5))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(5,5))
//STGDBR   DD  DISP=SHR,DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber+ ".DBR
//PRMDBR   DD  DISP=SHR,DSN=DESV.LIB.DBRMLIB
//SYSIN    DD  *
  COPY INDD=((STGDBR,R)),OUTDD=PRMDBR
  SELECT MEMBER=" + $componentName + "
//* LIBTYPE = DBQ
//* CICSPC  =
//* EXCI    =
//* USROP03 = Y
//* USROP06 =
//*)IM CMN$$CNC
//* NXPRMLV = 10
//* NXPRMNM = DESV
//ONLCNC  EXEC PGM=CMNCICS1,  *** CICS NEWCOPY FOR ONL
//             COND=(4,LT),
//             PARM=(XCI,CHECK,ZMF)
//STEPLIB  DD  DISP=SHR,
//             DSN=SYSU.MG1D.CMNZMF.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSU.MG1D.SERCOMC.PROD.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.CMNZMF.LOAD
//         DD  DISP=SHR,
//             DSN=SYSP.SERCOMC.LOAD
//         DD  DISP=SHR,DSN=SYS1.CTSD.SDFHEXCI
//SYSPRINT DD  DISP=(,PASS),DSN=&&LISTCNC,
//             UNIT=SYSDA,SPACE=(CYL,(5,5),RLSE),
//             DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SYSIN    DD  *
  TARGET=RDA1,PHA
  DFHRPL=DESV.LIB.ONLINE.LOAD
  PROGRAM=" + $componentName + "
  TARGET=RDA2,PHA
  DFHRPL=DESV.LIB.ONLINE.LOAD
  PROGRAM=" + $componentName + "
  TARGET=RDB1,PHA
  DFHRPL=DESV.LIB.ONLINE.LOAD
  PROGRAM=" + $componentName + "
//*)IM CMN$$CNC END
//*)IM CMN$$CLN
//*)IM CMN$$PST
//*)IM CMN00
//HEXA001  EXEC PROC=DSORT,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SORTIN   DD *
CORE; FUN=SELPROM,NOD=LOCAL
CORE; LVL=10,LNM=DESV,CID=" + $userName + "
CORE; SUP=NO,SSI=78482633
CORE; TYP=ODL
CORE; CMP=" + $componentName + "
CORE; TYP=ONL
CORE; CMP=" + $componentName + "
CORE; TYP=PKG
CORE; CMP=" + $componentName + "
CORE; TYP=SRC
CORE; CMP=" + $componentName + "
CORE; TYP=DBR
CORE; CMP=" + $componentName + "
CORE; FUN=END
CORE  FUN=32,CID=" + $userName + "
//*
//SORTOUT  DD DSN=&HEXA001,
//            DISP=(NEW,CATLG),SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  OPTION   COPY
  OUTREC   FIELDS=(1,4,X'000" + $HEX + "55000002',5,30)
//HEXA002  EXEC PROC=DSORT,COND=(0,NE)
//SYSPRINT DD SYSOUT=*
//SORTIN   DD *
 LVL=10
 LNM=DESV
 SSI=78482633
 OID=SELPROM
 NOD=LOCAL,FUN=04,CID=" + $userName + "
 FUN=21,CID=" + $userName + "
//*
//SORTOUT  DD DSN=&HEXA002,
//            DISP=(NEW,CATLG),SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  OPTION   COPY
  OUTREC   FIELDS=(1,4,X'000" + $HEX + "6300000000',5,30)
//SUCCESS EXEC PGM=CMNBATCH,   *** Access ChangeMan ZMF started task
//             COND=(4,LT),
//             PARM='SUBSYS=P,USER=" + $userName + "'
//*)IM CMN$$SPR
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SYSPRINT DD  DISP=(,PASS),DSN=&&LIST91,
//             UNIT=SYSDA,SPACE=(CYL,(5,5),RLSE),
//             DCB=(RECFM=FA,LRECL=133,BLKSIZE=0)
//SERPRINT DD  SYSOUT=*
//CMNDELAY DD  DISP=SHR,DSN=CMNP.MG1D.CMNZMF.CMNDELAY
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  DISP=SHR,DSN=&HEXA001
//*)IM CMNPRMER
//*)IM CMN99
//CHKCOND EXEC PGM=IEFBR14,    *** CHECK PREVIOUS RETURN CODES
//             COND=(8,LE)
//FAILURE EXEC PGM=CMNBATCH,   *** NOTIFY USER PROCESS HAS FAILED
//             COND=(EVEN,(0,EQ,CHKCOND)),
//             PARM='SUBSYS=P,USER=" + $userName + "'
//*)IM CMN$$SPR
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SERPRINT DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//CMNDELAY DD  DISP=SHR,DSN=CMNP.MG1D.CMNZMF.CMNDELAY
//ABNLIGNR DD  DUMMY
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  DISP=SHR,DSN=&HEXA002
//*)IM CMN$$PCP
//PRINT   EXEC PGM=SERPRINT,   *** MERGE SYSPRINT DATASETS
//             COND=EVEN,
//             PARM=('INDSN(LIST*)',
//             'OUTFILE(PRINT2)')
//PRINT1   DD  DISP=(,PASS),DSN=&&LIST,
//             UNIT=SYSDA,SPACE=(CYL,(50,50),RLSE),
//             DCB=(RECFM=VBM,LRECL=140,BLKSIZE=0)
//PRINT2   DD  SYSOUT=*,DCB=(RECFM=VBM,LRECL=140,BLKSIZE=0)
//*)IM CMNRPMDL
//*
//*  PROMOTION CLEANUP AT DEVELOPMENT SITE
//*
//CLNLCL  EXEC PGM=IDCAMS,     *** DELETE JCL LIBRARY
//             COND=EVEN
//SYSPRINT DD  SYSOUT=*
//SYSIN    DD  *
 DEL 'CMNP.MG1D.STG.CORE.#002737.S3AC2990'
 SET MAXCC = 0
//*
//*)IM CMNPRMER END
//*)IM CMN$$PRM END"

                }
            }
        }
    }
}
####################################################################################
#                        main                                                      #
####################################################################################
function mainWindow {

    Write-Host "mainWindow"

    $frmMainWindow = New-Object System.Windows.Forms.Form
    $frmMainWindow.Text = $lblMainWindowTxt
    $frmMainWindow.Size = New-Object System.Drawing.Size(350, 300)
    $frmMainWindow.FormBorderStyle = "FixedDialog"
    $frmMainWindow.MaximizeBox = $false
    $frmMainWindow.StartPosition = 'CenterScreen'


    $lblPackage = New-Object System.Windows.Forms.Label
    $lblPackage.Location = New-Object System.Drawing.Point(10, 10)
    $lblPackage.Size = New-Object System.Drawing.Size(60, 20)
    $lblPackage.Text = $lblPackageTxt
    $frmMainWindow.Controls.Add($lblPackage)


    $txtBoxPackage = New-Object System.Windows.Forms.TextBox
    $txtBoxPackage.Location = New-Object System.Drawing.Point(70, 10)
    $txtBoxPackage.Size = New-Object System.Drawing.Size(120, 20)
    $txtBoxPackage.Text = $txtPackageTxt
    $txtBoxPackage.MaxLength = 10
    $txtBoxPackage.CharacterCasing = 'Upper'
    $txtBoxPackage.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                #logic
                listPackageComponents
            }
        })
    $frmMainWindow.Controls.Add($txtBoxPackage)


    $btnList = New-Object System.Windows.Forms.Button
    $btnList.Location = New-Object System.Drawing.Point(200, 10)
    $btnList.Size = New-Object System.Drawing.Size(75, 23)
    $btnList.Text = $btnListTxt
    $btnList.Add_Click({ listPackageComponents })
    $frmMainWindow.Controls.Add($btnList)


    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Location = New-Object System.Drawing.Point(10, 30)
    $lblUser.Size = New-Object System.Drawing.Size(60, 20)
    $lblUser.Text = $lblUserTxt
    $frmMainWindow.Controls.Add($lblUser)


    $txtBoxUser = New-Object System.Windows.Forms.TextBox
    $txtBoxUser.Location = New-Object System.Drawing.Point(70, 30)
    $txtBoxUser.Size = New-Object System.Drawing.Size(120, 20)
    $txtBoxUser.CharacterCasing = 'Upper'
    $txtBoxUser.Text = $User
    $txtBoxUser.MaxLength = 6
    $txtBoxUser.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                #logic
                listPackageComponents
            }
        })
    $frmMainWindow.Controls.Add($txtBoxUser)


    $listViewComponents = New-Object System.Windows.Forms.ListView
    $listViewComponents.Location = New-Object System.Drawing.Point(10, 50)
    $listViewComponents.Size = New-Object System.Drawing.Size(315, 170)
    $listViewComponents.CheckBoxes=$false
    $listViewComponents.AutoArrange=$true
    $listViewComponents.GridLines=$true
    $listViewComponents.MultiSelect=$true
    $listViewComponents.AllowColumnReorder = $true
    $listViewComponents.View = "Details"
    $listViewComponents.Columns.Add("Name")
    $listViewComponents.Columns[0].Width = -2
    $listViewComponents.Columns.Add("Type")
    $listViewComponents.Columns[1].Width = -2
    $listViewComponents.Columns.Add("Status")
    $listViewComponents.Columns[2].Width = -2
    $listViewComponents.Columns.Add("RC")
    $listViewComponents.Columns[3].Width = -2
    $frmMainWindow.Controls.Add($listViewComponents)


    $btnPush = New-Object System.Windows.Forms.Button
    $btnPush.Location = New-Object System.Drawing.Point(85, 230)
    $btnPush.Size = New-Object System.Drawing.Size(75, 23)
    $btnPush.Text = $btnPushTxt
    $btnPush.Add_Click({ pushComponent })
    $frmMainWindow.Controls.Add($btnPush)


    $btnPull = New-Object System.Windows.Forms.Button
    $btnPull.Location = New-Object System.Drawing.Point(10, 230)
    $btnPull.Size = New-Object System.Drawing.Size(75, 23)
    $btnPull.Text = $btnPullTxt
    $btnPull.Add_Click({ pullComponent })
    $frmMainWindow.Controls.Add($btnPull)

    $btnPromote10 = New-Object System.Windows.Forms.Button
    $btnPromote10.Location = New-Object System.Drawing.Point(160, 230)
    $btnPromote10.Size = New-Object System.Drawing.Size(75, 23)
    $btnPromote10.Text = $btnPullTxt
    $btnPromote10.Add_Click({ promote10 })
    $frmMainWindow.Controls.Add($btnPromote10)

    $btnExit = New-Object System.Windows.Forms.Button
    $btnExit.Location = New-Object System.Drawing.Point(250, 230)
    $btnExit.Size = New-Object System.Drawing.Size(75, 23)
    $btnExit.Text = $btnExitTxt
    $btnExit.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $frmMainWindow.CancelButton = $btnExit
    $frmMainWindow.Controls.Add($btnExit)


    $progressBarAmount = 100
    $progressBar = New-Object System.Windows.Forms.progressBar
    $progressBar.Minimum = 0
    $progressBar.Maximum = $progressBarAmount
    $progressBar.Location = new-object System.Drawing.Size(10, 215)
    $progressBar.size = new-object System.Drawing.Size(315, 10)
    $frmMainWindow.Controls.Add($progressBar)

    $frmMainWindow.Topmost = $true
    $frmMainWindow.ShowDialog()

}
####################################################################################
#                                main                                              #
####################################################################################

Write-Host "begin"

mainWindow

Write-Host "end"
