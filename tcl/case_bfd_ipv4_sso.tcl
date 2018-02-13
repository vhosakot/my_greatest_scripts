#!/bin/sh
# \
    exec $AUTOTEST/bin/tclsh $0 ${1+"$@"}

# The above three lines are the standard way of invoking the TCL interpretor

##Script Header
# Copyright (c) 2009-2010 by Cisco Systems, Inc.
#
# Name:
#     case_bfd_ipv4_sso.tcl
#
# Purpose:
#     To automate the testcases found in EDCS-603730
#     Uses AE Test and METAL as a package.
#
# Author:
#     patring, bfd-devtest
#
# Support Alias:
#     bfd-devtest@cisco.com
#
# Description:
#     This automates the testcases in EDCS-603730 section 11.1.11
#     The intent of this case is to test the behavior of the 
#     BFD feature with SSO (EFSU) for Whitney2 (6500) 
#     
#
# Case Name
# case_bfd_ipv4_sso
#
# Case number
# 11.1.11   Verify BFD sessions with aggressive trasmit and receive timers
#          (500msec * 3) does not flap during perfroming SSO
#
# Topology:
#      Refer input files for topology info. A two router and two pagent topology
#      is required as a minimum.
#      All Testbed configuration is contained within inputfile.
#
#     Pgnt1--- R1(dut)-------R2---Pgnt2
#                       
#   The following is expectd of the METAL based input file:
#   All interfaces are up and should be able to ping from HEAD to TAIL
#
#
# Synopsis:
#     case_bfd_ipv4_sso.tcl  -tid <name> -metal_input_file <file>
#           -rut
#           -v4client <v4client_protocol>
#           [-pollTime <integer>] [-notraceback]
#           [-altDirectory <directory path>]
#           [-metal_debug <list|0>] [-metal_package_path <dir>] 
#           [--help] [--version] 
#
# Arguements:
#   Required
#     -tid <name> Test name idenitfier 
#     -metal_input_file <file>   The input file to be parsed
#     -rut <Router>  Router under test
#     -v4client <v4client_protocol> Client protocols supported by BFD IPv4    
#     
#   Optional (testcase specific)
#     -altDirectory <path> Directory where testcase specific library file is 
#     -pollTime <number> Seconds to poll for CLI to update (default: 180)
#
#   Optional (template specific)
#     -metal_debug <list|0>      Set the metal debug level, or turn it off
#                                Choices (or all): ion te_parser 
#                                 (default is input_file debug level)
#     -metal_package_path <dir>  Directory that has a pkgIndex to be 
#                                sourced.  This is supplied to over-write the 
#                                version of metal to be sourced
#     --help                     Show help
#     --version                  Show version info  
#
#   Optional (aetest specific)
#     -aetest_run_ids <casenames>  Will run just these case names and any
#                  dependancies needed
#     -aetest_skip_ids <casenames> Will not run just these case names and any
#                  dependancies needed
#   
# Sample Usage:
#     case_bfd_ipv4_sso.tcl 
#                -tid bfd_ipv4_6500_sso
#                -metal_input_file bfd_ipv4_6500_sso.input
#                -rut R1
#                -v4client ospf isis eigrp
#                                  
#                 
#
# Pass/Fail Criteria:
#     All tests must pass
#
# Sections of overall file:
#     0) Initialize script
#     1) Parse arguments
#     2) Overwrite ml_global flags, and fileParse
#     3) Validate Flags
#     4) Configure Testbed
#     5) Verify the topology 
#     6) Run testcase 
#     7) Unconfigure Testbed
#
# Known Bugs:
#     <Project>; <Component>; ?attributes?; <Bug Number 1>
#
# End of Header

###############################################################################
# CHANGE LOG
#
# DATE       BUG#       username    Comment
# ---------- ---------- ----------- -------------------------------------------
# 10-01-2008  CSCsq74234 patring     Initial release
# 03-13-2009  CSCsy40501 patring     CEF new BFD client, took more time to remove
# 03-27-2009  CSCsy62063 patring     Add chkpt verification before and after SSO 
# 04-01-2009  CSCsy85422 patring     Add frr check per CSCsy74693 fixed
# 06-10-2009  CSCta08751 patring     Measure BFD session Uptime after peer SSO 
# 07-27-2009  CSCtb01534 patring     Add delays when integrating into c10k
# 11-23-2010  CSCtj71030 jrodowic    Adding tests for BFD Async mode
#
# END CHANGE LOG
###############################################################################


########################################
##### TEST SCRIPT INITIALIZATION    ####
########################################


# Just a cleanup of argv (sometimes argv is different... not sure why)
if {![info exists argv0] || $argv0 == [lindex $argv 0]} {
    set argv0 [lvarpop argv]
}

# AtsAuto package includes base packages
package require AtsAuto

set mandatory_args {
    -metal_input_file   ANY
    -rut                ANY
    -v4client           ANY    
}

set optional_args {
    -altDirectory       ANY
    -sleepInt           DECIMAL
                        DEFAULT 90
    -pollInt            DECIMAL
                        DEFAULT 30
    -noTracebackCheck   FLAG
}


########################################
### TESTCASE DEPENDANCIES [CUSTOMIZE]
########################################
set tc_dependancies {
}

set passArgs $argv
set testcaseLib "$expect_library/csetest_tools/testcase_lib.tcl"

###############
# Source our testcase lib file from autotest to give us some helper procs and
# basic parsers

if {![catch {source $testcaseLib} err]} {
    if {[set tmp [parseBasicArgs]]} {
    return $tmp
    }
} else {
    ats_log -error "Error sourcing testcase_lib!"
    ats_log -error "$err"
    return 1
}


############### 
#Call the aetest::script_init function... don't change this!

if {[catch {aetest::script_init -return_array _flags \
    -mandatory_args $mandatory_args \
    -optional_args $optional_args \
    -tc_dependencies $tc_dependancies} aetestError]} {
    ats_log -error "Error initializing aetest: $aetestError"
    return 1
}


###############
# Variable initializations

set tN "case_bfd_ipv4_sso"
set gr_configured 0

set HeadRtr      ""
set TailRtr      ""
set DutAddr    ""
set TailAddr   ""
set Tail_addr_mask ""
set sleepInterval 90
set bfd_chkpt   Chkpt

##############################################
##### COMMON SETUP SECTION
##############################################
aetest::section common_setup {
    
    ############################################
    # The following will do generic csetest setup
    if {[csetest_common_setup] < "1"} {
        ats_results -result "fail"
        aetest::goto common_cleanup
    }


    ########################################################
    #Validate correct flags were passed 
    ml_checkFlags _flags {} -reportAll
    
    
    #Set the values
    if {[info exists _flags(sleepInt)]} {
        set sleepInterval $_flags(sleepInt)
    }
    
    set rut $_flags(rut)
    if {$rut == ""} {
        ml_error "$tN: Missing/incorrect parameters ... Required args \
                                are -rut <rut>"
        ats_results -result "fail" 
        aetest::goto common_cleanup
    }

    set v4client $_flags(v4client)
    if {$v4client == ""} {
        ml_error "$tN: Missing/incorrect parameters ... Required args\
                                are -v4client <v4client_protocol>"
        ats_results -result "fail" 
        aetest::goto common_cleanup
    }
    
    
    ########################################################
    # Outline main steps
    ml_testStep 1 "Source all needed support files" 
    ml_testStep 2 "Check for the flags passed"
    ml_testStep 3 "Check input file for proper topology configuration"
    ml_testStep 3.1 "Check if the standy RP is in ready state"
    ml_testStep 3.2 "Check for tracebacks before configuring the topology"
    ml_testStep 4 "Configure topology"
    ml_testStep 4.1 "Check for tracebacks after configuring the topology"
    ml_testStep 5 "Make sure all interfaces are up"
 
    
    set myPath [ml_getVar _flags(altDirectory) \
    "$expect_library/../../regression/tests/functionality/mplstest/TE/feature/bfd"]

    ########################################
    #### Source all needed files
    ml_testStep 1
    set neededFiles "
        metal_ha_lib.itcl \
        metal_te_sso_support.itcl \
        metal_device_support.itcl \
        metal_vpn_lib.itcl \
        metal_vpn_ion_lib.itcl \
        metal_ion_lib.itcl \
        metal_bfd_support.itcl \
        $myPath/bfd_proc.itcl \
    "

    if {[info exists ml_global(case_library)]} {
        lappend neededFiles $ml_global(case_library)
    }
    
    foreach file $neededFiles {
    if {[ml_sourceFile $file] != 1} {
        ml_error "Could not source file $file"
        ats_results -result "fail"
        aetest::goto common_cleanup
        }
    }

    
    #######################################################
    #Get the flags passed 
    ml_testStep 2
    
    global SUCCESS ERROR  ml_global csccon_state
    ml_getVar ERROR 0 -set
    ml_getVar SUCCESS 1 -set
    ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
    set maxTries [ml_getVar _flags(maxTries) 6]
    set pollInt [ml_getVar _flags(pollInt) 30]
    set maxWait [expr {$maxTries * $pollInt}]
    set pingRepeat [ml_getVar _flags(pingRepeat) 15]
    
    set srcPagentLoc   [ml_getVar ml_global(tgnInt)  "" -set]
    ml_debug "srcPagentLoc = $srcPagentLoc"
    
    set destPagentLoc   [ml_getVar ml_global(pktsInt) "" -set]
    ml_debug "destPagentLoc = $destPagentLoc"
    
    set rate     [ml_getVar ml_global(rate) "1000" -set]
    set length   [ml_getVar ml_global(pktLen) "256" -set]
    set numStrms [ml_getVar ml_global(streams) "1" -set]
    set maxTrafficLoss [ml_getVar ml_global(maxTrafficLoss) "40" -set]
     
    set maxTrafficLossPR [ml_getVar ml_global(maxTrafficLossPR) "40" -set]

    set Traceback_check 1
    if {[info exists _flags(noTracebackCheck)]} {
        set Traceback_check 0
    }
    
    ##################################################
    # Check input file for proper topology configuration
    # Check for proper number of routers
    ml_testStep 3
    
    ml_debug "Running Topology Check"
    #Determine if we have number of routers mandated is 2 
    set numRtrs 2
    
    set deviceList [ml_getRouters]
    ml_debug "deviceList= $deviceList "
    
    if {[llength $deviceList] < $numRtrs} {
        ml_error "The input file does not have $numRtrs to run\
                    the case.  Needs $numRtrs to run, but found\
                    the following devices: $deviceList"        
        ats_results -result "fail"
        aetest::goto common_cleanup
    }

    #Determine if we have the two pagent routers required for the testcase
    set allDevices $ml_global(deviceList)
    set pagents [lindex [intersect3 $allDevices $deviceList] 0]
    set pagNum  [llength $pagents]
    
    if {$pagNum == 2} {
        foreach router $pagents {
            if {![ml_isPagentRouter $router]} {
                ml_error "$router needs to be a pagent router with supported\
                        image"
                ats_results -result "fail"
                aetest::goto common_cleanup 
            }
        }
    } else {
        ml_error "Topology requires two pagent routers as\
                 Traffic source and destination routers but $pagNum\
                    pagents exist"
        ats_results -result "fail"
        aetest::goto common_cleanup
    }

    #Check required input file variables
    if {($srcPagentLoc == "") || ($destPagentLoc == "")} {
        ml_error "Both tgnInt and pktsInt should be defined in globals\
            section of the input file"
            ats_results -result "fail"
            aetest::goto common_cleanup 
    }
   
    set destPagentRtr [ml_parseInterface $destPagentLoc -parent]
    ml_debug "destPagentRtr = $destPagentRtr"
    
    set srcPagentRtr [ml_parseInterface $srcPagentLoc -parent]
    ml_debug "srcPagnetRtr = $srcPagentRtr"

    set destPagentAddr [$destPagentRtr getAddress "lo0" -ipv4 -noinit]
    ml_debug "destPagentAddr = $destPagentAddr"

    #############################
    # Discover the topology 
    set srcPeerInt [ml_getPeer $srcPagentLoc]
    set dut [ml_parseInterface $srcPeerInt -parent]
    ml_debug "Head router is $dut"
    
    set dstPeerInt [ml_getPeer $destPagentLoc]
    set TailRtr [ml_parseInterface $dstPeerInt -parent]
    ml_debug "Tail router is $TailRtr"
   
    set onePeer ""
    set twoPeers ""
    set threePeers ""
    set status 1
    
    foreach rtr $deviceList {
        set peers [ml_getPeerRtrs $rtr]
        if {[llength $peers] == 1} {
            lappend onePeer $rtr
            continue
        }
        if {[llength $peers] == 2} {
            lappend twoPeers $rtr
            continue
        }
        if {[llength $peers] == 3} {
            lappend threePeers $rtr
            continue
        }
        
        ml_error "One of the routers has more than three peers.\
        $rtr has following routers for peers: $peers"
        set status 0
    }
    
    if {$status == 0} {
        ats_results -result "fail"
        aetest::goto common_cleanup
    }
   
    if {[llength $onePeer] != 0} {
        ml_error "Please check the input file.\
        There should not be any router in the topology has one\
        peers.  All these ($onePeer) routers have one peer"
        ats_results -result "fail"
        aetest::goto common_cleanup
    } 
    
    if {[llength $twoPeers] != 2} {
        ml_error "Please check the input file.\
        There should be two routers in the topology has\
        two peers. All these ($twoPeers) routers have two peers."
        ats_results -result "fail"
        aetest::goto common_cleanup
    } 
    
    if {[llength $threePeers] != 0} {
        ml_error "Please check the input file.\
        There should not be any router in the topology has three\
        peers. All these ($threePeers) routers have three peers."
        ats_results -result "fail"
        aetest::goto common_cleanup
    }
    
       
    #Get the traffic source and destination routers and address
    set destPagentRtr [ml_parseInterface $destPagentLoc -parent]
    ml_debug "destPagentRtr = $destPagentRtr"
    set srcPagentRtr [ml_parseInterface $srcPagentLoc -parent]
    ml_debug "srcPagentRtr = $srcPagentRtr"
    set destPagentAddr [$destPagentRtr getAddress "lo0" -ipv4 -noinit]
    ml_debug "destPagentAddr = $destPagentAddr"

    #Get the interfaces on dut 
    ml_debug "Get the interfaces on $dut"
    
    set srcPeerInt [ml_getPeer $srcPagentLoc]
    set listOfInts [$dut getAllInterfaces -notunnels -noloopback -notftp]
    set int [ml_parseInterface $srcPeerInt] 
    set index [lsearch $listOfInts $int]
    set dut_Int_List [lreplace $listOfInts $index $index]
    
    ml_debug "list of interfaces on $dut = $dut_Int_List"

    #Get the interfaces on TailRtr 
    ml_debug "Get the interfaces on $TailRtr"
    
    set destPeerInt [ml_getPeer $destPagentLoc]
    set listOfInts [$TailRtr getAllInterfaces -notunnels -noloopback -notftp]
    set int [ml_parseInterface $destPeerInt] 
    set index [lsearch $listOfInts $int]
    set TailRtr_Int_List [lreplace $listOfInts $index $index]
    
    ml_debug "list of interfaces on $TailRtr  = $TailRtr_Int_List"
    
    #Check single path is configured between DUT and Tail Rtr
    set path ""

    if {[set path [ml_getPaths $dut $TailRtr]] == ""} {
        ml_error "$tN - Unable to find a path between the\
                        Head Rtr: $dut and Tail Rtr: $TailRtr"
        ats_results -result "fail"
        aetest::goto common_cleanup
    }

    ml_debug "Path between Head Rtr and Tail Rtr is $path"

    if {[llength $path] != 1} {
        ml_error "$tN - Please just configure a single path\
                    between Head Rtr: $dut to Tail Rtr: $TailRtr"
        ats_results -result "fail"
        aetest::goto common_cleanup
    }

    set DutAddr [[ml_getPeer [lindex [lindex $path 0] 1] ] getAddress]
    ml_debug "DUT address is $DutAddr"

    set TailAddr [[ml_getPeer [lindex [lindex $path 0] 0] ] getAddress]
    ml_debug "Tail Rtr address is $TailAddr"

    
    #Get the traffic tunnel physical int on which the traffic is sent
 
    set traffic_tunInt  [lindex [lindex $path 0] 0]
    
    ml_debug "traffic_tunInt == $traffic_tunInt"
    
    set traffic_int  [ml_parseInterface $traffic_tunInt]

    ####################################################
    # Verify DUT standby RP is ready
    ml_testStep 3.1
    
    if {![ml_waitForStandbyUp $dut]} {
        ml_error "#dut cannot run SSO/SSO tests without standby RP not in\
                    ready state" -pause
        ats_results -result "fail"
        aetest::goto common_cleanup
    } else {
        ml_success "$dut Standby RP is ready for testing"
    }

    ###################################################################
    #Check for tracebacks before configuring the topology
    ml_testStep 3.2
    
    if {$Traceback_check} {
        if {![ml_verifyRTRlogs $dut]} {
            ml_error "$tN: PreRutConfig tracebacks found on $dut" -warning
        } else {
            ml_success "No tracebacks found on $dut before metal\
                        configuration"
        }
    } else {
        ml_debug "Traceback check is disabled"
    }
    
    ######################################################################
    #Configure topology
    ml_testStep 4
    
    if {$ml_global(configure)} {
        if {[catch {ml_configureTopology} err] || $err < "1"} {
            ml_error "Error with ml_configureTopology :: $err"
            ats_results -result "fail"
            aetest::goto common_cleanup
        } else {
            ml_success "Topology configured based on input file and ready\
                        for testing"
        }
    } else {
        ml_debug "Topology not being configured as either input file or\
                    suite-line arguement configure value is set to 0"
    }

    ######################################
    #Check for tracebacks after configuring the topology
    ml_testStep 4.1
    
    if {$Traceback_check} {
        ml_debug "Check for tracebacks after configuring the topology"
        if {![ml_verifyRTRlogs $dut]} {
            ml_error "$tN: PostRutConfig tracebacks found on $dut" -warning
        } else {
            ml_success "No tracebacks found on $dut after metal\
                        configuration"
        }
    } else {
        ml_debug "Traceback check is disabled"
    }

    ##################################################
    # Make sure all interfaces are up
    ml_testStep 5 
    foreach router $deviceList {
        if {![ml_intsUp $router]} {
            ml_error "Not all configured interfaces are up" -pause
            ats_results -result "fail"
            aetest::goto common_cleanup
        }
    }


}; #endof common_setup

########################################
#####    TESTCASE BLOCK
########################################
ml_checkFlags _flags {} -reportAll

aetest::testcase -tc_id case_bfd_ipv4_sso {
    ml_testName case_bfd_ipv4_sso
    ml_setDUT $rut
    ml_setTestDescr "This test configues BFD between Head Rtr as DUT and\
                     Tail Rtr while Head Rtr as DUT perform SSO.\
                     It maps to testcases 11.1.11 in EDCS-603730."
    ml_testStep 6 "Verify DUT formed BFD adjacency with Tail Router"
    ml_testStep 7 "Start Pagent traffic, and verify traffic flow"
    ml_testStep 8 "Check whether image in DUT is ION"
    ml_testStep 8.1 "If image in DUT is ION, start traffic and start\
                     Process Restart"
    ml_testStep 8.2 "Verifiy traffic after Process Restart"
    ml_testStep 8.3 "Make sure standby RP is up after Process Restart"
    ml_testStep 8.4 "Make sure BFD adjacency formed after Process Restart"
    ml_testStep 9 "Verify BFD adjacency - Shut and no shut the intferace"
    ml_testStep 10 "Verify BFD adjacency - Remove and restore ip address"
    ml_testStep 11 "Verify BFD adjacency - Toggle BFD echo/async mode"
    ml_testStep 12 "Verify DUT standby RP is ready for SSO testing"
    ml_testStep 13 "Configure testbed for graceful restart for SSO tests"
    ml_testStep 14 "Verify DUT is ready for SSO tests"
    ml_testStep 15 "Verify BFD adjacency is formed between Head Router and\
                   Tail Router before Head Router perform SSO - measure Uptime"
    ml_testStep 16 "Verify BFD clients are registered correctly in Active RP\
                    Verify Chkpt is registered correctly in Standby RP"
    ml_testStep 17 "Start Pagent traffic, to verify the traffic flow"
    ml_testStep 18 "Start Pagent traffic again and ready for SSO and SSO test"
    ml_testStep 19 "Measure BFD Uptime before BFD SSO"
    ml_testStep 20 "$dut as Head router perform SSO"
    ml_testStep 21 "Tail Rtr measure BFD Uptime after BFD SSO and verify BFD\
                    session does not flap during Head Rtr perform BFD SSO"
    ml_testStep 22 "Verify $dut standby RP is up after $dut perform SSO."
    ml_testStep 23 "Verify BFD clients and Chkpt are registered correctly in\
                    Active RP after SSO before Chkpt de-registered by itself\
                    Verify Chkpt registered correctly in Standby RP after SSO"
    ml_testStep 23.1 "Check for tracebacks after $dut completed SSO"
    ml_testStep 24 "Do the traffic verification after $dut completed SSO"

# CSCtj71030 - Adding tests for BFD Async mode

    ml_testStep 25 "Verify BFD adjacency - Set BFD async mode"
    ml_testStep 26 "Verify DUT standby RP is ready for SSO testing"
    ml_testStep 27 "Configure testbed for graceful restart for SSO tests"
    ml_testStep 28 "Verify DUT is ready for SSO tests"
    ml_testStep 29 "Verify BFD adjacency is formed between Head Router and\
                   Tail Router before Head Router perform SSO - measure Uptime"
    ml_testStep 30 "Verify BFD clients are registered correctly in Active RP\
                    Verify Chkpt is registered correctly in Standby RP"
    ml_testStep 31 "Start Pagent traffic, to verify the traffic flow"
    ml_testStep 32 "Start Pagent traffic again and ready for SSO and SSO test"
    ml_testStep 33 "Measure BFD Uptime before BFD SSO"
    ml_testStep 34 "$dut as Head router perform SSO"
    ml_testStep 35 "Tail Rtr measure BFD Uptime after BFD SSO and verify BFD\
                    session does not flap during Head Rtr perform BFD SSO"
    ml_testStep 36 "Verify $dut standby RP is up after $dut perform SSO."
    ml_testStep 37 "Verify BFD clients and Chkpt are registered correctly in\
                    Active RP after SSO before Chkpt de-registered by itself\
                    Verify Chkpt registered correctly in Standby RP after SSO"
    ml_testStep 37.1 "Check for tracebacks after $dut completed SSO"
    ml_testStep 38 "Do the traffic verification after $dut completed SSO"
    ml_testStep 39 "Unconfigure graceful restart"
    ml_testStep 40 "Clear pagent configs"
    ml_testStep 41 "Check for tracebacks after unconfiguring the feature"
   

aetest::section test {

    #####################################################
    # Verify DUT formed BFD adjacency with Tail Router
    ml_testStep 6 
    ################

    # One time delay
    ml_showSleep $sleepInterval -reason "to let BFD protocol client to\
                                bring up BFD"
    
    ml_debug "Make sure bfd neighbor adjacency is formed between Head Router\
                and Tail Router after loading input file."
   
    # From Tail router to check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between Head Rtr $dut and Tail Rtr\
                    $TailRtr after loading input file"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        Head $dut and Tail $TailRtr after loading\
                        input file" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # Check whether image on UUT is ION or IOS 
    ml_debug "Check what kind of image $dut is running"
    set dut_ion 0
    
    if {[ml_isIONImage $dut]} {
        ml_debug "***$dut is running ION image.****"
        set waitTime 700
        set dut_ion 1
        
    } else {
        ml_debug "***$dut is running IOS image.****"
        #default is 600
        set waitTime 600
        set dut_ion 0
    }
    

    #####################################################
    #Start Pagent traffic and verify traffic flow before testing
    ml_testStep 7
    ################    

    ml_debug "*********** TRAFFIC SECTION START***********"
    ml_debug "Set up pagent and start traffic"
    set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                    -rate $rate -pktsize $length \
                    -numStreams $numStrms]
    if {!$status} {
        ml_error "Error Setting Up Pagent For Test" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    #Verify traffic is running
    
    ml_showSleep 3 -reason "to collect pkts stats"
    set fastCountList [ml_pgnt_pkts_getFastcountStats $destPagentLoc]
    ml_debug "fastCountList= $fastCountList"
    set keys [keylkeys fastCountList]
    set streamPkts [ml_keylget fastCountList [lindex $keys 0].count]
    
    if {$streamPkts == "DNE!!"} {
        ml_error "Failed to get traffic counters on $destPagentLoc" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    
    ml_debug "streamPkts = $streamPkts"
    ml_debug "==>Stop traffic, check results and clean up"
    
    if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
            -maxDropTime $maxTrafficLoss]} {
        ml_error "Traffic verify failed" -pause
        ml_testResult "fail" 
        aetest::goto cleanup
    }

    
    #################################################
    # Check whether image in DUT is ION 
    ml_testStep 8 
    ################ 
    
    ml_debug "Check what kind of image $dut is running"
    set dut_ion 0
    
    if {[ml_isIONImage $dut]} {
        ml_debug "***$dut is running ION image.****"
        set waitTime 700
        set dut_ion 1
        
    } else {
        ml_debug "***$dut is running IOS image.****"
        #default is 600
        set waitTime 600
        set dut_ion 0
    }
    
    
    ###########################################################
    # If image is ION, start traffic and start Process Restart
    ml_testStep 8.1 
    ################ 
    
    if {$dut_ion == 1} {
    #Start Pagent traffic and ready for Process Restart test
        
        ml_debug "Set up pagent and start traffic again"
        set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                        -rate $rate -pktsize $length \
                        -numStreams $numStrms]
        if {!$status} {
            ml_error "Error Setting Up Pagent For Test" -pause
            ml_testResult "fail"
            aetest::goto cleanup
        }

        #Start Process Restart        
        ml_debug "Start Process Restart on $dut with ION image"
        
        ml_debug "############start PROCESS RESTART###############"

        set process "iprouting.iosproc"
        ml_debug "Process to be restarted is $process"
        
        if {![ml_ion_restartProcess $dut $process]} {
            ml_error "$process - Process Restart failed" -pause  
            ml_testResult "fail"
            aetest::goto cleanup 
        } else {
            ml_success "$process - Process Restart successful and passed"
        }


        ###############################################
        # Traffic Verification after Process Restart 
        ml_testStep 8.2
        ################

        ml_debug "==>Stop traffic, check results and clean up"
        if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
                -maxDropTime $maxTrafficLossPR]} {
            ml_error "Traffic verify failed after PR completed" -pause
            ml_testResult "fail" 
            aetest::goto cleanup
        }

        ##############################################
        # Make sure standby RP is up after Process Restart
        ml_testStep 8.3
        ################
        
        ml_debug "Check $dut standby RP is up after Process Restart"

        if {![ml_waitForStandbyUp $dut]} {
            ml_error "Cannot proceed further without standby RP\
                        in ready state after Process Restart" -pause
            ml_testResult "fail"
            aetest::goto cleanup
        } else {
            ml_success "$dut Standby RP is ready after $dut Process Restart"
        }

        
        ###########################################################
        # Make sure BFD adjacency is formed after Process Restart
        ml_testStep 8.4
        ################

        ml_debug "Make sure bfd neighbor adjacency is formed between\
                    Head router and Tail router after Process Restart."
   
        # From Tail router to check BFD IPv4 adjacency
        if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
            ml_success "BFD adjacency is formed between Head $dut and\
                        Tail $TailRtr after $dut perform Process Restart" 
        } else {
            ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                            Head $dut and Tail $TailRtr after $dut\
                            perform Process Restart" -pause
            ml_testResult "fail"
            aetest::goto cleanup
        }
        
    }

    
    #####################################################
    #Verify BFD adjacency - Shut and no shut the intferace
    ml_testStep 9
    ################ 
    
    set HeadRtrIntf [ml_getPeer ${TailRtr}::${TailRtr_Int_List}]
    ml_debug "HeadRtrIntf is $HeadRtrIntf"

    foreach HeadRtrIntf [$dut getAllInterfaces -notunnels -noloopback] {
        ml_debug "HeadRtrIntf is $HeadRtrIntf"

        #List the ipv4 address from input file

        set TailRtrIntf [ml_getPeer ${dut}::${HeadRtrIntf}]
        ml_debug "TailRtrIntf is $TailRtrIntf"
    }

    set Tail_addr_mask [lindex [ [ml_getPeer ${dut}::${HeadRtrIntf}]\
                                            getAddress -mask] 1]
    ml_debug "Tail_addr_mask is $Tail_addr_mask"

    
    # Shut and no shut from Tail router intf, to verify BFD adjacency re-formed
    
    # Shutdown from Tail router interface, to verify the BFD adjacency is down
    $TailRtrIntf shut
    
    if {![ml_intsUp $TailRtrIntf -down]} {
        ml_error "$tN - Not all configured interfaces are down after tail\
                    router shutting its interfaces" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "All configured interfaces are down after tail router\
                        shutting its interfaces"
    }
    
    ml_showSleep 45 -reason "let $TailRtr to shut $TailRtrIntf"
    # Check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 1] == 0 {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_success "BFD adjacency is not formed between Head $dut and \
                    Tail $TailRtr is expected because $TailRtrIntf is shut"
    } else {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "$tN - Failure!!! BFD adjacency is formed between Head\
                        $dut and Tail $TailRtr, expected not formed adj\
                        because $TailRtrIntf is shut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # It is necessary to delay 5 seconds before shutting down for pos intf
    ml_showSleep 5 -reason "Tail Router no shut"    
    $TailRtrIntf shut -no

    ml_showSleep 90 -reason "let CEF and routing protocols form adjacency"
    # Check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between Head $dut and Tail $TailRtr\
                     after $TailRtrIntf is no shut"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between Head\
                      $dut and Tail $TailRtr after $TailRtrIntf no shut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # Shut and no shut from Head rtr intf, to verify BFD adjacency is re-formed
    
    # Shutdown from Head router interface, to verify the BFD adjacency is down
    set HeadRtrIntfLink [ml_getPeer ${TailRtrIntf}]
    ml_debug "HeadRtrIntfLink is $HeadRtrIntfLink"

    $HeadRtrIntfLink shut

    if {![ml_intsUp $HeadRtrIntfLink -down]} {
        ml_error "$tN - Not all configured interfaces are down after Head\
                    router shutting its interfaces" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "All configured interfaces are down after Head router\
                        shutting its interfaces"
    }

    ml_showSleep 45 -reason "let $dut to shut $HeadRtrIntfLink"
    # Check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $TailRtr $DutAddr\
            active -sleepTime 5 -maxBfdTries 1] == $ERROR} {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_success "BFD adjacency is not formed between Head $dut and \
                    Tail $TailRtr is expected because $HeadRtrIntfLink shut"
    } else {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "$tN - Failure!!! BFD adjacency is formed between Head\
                        $dut and Tail $TailRtr, expected not formed adj\
                        because $HeadRtrIntfLink shut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    
    # It is necessary to delay 5 seconds before shutting down for pos intf
    ml_showSleep 5 -reason "Head Router no shut"
    $HeadRtrIntfLink shut -no

    ml_showSleep 90 -reason "let CEF and routing protocols form adjacency"
    # Check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail $TailRtr\
                     is expected because $HeadRtrIntfLink no shut"
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is formed between\
                        $dut and Tail $TailRtr, expected not formed adj\
                        because $HeadRtrIntfLink no shut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    #####################################################
    #Verify BFD adjacency - Remove and restore ip address
    ml_testStep 10 
    ################ 
    
    # Remove ipv4 address 
    $TailRtrIntf config "no ip address $TailAddr $Tail_addr_mask"
    
    ml_showSleep 45 -reason "let $TailRtr to remove $TailAddr"
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $ERROR} {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_success "BFD adjacency is down between $dut and Tail Rtr\
                     after removing ip address from Tail Rtr"                
    } else {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "$tN - Failure!!! BFD adjacency is not down between\
                        $dut and Tail router after removing ip address\
                        from Tail Rtr" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # Restore IPv4 addresss
    $TailRtrIntf config "ip address $TailAddr $Tail_addr_mask"
    
    ml_showSleep 45 -reason "let $TailRtr to restore $TailAddr"
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     after restoring ip address on Tail Rtr"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail router after restoring ip address\
                        on Tail Rtr " -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    #####################################################
    #Verify BFD adjacency - Toggle BFD echo/async mode
    ml_testStep 11 
    ################ 
    
    # Toggle bfd mode to either async or echo mode
    if {[ml_toggle_bfd_echo_mode $TailRtrIntf] == $SUCCESS} {
         ml_success "Tail Rtr, $TailRtrIntf bfd mode toggle successfully"
    } else {
        ml_error "$tN - Failure!!! Tail Rtr, $TailRtrIntf unable to\
                        toggle bfd mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     after bfd mode is toggled"
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail router after bfd mode is toggled"
                        -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    
    # Toggle bfd mode back to either async or echo mode
    if {[ml_toggle_bfd_echo_mode $TailRtrIntf] == $SUCCESS} {
         ml_success "Tail Rtr, $TailRtrIntf bfd mode toggle successfully"
    } else {
        ml_error "$tN - Failure!!! Tail Rtr, $TailRtrIntf unable to \
                        toggle bfd mode successfully" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     after bfd mode is toggled"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail router after bfd mode is toggled"
                        -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # configure async mode
    if {[ml_configure_bfd_mode $TailRtrIntf async] == $SUCCESS} {
         ml_success "Tail Rtr, $TailRtrIntf configured bfd async mode"
    } else {
        ml_error "$tN - Failure!!! Tail Rtr, $TailRtrIntf unable to configure\
                        bfd async mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    # configure echo mode
    if {[ml_configure_bfd_mode $TailRtrIntf echo] == $SUCCESS} {
         ml_success "Tail Rtr, $TailRtrIntf configured bfd echo mode"
    } else {
        ml_error "$tN - Failure!!! Tail Rtr, $TailRtrIntf unable to configure\
                        bfd echo mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
   

    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     after configuring echo mode"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail Rtr after configuring echo mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ####################################################
    # Verify DUT standby RP is ready for SSO/SSO
    ml_testStep 12 
    ################
    
    if {![ml_waitForStandbyUp $dut]} {
        ml_error "$dut cannot run SSO and SSO tests without standby RP\
            not in ready state" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "$dut Standby RP is up and ready for SSO"
    }
   
    #CSCsy85422 
    if {$v4client == "frr"} { 

    #######################################################
    # Configure testbed for Graceful Restart for SSO/SSO
    ml_testStep 13 
    ################
    
    set ml_global(teHaObjList)  ""
    set teHaObjs ""
    set HA_Name teHaObj-$dut
    uplevel #0 MPLS_TE_HA $HA_Name
    $HA_Name setTarget $dut
    keylset ml_global(teHaObjList) $dut $HA_Name
    lappend teHaObjs $HA_Name
    
    #print out data
    foreach obj $teHaObjs {
        ml_debug "TE_HA Class Object = $obj"
        ml_debug "Router for $obj is [$obj getTarget]"
    }

    ml_debug "Config graceful restart hellos on interfaces"
    if {[ml_te_configGrOnInts $dut $dut_Int_List] == $ERROR} {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "Failed to configure graceful restart hellos\
                    for $rut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    set gr_configured 1
    ml_debug "Graceful restart is configured"

    
    ####################################################
    # Verify DUT is ready for SSO tests
    ml_testStep 14 
    ################
    
    if {![ml_te_verifySSOready -rut $dut]} {
        ml_error "$dut is not ready for SSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "Router $dut is ready for TE SSO tests"
    }
    
    }

    #########################################################
    # Verify DUT formed BFD adjacency with Tail Router before
    # DUT perform SSO
    ml_testStep 15
    ################
    
    ml_debug "Make sure bfd neighbor adjacency is formed between Head Rtr\
                and Tail Rtr before Head Rtr perform SSO."
   
    # From Tail router to check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     before $dut perform SSO"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail rtr before $dut perform SSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ###################################
    # Verify BFD clients are registered correctly in Active RP and
    # verify Chkpt is registered correctly in Standby RP before SSO
    ml_testStep 16
    ################
    
    # Verify BFD ipv4 clients are registered correctly in
    # Headend Active RP before SSO 

    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $v4client\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol clients, $v4client are\
                        registered correctly in Headend Active RP before SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol clients are registered\
                            incorrectly in Headend Active RP before SSO\
                            expected $v4client" -pause
        set testResult "fail"
        aetest::goto cleanup
    }


    # It should be Chkpt registered in Standby RP
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        stdby] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Standby RP\
                         registered correctly as Chkpt before SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Standby RP\
                         registered incorrectly in Standby RP\
                         expected Chkpt before SSO" -pause
        set testResult "fail"
        aetest::goto cleanup
    }

   
    #####################################################
    #Start Pagent traffic and verify the traffic flow
    ml_testStep 17
    ################    

    ml_debug "*********** TRAFFIC SECTION START***********"
    ml_debug "Set up pagent and start traffic"
    set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                    -rate $rate -pktsize $length \
                    -numStreams $numStrms]
    if {!$status} {
        ml_error "Error Setting Up Pagent For Test" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    #Verify traffic is running
    
    ml_showSleep 3 -reason "to collect pkts stats"
    set fastCountList [ml_pgnt_pkts_getFastcountStats $destPagentLoc]
    ml_debug "fastCountList= $fastCountList"
    set keys [keylkeys fastCountList]
    set streamPkts [ml_keylget fastCountList [lindex $keys 0].count]
    
    if {$streamPkts == "DNE!!"} {
        ml_error "Failed to get traffic counters on $destPagentLoc" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    
    ml_debug "streamPkts = $streamPkts"
    ml_debug "==>Stop traffic, check results and clean up"
    
    if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
            -maxDropTime $maxTrafficLoss]} {
        ml_error "Traffic verify failed" -pause
        ml_testResult "fail" 
        aetest::goto cleanup
    }


    #############################################################
    #Start Pagent traffic again and ready for SSO testing
    ml_testStep 18
    ################
    
    ml_debug "Set up pagent and start traffic again"
    set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                    -rate $rate -pktsize $length \
                    -numStreams $numStrms]
    if {!$status} {
        ml_error "Error Setting Up Pagent For Test" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    

    ##############################################
    # Tail Rtr measure BFD Uptime before BFD SSO" 
    ml_testStep 19
    ################
    set bfd_uptime_beforeSSO 0
    set bfd_uptime_beforeSSO [ml_getIpv4BfdUptime $TailRtr $DutAddr active] 
    ml_debug "Tail rtr $TailRtr bfd_uptime_beforeSSO is $bfd_uptime_beforeSSO"


    ###################################
    # Head Router perform SSO" 
    ml_testStep 20 
    ################    
 
    ml_debug "Head router $dut perform SSO"

    if { [$dut switchover -nowait] == $ERROR } {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "$tN - Switchover could not be performed on $dut" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "Head router $dut perform SSO successfully."
    }


    ###########################################################
    # Tail Rtr measure BFD Uptime after BFD SSO and verify BFD
    # session does not flap after BFD SSO
    ml_testStep 21
    ################

    set bfd_uptime_afterSSO 0
    set bfd_uptime_afterSSO [ml_getIpv4BfdUptime $TailRtr $DutAddr active]
    ml_debug "Tail rtr $TailRtr bfd_uptime_afterSSO is $bfd_uptime_afterSSO"

    if {$bfd_uptime_afterSSO > $bfd_uptime_beforeSSO} {
        ml_success "BFD session does not flap during BFD SSO"
    } else {
        ml_error "$tN - Failure!!! BFD session flap during BFD SSO.\
                        BFD uptime before SSO is $bfd_uptime_beforeSSO\
                        BFD uptime after SSO is $bfd_uptime_afterSSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ###########################################################
    # Make sure the Head Router standby is up after Head Router
    # perform SSO
    ml_testStep 22 
    ###############

    ml_debug "Make sure the Head Router standby is up after $dut\
                perform SSO."
      
    if {![ml_waitForStandbyUp $dut -timeout $waitTime]} {
        ml_error "Cannot proceed further without standby RP\
                   in ready state" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "$dut Standby RP is ready after $dut perform SSO\
                    is completed"
    }


    ###################################
    # Verify BFD clients and Chkpt are registered correctly in Active RP,
    # verify Chkpt is registered correctly in Standby RP after SSO
    ml_testStep 23
    ################
    
    # Chkpt should also registered in Active RP after SSO, 
    # before de-registered by itself 
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Active RP\
                         registered correctly as Chkpt after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Active RP\
                         registered incorrectly in Standby RP expected Chkpt\
                         after SSO before Chkpt de-registered by itself" -pause
        set testResult "fail"
        aetest::goto cleanup
    }
    
    # Verify BFD ipv4 clients are registered correctly in
    # Headend Active RP after SSO 

    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $v4client\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol clients, $v4client are\
                        registered correctly in Headend Active RP after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol clients are registered\
                            incorrectly in Headend Active RP after SSO\
                            expected $v4client" -pause
        set testResult "fail"
        aetest::goto cleanup
    }

    # It should be Chkpt registered in Standby RP
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        stdby] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Standby RP\
                         registered correctly as Chkpt after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Standby RP\
                         registered incorrectly in Standby RP\
                         expected Chkpt after SSO" -pause
        set testResult "fail"
        aetest::goto cleanup
    }


    ###################################################
    ####Check for tracebacks after SSO
    ml_testStep 23.1 
    #################
    
    if {$Traceback_check} {
        if {![ml_verifyRTRlogs $dut]} {
        ml_error "tracebacks found on $dut after SSO" -warning
        } else {
        ml_success "No tracebacks found on $dut after SSO"
        }
    } else {
        ml_debug "Traceback check is disabled"
    }

 
    ######################################
    #Traffic Verification after SSO is completed
    ml_testStep 24

    ml_debug "==>Stop traffic, check results and clean up"
    if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
            -maxDropTime $maxTrafficLoss]} {
        ml_error "Traffic verify failed after SSO completed" -pause
        ml_testResult "fail" 
        aetest::goto cleanup
    }

####################################################
#CSCtj71030 - Adding tests for BFD Async mode
####################################################

    #####################################################
    #Verify BFD adjacency - Set BFD async mode
    ml_testStep 25 
    ################ 

    # configure async mode
    if {[ml_configure_bfd_mode $TailRtrIntf async] == $SUCCESS} {
         ml_success "Tail Rtr, $TailRtrIntf configured bfd async mode"
    } else {
        ml_error "$tN - Failure!!! Tail Rtr, $TailRtrIntf unable to configure\
                        bfd async mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     after configuring echo mode"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail Rtr after configuring echo mode" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ####################################################
    # Verify DUT standby RP is ready for SSO/SSO
    ml_testStep 26 
    ################
   
    #CSCsy85422 
    if {$v4client == "frr"} { 

    #######################################################
    # Configure testbed for Graceful Restart for SSO/SSO
    ml_testStep 27 
    ################
    
    set ml_global(teHaObjList)  ""
    set teHaObjs ""
    set HA_Name teHaObj-$dut
    uplevel #0 MPLS_TE_HA $HA_Name
    $HA_Name setTarget $dut
    keylset ml_global(teHaObjList) $dut $HA_Name
    lappend teHaObjs $HA_Name
    
    #print out data
    foreach obj $teHaObjs {
        ml_debug "TE_HA Class Object = $obj"
        ml_debug "Router for $obj is [$obj getTarget]"
    }

    ml_debug "Config graceful restart hellos on interfaces"
    if {[ml_te_configGrOnInts $dut $dut_Int_List] == $ERROR} {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "Failed to configure graceful restart hellos\
                    for $rut" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    set gr_configured 1
    ml_debug "Graceful restart is configured"

    
    ####################################################
    # Verify DUT standby RP is ready for SSO/SSO
    # Verify DUT is ready for SSO tests
    ml_testStep 28 
    ################

    if {![ml_waitForStandbyUp $dut]} {
        ml_error "$dut cannot run SSO and SSO tests without standby RP\
            not in ready state" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "$dut Standby RP is up and ready for SSO"
    }
    
    if {![ml_te_verifySSOready -rut $dut]} {
        ml_error "$dut is not ready for SSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "Router $dut is ready for TE SSO tests"
    }
    
    }

    #########################################################
    # Verify DUT formed BFD adjacency with Tail Router before
    # DUT perform SSO
    ml_testStep 29
    ################
    
    ml_debug "Make sure bfd neighbor adjacency is formed between Head Rtr\
                and Tail Rtr before Head Rtr perform SSO."
   
    # From Tail router to check BFD IPv4 adjacency
    if {[ml_verifyBfdNeighborIpv4Up $dut $TailAddr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "BFD adjacency is formed between $dut and Tail Rtr\
                     before $dut perform SSO"                
    } else {
        ml_error "$tN - Failure!!! BFD adjacency is not formed between\
                        $dut and Tail rtr before $dut perform SSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ###################################
    # Verify BFD clients are registered correctly in Active RP and
    # verify Chkpt is registered correctly in Standby RP before SSO
    ml_testStep 30
    ################
    
    # Verify BFD ipv4 clients are registered correctly in
    # Headend Active RP before SSO 

    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $v4client\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol clients, $v4client are\
                        registered correctly in Headend Active RP before SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol clients are registered\
                            incorrectly in Headend Active RP before SSO\
                            expected $v4client" -pause
        set testResult "fail"
        aetest::goto cleanup
    }


    # It should be Chkpt registered in Standby RP
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        stdby] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Standby RP\
                         registered correctly as Chkpt before SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Standby RP\
                         registered incorrectly in Standby RP\
                         expected Chkpt before SSO" -pause
        set testResult "fail"
        aetest::goto cleanup
    }

   
    #####################################################
    #Start Pagent traffic and verify the traffic flow
    ml_testStep 31
    ################    

    ml_debug "*********** TRAFFIC SECTION START***********"
    ml_debug "Set up pagent and start traffic"
    set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                    -rate $rate -pktsize $length \
                    -numStreams $numStrms]
    if {!$status} {
        ml_error "Error Setting Up Pagent For Test" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }

    #Verify traffic is running
    
    ml_showSleep 3 -reason "to collect pkts stats"
    set fastCountList [ml_pgnt_pkts_getFastcountStats $destPagentLoc]
    ml_debug "fastCountList= $fastCountList"
    set keys [keylkeys fastCountList]
    set streamPkts [ml_keylget fastCountList [lindex $keys 0].count]
    
    if {$streamPkts == "DNE!!"} {
        ml_error "Failed to get traffic counters on $destPagentLoc" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    
    ml_debug "streamPkts = $streamPkts"
    ml_debug "==>Stop traffic, check results and clean up"
    
    if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
            -maxDropTime $maxTrafficLoss]} {
        ml_error "Traffic verify failed" -pause
        ml_testResult "fail" 
        aetest::goto cleanup
    }


    #############################################################
    #Start Pagent traffic again and ready for SSO testing
    ml_testStep 32
    ################
    
    ml_debug "Set up pagent and start traffic again"
    set status [ml_pgnt_setupTraffic $srcPagentLoc $destPagentLoc \
                    -rate $rate -pktsize $length \
                    -numStreams $numStrms]
    if {!$status} {
        ml_error "Error Setting Up Pagent For Test" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }
    

    ##############################################
    # Tail Rtr measure BFD Uptime before BFD SSO" 
    ml_testStep 33
    ################
    set bfd_uptime_beforeSSO 0
    set bfd_uptime_beforeSSO [ml_getIpv4BfdUptime $TailRtr $DutAddr active] 
    ml_debug "Tail rtr $TailRtr bfd_uptime_beforeSSO is $bfd_uptime_beforeSSO"


    ###################################
    # Head Router perform SSO" 
    ml_testStep 34 
    ################    
 
    ml_debug "Head router $dut perform SSO"

    if { [$dut switchover -nowait] == $ERROR } {
    	ml_debug "VIRAG: ERROR: $ERROR, SUCCESS: $SUCCESS" 
        ml_error "$tN - Switchover could not be performed on $dut" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "Head router $dut perform SSO successfully."
    }


    ###########################################################
    # Tail Rtr measure BFD Uptime after BFD SSO and verify BFD
    # session does not flap after BFD SSO
    ml_testStep 35
    ################

    set bfd_uptime_afterSSO 0
    set bfd_uptime_afterSSO [ml_getIpv4BfdUptime $TailRtr $DutAddr active]
    ml_debug "Tail rtr $TailRtr bfd_uptime_afterSSO is $bfd_uptime_afterSSO"

    if {$bfd_uptime_afterSSO > $bfd_uptime_beforeSSO} {
        ml_success "BFD session does not flap during BFD SSO"
    } else {
        ml_error "$tN - Failure!!! BFD session flap during BFD SSO.\
                        BFD uptime before SSO is $bfd_uptime_beforeSSO\
                        BFD uptime after SSO is $bfd_uptime_afterSSO" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    }


    ###########################################################
    # Make sure the Head Router standby is up after Head Router
    # perform SSO
    ml_testStep 36 
    ###############

    ml_debug "Make sure the Head Router standby is up after $dut\
                perform SSO."
      
    if {![ml_waitForStandbyUp $dut -timeout $waitTime]} {
        ml_error "Cannot proceed further without standby RP\
                   in ready state" -pause
        ml_testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "$dut Standby RP is ready after $dut perform SSO\
                    is completed"
    }


    ###################################
    # Verify BFD clients and Chkpt are registered correctly in Active RP,
    # verify Chkpt is registered correctly in Standby RP after SSO
    ml_testStep 37
    ################
    
    # Chkpt should also registered in Active RP after SSO, 
    # before de-registered by itself 
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Active RP\
                         registered correctly as Chkpt after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Active RP\
                         registered incorrectly in Standby RP expected Chkpt\
                         after SSO before Chkpt de-registered by itself" -pause
        set testResult "fail"
        aetest::goto cleanup
    }
    
    # Verify BFD ipv4 clients are registered correctly in
    # Headend Active RP after SSO 

    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $v4client\
                        active] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol clients, $v4client are\
                        registered correctly in Headend Active RP after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol clients are registered\
                            incorrectly in Headend Active RP after SSO\
                            expected $v4client" -pause
        set testResult "fail"
        aetest::goto cleanup
    }

    # It should be Chkpt registered in Standby RP
    
    if {[ml_verifyBfdRegisteredIpv4Client $dut $TailAddr $bfd_chkpt\
                        stdby] == $SUCCESS} {
        ml_success "BFD IPv4 registered protocol client in Standby RP\
                         registered correctly as Chkpt after SSO"
    } else {
        ml_error "$tN - BFD IPv4 registered protocol client in Standby RP\
                         registered incorrectly in Standby RP\
                         expected Chkpt after SSO" -pause
        set testResult "fail"
        aetest::goto cleanup
    }


    ###################################################
    ####Check for tracebacks after SSO
    ml_testStep 37.1 
    #################
    
    if {$Traceback_check} {
        if {![ml_verifyRTRlogs $dut]} {
        ml_error "tracebacks found on $dut after SSO" -warning
        } else {
        ml_success "No tracebacks found on $dut after SSO"
        }
    } else {
        ml_debug "Traceback check is disabled"
    }

 
    ######################################
    #Traffic Verification after SSO is completed
    ml_testStep 38

    ml_debug "==>Stop traffic, check results and clean up"
    if {![ml_pgnt_verifyTraffic $srcPagentLoc $destPagentLoc \
            -maxDropTime $maxTrafficLoss]} {
        ml_error "Traffic verify failed after SSO completed" -pause
        ml_testResult "fail" 
        aetest::goto cleanup
    }

    
    ml_testResult "pass"
    };#end of test section

    
    aetest::section cleanup {

    #CSCsy85422
    if {$v4client == "frr"} {

    ###########################################
    # Unconfigure graceful restart
    ml_testStep 39
    ################
    
    if {$gr_configured} {
        ml_debug "Unconfigure graceful restart"
        if {![ml_te_configGrOnInts $dut $dut_Int_List -no]} {
            ml_error "Counld not unconfigure graceful restart on $dut\
                      router" -pause
            ats_results -result "fail"
        }
        ml_success "Graceful restart is unconfigured successfully"
    }   

    }

    ###########################################
    #Clear pagent configs
    ml_testStep 40
    ################

    if {![ml_pgnt_tgn_clear $srcPagentRtr]} {
        ml_error "$tN : Error resetting tgn $srcPagentRtr" -pause
        ats_results -result "fail"
    }
    
    if {![ml_pgnt_pkts_clear $destPagentRtr]} {
        ml_error "$tN : Error resetting pkts $destPagentRtr" -pause
        ats_results -result "fail"
    }

    #CSCsy85422
    if {$v4client == "frr"} {

    #Test bed / script cleanup
    if {$gr_configured} {
        ml_debug "Delete TE HA Objects (for each rut)"
        foreach obj $teHaObjs {
            itcl::delete object $obj
        }
    }
 
    }

    ###################################################################
    #Check for tracebacks after unconfiguring feature
    ml_testStep 41
    ###############
    
    if {$Traceback_check} {
        if {![ml_verifyRTRlogs $dut]} {
            ml_error "$tN: PostRutConfig tracebacks found on $dut\
                        after unconfiguring feature" -warning
        } else {
            ml_success "No tracebacks found on $dut after\
                        unconfiguring feature"
        } 
    } else {
        ml_debug "Traceback check is disabled"
    }
        
    };#end of cleanup section 

};#end of testcase section


##############################################################################
########################################
##### SECTION 6
#####    UNCONFIGURE TB
########################################

aetest::section common_cleanup {
    
    # unconfigure the whole topology based on input file
    
    ml_logConfigErrors -disable
    if {$ml_global(unconfigure)} {
        ml_unconfigureTopology
    } else {
        ml_debug "Topology will not be unconfigured due to input file or\
                    suite-line arguement for unconfigure set to 0"
    }
    
    # disconnect from all devices
    foreach item $ml_global(deviceList) {
        if {[catch {$item disconnectDevice} errMsg]} {
            ml_error "Could not disconnect from $item: $errMsg"
        }
    }
    

    ###############
    # Show all results if not in ATS mode
    
    if {$ml_global(ats_mode) == ""} {
        ml_showTestStatus parents
    } else {
        ml_debug "In ATS mode, results will not be shown here"
    }
    
    
    ml_cleanupMETAL
}
