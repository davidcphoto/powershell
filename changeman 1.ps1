Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


####################################################################################
#  Definitions                                                                     #
####################################################################################
$user = ""
switch ($env:USERNAME) {
    'd.fonseca.do.canto' {
        $user = 'X93182'
    }
    'daniel.t.rodrigues' {
        $user = 'XZ0670'
    }
    'paulo.a.bigas' {
        $user = 'X93295'
    }
    Default {
        $user = 'X#####'
    }
}
$compileJCLSuffix = '##'
#
$ListaPAcotes = @()
$lblMainWindowTxt = 'ChangeMan'
$lblPackageTxt    = 'Package'
$lblUserTxt       = 'User'
$btnPullTxt       = 'Pull'
$btnPushTxt       = 'Push'
$btnExitTxt       = 'Exit'
$btnListTxt       = 'List'
$txtPackageTxt    = 'CORE'
$btnPromoteTxt    = "Promote"

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

    if ($cmbBoxPackage.Text.Length -ne 9){
        $cmbBoxPackageNumber = $cmbBoxPackage.Text.substring(4)
        ##Write-Host $cmbBoxPackageNumber
        $cmbBoxPackageNumberMax = $cmbBoxPackageNumber.padleft(6,'0')
        ##Write-Host $cmbBoxPackageNumberMax
        ##$cmbBoxPackage = $cmbBoxPackage.Text.substring(0,4) + $cmbBoxPackageNumberMax
        ##Write-Host $cmbBoxPackage
        $packageNumber = $cmbBoxPackageNumberMax
        $cmbBoxPackage.Text = $cmbBoxPackage.Text.substring(0,4) + $cmbBoxPackageNumberMax
    }
    else{
        $packageNumber = $cmbBoxPackage.Text.substring($cmbBoxPackage.Text.Length - 6)
    }



    Write-Host "   | " $cmbBoxPackage.Text

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

    $cmbBoxPackage.Items.Add($cmbBoxPackage.Text)
    $Global:ListaPAcotes += $cmbBoxPackage.Text

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
            $componentItem.SubItems.Add("")
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
            $componentItem.SubItems.Add("")
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
            $componentItem.SubItems.Add("")
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
    $packageNumber = $cmbBoxPackage.Text.Substring(4, 6)
    $userName = $txtBoxUser.Text

    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {
        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        $listViewComponents.SelectedItems.Item($i).SubItems[4].Text = ''
        $listViewComponents.SelectedItems.Item($i).SubItems[5].Text = '00'
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

            $job = "//" + $userName + "PS JOB (851,985,995),'PUSH::$componentName',
//         MSGCLASS=X,CLASS=D
//*
//*        -----------------------------------------------------------
//*        IEBCOPY: COPIA DE ELEMENTO DE UM UTILIZADOR PARA O PACOTE
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
JC1=//" + $userName + $compileJCLSuffix + " JOB ,'COMPILE::CORE$packageNumber',MSGCLASS=X,
JC2=//         NOTIFY=$userName,CLASS=N
JC3=//*
JC4=//*
SUP=N,
UPN=CMNUSR01,
IJN=N,
DSN=CMNP.MG1D.STG.CORE.#$packageNumber.$componentExtension,
CMP=$componentName,
CNT=00001"
        }
        elseif ($componentExtension -eq "unl") {
            $componentType = "UNLOAD"
            $job = "//" + $userName + "PS JOB (851,985,995),'Push - $componentName',
//         NOTIFY=" + $userName + ",CLASS=N
//*
//*
//*
//* THE ABOVE JOB CARDS CAME FROM THE IMBED OF SKEL CMN$$JCD
//*)IM CMN$$JCD
//*
//*  JOB REQUESTED BY " + $userName + " ON 2023/12/13 AT 15:04
//*
//*)IM CMN$$DSN
//* LANG    =
//* PROC    =
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
//*)IM CMNSRVC
//*
//CMNSRVC EXEC PGM=CMNVSRVC,
//             COND=(4,LT),
//             PARM='SUBSYS=P,USER=" + $userName + "'
//*)IM CMN$$SPR
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SERRPLY  DD  SYSOUT=*,
//             DCB=(RECFM=VB,LRECL=4080,BLKSIZE=0)
//SERPRINT DD  SYSOUT=*                             TRACE OUTPUT
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  *
OBJ=CMPONENT,MSG=CHECKIN,PKN=CORE" + $packageNumber + ",
LTP=UNL,CKF=1,SLT=9,
LIB=" + $userName + ".LIB.UNLOAD,
LOK=N,SPV=Y,CCD=                               ,
SUP=N,
TMN=AMU01D11,
CNT=00001
"
        }
        $progressBar.Value = 2

        $job | Out-file -encoding ASCII -noNewline -FilePath "$env:TEMP\Job.JCL"

        $progressBar.Value = 3

        jobSubmit 'Push'

        # Não é possível deletar jobs de compilação...
        #@(listJobs '' $userName$compileJCLSuffix 'jobid') | ForEach-Object {purgeJobByJobID $_}


        if (jobSubmit -jobType 'Push')
        {
            $compilationJobID = ''
            @(listJobs '' $userName$compileJCLSuffix '') | ForEach-Object {if($_.status -eq "ACTIVE"){$compilationJobID = $_.jobid}}
            #Write-Host $compilationJobID
            if ($compilationJobID -eq '') {
                @(listJobs '' $userName$compileJCLSuffix '') | ForEach-Object {if($_.status -eq "ACTIVE"){$compilationJobID = $_.jobid}}
                if ($compilationJobID -eq '')
                {
                    @(listJobs '' $userName$compileJCLSuffix '') | ForEach-Object {if($_.status -eq "ACTIVE"){$compilationJobID = $_.jobid}}
                    if ($compilationJobID -eq '')
                    {
                        Write-Host 'Job Not Found'
                    }
                }
            }
        }

        if ($compilationJobID -ne '')
        {
            $listViewComponents.SelectedItems.Item($i).SubItems[4].Text = getJobRC $compilationJobID
        }
        else
        {
            $listViewComponents.SelectedItems.Item($i).SubItems[4].Text = 'n/a'
        }

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
    $packageNumber = $cmbBoxPackage.Text.Substring(4, 6)

    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {

        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        $listViewComponents.SelectedItems.Item($i).SubItems[4].Text = ''
        $listViewComponents.SelectedItems.Item($i).SubItems[5].Text = ''
        Write-Host "   | " $componentName'.'$componentExtension

        $progressBar.Value = 1

        if ($componentExtension -eq "cpy") {
            $componentType = "COPY"
        }
        elseif ($componentExtension -eq "src") {
            $componentType = "SOURCE"
        }
        elseif ($componentExtension -eq "unl") {
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
    if ($jobType -eq 'Promote') {
        $listViewComponents.SelectedItems.Item($i).SubItems[5].Text = '10'
    }
    $progressBar.Value = 4

    #Write-Host   $outputJCL

    $data = $outputJCL | ConvertFrom-Json

    $data.stdout

    switch ($jobType) {
        'Promote' {
            $jobRC = $userName + "PP ENDED - RC="
        }
        'Push' {
            $jobRC = $userName + "PS ENDED - RC="
        }
        'Pull' {
            $jobRC = $userName + "PL ENDED - RC="}
    }

    $jobRCPosition = $data.stdout.LastIndexOf($jobRC)
    $returnCode = $data.stdout.Substring($jobRCPosition+$jobRC.Length,4)
    $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = $returnCode
    if ($returnCode -ne '0000'){
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = $jobType + ' Not Ok'
        return '0'
    }else{
        return '1'}
}
####################################################################################
#                                   getJobRC                                       #
####################################################################################
function getJobRC() {
    Param($FgJRCjobID)
    Write-Host " > getJobRC"
    Write-Host "   | " $FgJRCjobID
    $FgJRCjobRC = 'null'
    do{
        $FgJRCjobRC =  (zowe zos-jobs view job-status-by-jobid $FgJRCjobID --rff retcode --rft string)
    }
    while ($FgJRCjobRC -eq 'null')
    return $FgJRCjobRC.Substring(3, 4)
}
####################################################################################
#                                   purgeJobByJobID                               #
####################################################################################
function purgeJobByJobID() {
    Param($FpJBJIjobID)
    Write-Host " > purgeJobByJobID"
    Write-Host "   | " $FpJBJIjobID
    $FpJBJIdeletedJob = @(zowe zos-jobs delete job $FpJBJIjobID)
    Write-Host $FpJBJIdeletedJob
}
####################################################################################
#                                   listJobs                                       #
####################################################################################
function listJobs() {
    Param($FlJjobOwner, $FlJjobPrefix, $FlJjobListFilter)
    Write-Host " > listJobs"
    Write-Host "   | " $FlJjobOwner $FlJjobPrefix $FlJjobListFilter
    $FlJOutput = @()

    if ($FlJjobOwner -eq ''){
        $FlJjobOwner = '*'
    }

    if ($FlJjobPrefix -eq ''){
        $FlJjobPrefix = '*'
    }

    if ($FlJjobListFilter -eq ''){
        $FlJOutput = @(zowe zos-jobs list jobs -o $FlJjobOwner -p $FlJjobPrefix --rft list) | ConvertFrom-Json
    }
    else {
        $FlJOutput = @(zowe zos-jobs list jobs -o $FlJjobOwner -p $FlJjobPrefix --rft list --rff $FlJjobListFilter) | ConvertFrom-Json
    }

    #Write-Host $FlJOutput
    #Write-Host $FlJOutput[0].jobid
    #Write-Host $FlJOutput[0].retcode
    #Write-Host $FlJOutput[0].status
    #return $FlJOutput | ConvertFrom-Json

    return $FlJOutput

}
####################################################################################
#                       refreshList                                                #
####################################################################################
function refreshList {
    Write-Host " > refreshList"

    $progressBar.Value = 0
    $progressBar.Refresh

    $listViewComponents.SelectedItems.Clear()
    $listViewComponents.Refresh()

    $listViewComponents.Columns[0].Width = -1
    $listViewComponents.Columns[1].Width = -2
    $listViewComponents.Columns[2].Width = -2
    $listViewComponents.Columns[3].Width = -2
    $listViewComponents.Columns[4].Width = -2
    $listViewComponents.Columns[5].Width = -2
}

####################################################################################
#                                 Promote10                                        #
####################################################################################

function promote10() {

    Write-Host " > promote10"

    $packageNumber = $cmbBoxPackageNumberMax
    Write-Host "  packageNumber " + $packageNumber

    # $dec = $packageNumber
    # $hex = $dec.ToString("x")
    # Write-Host $hex

    $progressBar.Maximum = 5
    $packageNumber = $cmbBoxPackage.Text.Substring(4, 6)
    $userName = $txtBoxUser.Text


    for ($i = 0; $i -lt $listViewComponents.SelectedItems.Count; $i++) {
        $componentName= $listViewComponents.SelectedItems.Item($i).SubItems[0].Text
        $componentExtension = $listViewComponents.SelectedItems.Item($i).SubItems[1].Text
        $listViewComponents.SelectedItems.Item($i).SubItems[2].Text = '-'
        $listViewComponents.SelectedItems.Item($i).SubItems[3].Text = ''
        Write-Host "   | " $componentName'.'$componentExtension
        $progressBar.Value = 1

        if ($componentExtension -eq "src") {

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
            $progressBar.Value = 2
            $job = "//" + $userName + "PP JOB (851,985,995),'Push - $componentName',
//" + $userName + "PP JOB ,'PROM.QUAL CORE" + $packageNumber + "',MSGCLASS=X,
//         NOTIFY=" + $userName + ",CLASS=N
//*
//*
//*
//* THE ABOVE JOB CARDS CAME FROM THE IMBED OF SKEL CMNSSJCD
//*)IM CMNSSJCD
//*
//*  JOB REQUESTED BY " + $userName + " ON 2023/12/14 AT 13:12
//*
//*)IM CMNSSDSN
//* LANG    =
//* PROC    = BMPCOBE
//* SIGYCMP = SYS1.ADCOB.SIGYCOMP
//*)IM CMNSSJBL
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
  DELETE (CMNP.TEMP.CORE.#" + $packageNumber + "." + $componentName + ".S1) NONVSAM
  SET MAXCC = 0
/*
//*
//CMNSRVC EXEC PGM=CMNVSRVC,
//             COND=(4,LT),
//             PARM='SUBSYS=P,USER=" + $userName + "'
//*)IM CMNSSSPR
//SER#PARM DD  DISP=SHR,DSN=SYSU.MG1D.SERCOMC.PROD.V8R2P05.TCPIPORT
//SERRPLY  DD  SYSOUT=*,
//             DCB=(RECFM=VB,LRECL=4080,BLKSIZE=0)
//SERPRINT DD  DISP=(,CATLG),
//             DSN=CMNP.TEMP.CORE.#$packageNumber.$componentName.S1,
//             UNIT=SYSDA,SPACE=(CYL,(5,5),RLSE),
//             DCB=(RECFM=FBA,LRECL=133,BLKSIZE=0)
//SYSUDUMP DD  SYSOUT=*
//SYSIN    DD  *
OBJ=CMPONENT,MSG=CHECKIN,PKN=CORE" + $packageNumber + ",
LTP=SRC,CKF=1,SLT=6,
LIB=" + $userName + ".LIB.SOURCE,
LOK=N,SPV=Y,CCD=                               ,
SUP=N,
TMN=" + $componentName + ",
CNT=00001
OBJ=CMPONENT,MSG=BUILD,PKN=CORE" + $packageNumber + ",
LTP=SRC,PRC=BMPCOBE ,LNG=COBOLE  ,
$sourceType
DB2=Y,DBS=DB2D,DBL=SYS1.DB2.SDSNLOAD                           ,
JC1=//" + $userName + "Q JOB ,'PROM.DESV CORE" + $packageNumber + "',MSGCLASS=X,                       ,
JC2=//         NOTIFY=" + $userName + ",CLASS=N                                        ,
JC3=//*                                                                     ,
JC4=//*                                                                     ,
SUP=N,
UPN=CMNUSR01,
IJN=N,
DSN=CMNP.MG1D.STG.CORE.#" + $packageNumber + ".SRC,
CMP=" + $componentName + ",
CNT=00001"
        }

        $progressBar.Value = 3
        $job | Out-file -encoding ASCII -noNewline -FilePath "$env:TEMP\Job.JCL"

        $progressBar.Value = 4

        jobSubmit 'Promote'

        $progressBar.Value = 5
    }

    refreshList

    $listViewComponents.Columns[1].Width = -2
    $listViewComponents.Columns[2].Width = -2
    $listViewComponents.Columns[3].Width = -2
    $listViewComponents.Columns[4].Width = -2
    $listViewComponents.Columns[5].Width = -2

    Write-Host ' (waiting)'
    return
}
####################################################################################
#                        le lista de packages                                      #
####################################################################################
function Obtemdados() {

    $path = $script:PSScriptRoot.ToString()
    $json = Get-Content -Path $path\Packages.json -Raw | ConvertFrom-Json

    # Loop through the objects in the JSON data
    foreach ($object in $json.PSObject.Properties) {

        Write-Host "Object name  : $($object.Name) Object value : $($object.Value)"

        switch ($($object.Name)) {
            "user" {
                # Clear-Variable -Name user
                $global:user = $($object.Value)
            }
            "packages" {

                $objectproperties =  $object.Value
                 Write-Host '$objectproperties ' objectproperties

                foreach ($Value in $objectproperties) {

                    Write-Host "Pacote Property name: $($Value)"
                    $cmbBoxPackage.Items.Add($($Value))
                    $Global:ListaPAcotes += $($Value)

                }
            }
        }

    }

}
####################################################################################
#                        Grava lista de packages                                   #
####################################################################################
function salvaDados() {

    Write-Host ' salvaDados'

    $path = $script:PSScriptRoot.ToString()
    $ficheiro = '{"user":"' + $User + '"'


    if ($Global:ListaPAcotes.Count -gt 0) {

        $ficheiro = $ficheiro + ',"packages":["'

        for ($i = 0; $i -lt $Global:ListaPAcotes.Count; $i++) {

            Write-Host ' $Global:ListaPAcotes[' $i '] ' $Global:ListaPAcotes[$i]
            $ficheiro = $ficheiro + $Global:ListaPAcotes[$i]
            if ($i -le $Global:ListaPAcotes.Count - 2) {
                $ficheiro = $ficheiro + '","'
            }
        }
        $ficheiro = $ficheiro + '"]'
    }


    $ficheiro = $ficheiro + '}'
    $ficheiro | Out-file -encoding ASCII -noNewline -FilePath "$path\Packages.json"




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


    # $cmbBoxPackage = New-Object System.Windows.Forms.TextBox
    # $cmbBoxPackage.Location = New-Object System.Drawing.Point(70, 10)
    # $cmbBoxPackage.Size = New-Object System.Drawing.Size(120, 20)
    # $cmbBoxPackage.Text = $txtPackageTxt
    # $cmbBoxPackage.MaxLength = 10
    # $cmbBoxPackage.CharacterCasing = 'Upper'
    # $cmbBoxPackage.Add_KeyDown({
    #         if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
    #             #logic
    #             listPackageComponents
    #         }
    #     })
    # $frmMainWindow.Controls.Add($cmbBoxPackage)

    $cmbBoxPackage = New-Object System.Windows.Forms.ComboBox
    $cmbBoxPackage.Location = New-Object System.Drawing.Point(70, 10)
    $cmbBoxPackage.Size = New-Object System.Drawing.Size(120, 20)
    $cmbBoxPackage.Text = $txtPackageTxt
    $cmbBoxPackage.MaxLength = 10
    $cmbBoxPackage.MaxDropDownItems = 10
    $cmbBoxPackage.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                #logic
                listPackageComponents
            }
        })
    $frmMainWindow.Controls.Add($cmbBoxPackage)


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
    $listViewComponents.Columns.Add("Compile RC")
    $listViewComponents.Columns[4].Width = -2
    $listViewComponents.Columns.Add("Level")
    $listViewComponents.Columns[5].Width = -2
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
    $btnPromote10.Text = $btnPromoteTxt
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

    Obtemdados

    $frmMainWindow.Topmost = $true
    $frmMainWindow.ShowDialog()

    salvaDados

}
####################################################################################
#                                main                                              #
####################################################################################

Write-Host "begin"

mainWindow

Write-Host "end"