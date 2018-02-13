#!/bin/sh
# \
	exec $AUTOTEST/bin/tclsh $0 ${1+"$@"}

# The above three lines are the standard way of invoking the TCL interpretor

##Script Header
#
# Name:
#     case_bfd_ipv6v4_intf.tcl
#
# Purpose:
#     To automate the testcases found in EDCS-597544
#     Uses AE Test and METAL as a package.
#
# Author:
#     patring 
#
# Support Alias:
#     bfd-devtest@cisco.com
#
# Description:
#     This automates the testcases in EDCS-597544 sections 11.1.1, 11.1.2, 
#     11.1.3, 11.1.6, 11.1.7, 11.1.8, 11.1.9, 11.1.14 and 11.1.17
#     The intent of this case is to test the behavior of the 
#     BFDv6 (BFD stub client for IPv6) support on ATM, POS and VLAN interfaces 
#     
#     Test cases within this case file:
#      EDCS-597544
# case num Case Name 
# 11.1.1   Verify that BFD neighbor command works correctly with IPv6 address 
# 11.1.2   Verify "show bfd neighbor" displays IPv6 clients
# 11.1.3   Verify "show bfd neighbor" displays IPv6 and IPv4 clients
# 11.1.6   Verify BFD functionality with multiple IPv6 instances (link local 
#          and multiple global IPv6 addresses) on a single interface
# 11.1.7   Verify BFD functionality with multiple IPv6 / IPV4 (combination) 
#          instances on a single interface. When one link fails other sessions
#          must not flap          
# 11.1.8   Verify BFD adjacency with Link Local IPv6 address
# 11.1.9   Verify BFD adjacency wiht global IPv6 address
# 11.1.14  Verify BFD functionality on multiple interfaces, types and multiple 
#          BFD sessions per interface
# 11.1.17  Verify BFDv6 support on WAN interfac    
#
# Topology:
#      Refer input files for topology info. A two router topology
#      is required as a minimum.
#      All Testbed configuration is contained within inputfile.
#
#                   R1-------------R2
#                   (Head)         (Tail) 
#                   (DUT)    
#
#       The following is expected of the METAL based input file:
#       All interfaces are up and should be able to ping from HEAD to TAIL
#
# Synopsis:
#     case_bfd_ipv6v4_intf.tcl -tid <name> -metal_input_file <file> 
#                              -rut <Router>     
#
# Arguements:
#   Required
#     -tid <name> Test name idenitfier 
#     -metal_input_file <file>   The input file to be parsed
#     -rut <Router>  Router under test
#
#   Optional (testcase specific)
#     -altDirectory <path> Directory where testcase specific library file is 
#     -description <description> brief test description to be displayed in
#                                result and error logging.      
#     -maxTries <number> Times to poll CLI commands
#                        before declaring failure (default: 8)
#     -pollInt <number> Interval in seconds to wait between polls 
#                        (default: 15)
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
#                                       dependancies needed
#     -aetest_skip_ids <casenames> Will not run just these case names and any
#                                       dependancies needed
#
# Sample Usage:
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_pos_hdlc \
#           -metal_input_file bfd-ipv6v4-pos-hdlc.input -rut R1 
#           
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_pos_ppp \
#           -metal_input_file bfd-ipv6v4-pos-ppp.input -rut R1 
#
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_pos_fr \
#           -metal_input_file bfd-ipv6v4-pos-fr.input -rut R1
#
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_ge \
#           -metal_input_file bfd-ipv6v4-ge.input -rut R1 
#
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_ge_dot1q \
#           -metal_input_file bfd-ipv6v4-ge-dot1q.input -rut R1 
#
#       case_bfd_ipv6v4_intf.tcl -tid bfd_ipv6v4_static \
#           -metal_input_file bfd-ipv6v4-static.input -rut R1 
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
#     <Project>; <Component>; <attributes>; <Bug Number 1>
#
# End of Header

###############################################################################
# CHANGE LOG
#
# DATE       BUG#       username    Comment
# ---------- ---------- ----------- -------------------------------------------
# 07-29-2007 CSCsj58997  patring    Initial release
# 05-28-2009 CSCsz70854  patring    add delay for CEF non-discovery protocol
#                                   client, eg static, stub 
# 06-24-2009 CSCta33276  patring    Add delay in Step 4 to restore ipv6 addr
#
# END CHANGE LOG
###############################################################################


########################################
##### TEST SCRIPT INITIALIZATION    ####
########################################

###############

# Just a cleanup of argv (sometimes argv is different... not sure why)
if {![info exists argv0] || $argv0 == [lindex $argv 0]} {
    set argv0 [lvarpop argv]
}

# AtsAuto package includes base packages
package require AtsAuto

set mandatory_args {
    -metal_input_file   ANY
    -rut                ANY
}

set optional_args {
    -altDirectory       ANY
    -description        ANY
    -maxTries           DECIMAL
                        DEFAULT 8
    -pollInt            DECIMAL
                        DEFAULT 15
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

########################################
### TESTCASE DEPENDANCIES [CUSTOMIZE]
########################################

set tc_dependancies {
}


#Call the aetest::script_init function... don't change this!

if {[catch {aetest::script_init -return_array _flags \
    -mandatory_args $mandatory_args \
    -optional_args $optional_args \
    -tc_dependencies $tc_dependancies} aetestError]} {
    ats_log -error "Error initializing aetest: $aetestError"
    return 1
}

#############################
#Variable initializations to default values
set tN       "case_bfd_ipv6v4_intf"

set HeadRtr      ""
set TailRtr      ""
set endRouters   ""

##############################################
##### COMMON SETUP SECTION
##############################################
aetest::section common_setup {

    set testResult "pass"
    
    ###############
    # The following will do generic csetest setup
    if {[csetest_common_setup] < "1"} {
    set testResult "fail"
    aetest::goto common_cleanup
    }


   #Set the values

    set rut     $_flags(rut)
    
    if {$rut == ""} {
        ml_error "$tN: Missing/incorrect parameters ... Required args\
                                are -rut <rut>"
        set testResult "fail" 
        set ml_global(unconfigure) 0
        aetest::goto common_cleanup
    }

    
    set myPath [ml_getVar _flags(altDirectory)\
 "$expect_library/../../regression/tests/functionality/mplstest/TE/feature/bfd"]


    ########################################
    #### Source all needed files
    ########################################
    set neededFiles "
        $myPath/bfd_proc.itcl
        metal_bfd_support.itcl
    "

    if {[info exists ml_global(case_library)]} {
        lappend neededFiles $ml_global(case_library)
    }
    foreach file $neededFiles {
        if {[ml_sourceFile $file] != 1} {
            ml_error "$tN: Could not source file $file"
            set testResult "fail"
            set ml_global(unconfigure) 0
            aetest::goto common_cleanup
        }
    }

    set ERROR 0
    set SUCCESS 1
    set FALSE 0
    set TRUE 1
    global ml_global

    ########################################
    ##### SECTION 1
    #####    VALIDATE PASSED IN FLAGS [CUSTOMIZE]
    ########################################
    
    #Determine if we have the minimum num of routers mandated ie 2 
    set numRtrs 2 
    set deviceList [ml_getRouters]
    set allDevices $ml_global(deviceList)
    if {[llength $deviceList] < $numRtrs} {
        ml_error "$tN: The input file does not define the mandatory\
                    min number of routers - $numRtrs required. Found that the\
                    following devices: $deviceList listed"
        set testResult "fail"
        set ml_global(unconfigure) 0
        aetest::goto common_cleanup
    }

    foreach router $deviceList {
        set peerRtrs ""
        set peerRtrs [ml_getPeerRtrs $rut]
    
        if {[llength $peerRtrs] == 1} {
            lappend endRouters $router
        }
    }
    
    ml_debug "List of endRouters are $endRouters" 
    
    if {[llength $endRouters] != 2} {
        ml_error "$tN - From Head to Tail, only 2 routers are needed\
                        Head and Tail router must peer with only one\
                        router each" 
        set testResult "fail"
        aetest::goto common_cleanup
    }
    
    if {[lsearch $endRouters $rut] == -1} {
        ml_error "$tN - Double check to make sure the rut: $rut specific\
                        in input file is indeed as Head Router" 
        set testResult "fail"
        aetest::goto common_cleanup
    } 
   
    set HeadRtr $rut 
    set TailRtr [lindex [intersect3 $endRouters $HeadRtr] 0]
    ml_debug "Head router is: $HeadRtr"
    ml_debug "Tail router is: $TailRtr"

    foreach HeadRtrIntf [$HeadRtr getAllInterfaces -notunnels -noloopback] {
        ml_debug "HeadRtrIntf is $HeadRtrIntf"

        #List the ipv4 address from input file

        set TailRtrIntf [ml_getPeer ${HeadRtr}::${HeadRtrIntf}]
        ml_debug "TailRtrIntf is $TailRtrIntf"
    }

    
    set tail_v4_addr [[ml_getPeer ${HeadRtr}::${HeadRtrIntf}] getAddress]
    ml_debug "tail_v4_addr is $tail_v4_addr"

    set tail_v4_addr_mask [lindex [ [ml_getPeer ${HeadRtr}::${HeadRtrIntf}]\
                                            getAddress -mask] 1]
    ml_debug "tail_v4_addr_mask is $tail_v4_addr_mask"


    # Workaround CSCsj86757
    # List the ipv6 address from input file 

    set max_v6_addr $ml_global(max_v6_addr)

    for {set i 1} {$i <= $max_v6_addr} {incr i} {
        set head_v6_addr$i $ml_global(head_v6_addr$i)
        set tail_v6_addr$i $ml_global(tail_v6_addr$i)
        set tail_v6_addr_mask$i $ml_global(tail_v6_addr_mask$i)
        ml_debug "head_v6_addr$i [set head_v6_addr$i]"
        ml_debug "tail_v6_addr$i [set tail_v6_addr$i]"
        ml_debug "tail_v6_addr_mask$i [set tail_v6_addr_mask$i]"
    } 

    set maxTries [ml_getVar _flags(maxTries) 8]
    set pollInt [ml_getVar _flags(pollInt) 15]


    #####################
    #    CONFIGURE TB
    
    if {$ml_global(configure)} {
        if {[catch {ml_configureTopology} err] || $err < "1"} {
            ml_error "$tN: Error with ml_configureTopology :: $err"
            set testResult "fail"
            aetest::goto common_cleanup
        } else {
            ml_success "Topology configured based on input file and ready\
                        for testing"
        }
    } else {
        ml_debug "$tN:Topology not being configured as either input\
                    file or suite-line arguement configure value is set to 0"
    }
    
}


########################################
#####    TESTCASE BLOCK
########################################
ml_checkFlags _flags {} -reportAll

aetest::testcase -tc_id case_bfd_ipv6v4_intf {
    
    ml_testName case_bfd_ipv6v4_intf
    ml_setDUT $rut
    ml_setTestDescr "This test validates BFD for IPv6 support\
                    It maps to testcases 11.1.1, 11.1.2, 11.1.3, 11.1.6,\
                    11.1.7, 11.1.8, 11.1.9, 11.1.14 and 11.1.17 in\
                    EDCS-597544."

    ml_testStep 1 "Check BFD neighbor adjacecny, and verify all\
                        IPv6 and IPv4 interfaces formed BFD adjacency"
    ml_testStep 2 "Shutdown all interfaces, and verify all BFD neighbors\
                        go down"
    ml_testStep 3 "No shutdown all interfaces, and verify all BFD neighbors
                        back up"
    ml_testStep 4 "Remove a remote ipv6 interface one at a time and verify\
                        all BFD neighbors are still up except that interface\
                        being removed" 
    ml_testStep 5 "Add and restore that remote ipv6 interface back, and then\
                        verify all BFD neighbor adjacecy remain up states"
    
    aetest::section setup {
        foreach router $deviceList {
            if {![ml_intsUp $router -sleep $pollInt -max $maxTries] } {
                ml_error "$tN - Not all configured interfaces are up in\
                            $router" -pause
                set testResult "fail"
                aetest::goto cleanup
            } else {
                ml_success "All configured interfaces are up in $router"
            }
        }
    }


    aetest::section test {

    ###################################
    ml_testStep 1
    ################

    ml_showSleep 10 -reason "Let routing protocol and bfd settle down"
    # Check BFD adjacency for IPv6
    for {set i 1} {$i <= $max_v6_addr} {incr i} {
        if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$i]\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
            ml_success "IPv6 interface - [set tail_v6_addr$i] formed BFD\
                            adjacency"
        } else {
            ml_error "$tN - IPv6 interfaces - [set tail_v6_addr$i] does not\
                        formed BFD adjacency" -pause
            set testResult "fail"
            aetest::goto cleanup
        }
    }

    # Check BFD adjacency for IPv4
    if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
            active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "IPv4 interface - $tail_v4_addr formed BFD adjacency"
    } else {
        ml_error "$tN - IPv4 interface - $tail_v4_addr does not formed\
                        BFD adjacency" -pause
        set testResult "fail"
        aetest::goto cleanup
    }


    ###################################
    ml_testStep 2
    ################ 

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

    
    
    # Check BFD adjacency for IPv6
    for {set i 1} {$i <= $max_v6_addr} {incr i} {
        if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$i]\
                active -sleepTime 5 -maxBfdTries 3] == $ERROR} {
            ml_success "IPv6 interface - [set tail_v6_addr$i] does not\
                        form BFD adjacency because the remote shutting\
                        down the interface"
        } else {
            ml_error "$tN - IPv6 interfaces - [set tail_v6_addr$i] form\
                            BFD adjacency even the remote shutting down\
                            the interface" -pause
            set testResult "fail"
            aetest::goto cleanup
        }
    }

    # Check BFD adjacency for IPv4
    if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
            active -sleepTime 5 -maxBfdTries 3] == $ERROR} {
        ml_success "IPv4 interface - $tail_v4_addr does not form BFD\
                    adjacency because the remote shutting down the interface"
    } else {
        ml_error "$tN - IPv4 interface - $tail_v4_addr does not form BFD\
                        adjacency even the remote shutting down the interface"\
                        -pause
        set testResult "fail"
        aetest::goto cleanup
    }

    
    ###################################
    ml_testStep 3
    ################
    # No shutdown from Tail router intf, to verify BFD adjacency went back up

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

    # It is necessary to delay 5 seconds before shutting down for pos intf
    ml_showSleep 5 -reason "Tail Router no shut"    
    $TailRtrIntf shut -no
    
    # It is necessary to delay 5 seconds before shutting down for pos intf
    ml_showSleep 5 -reason "Head Router no shut"
    $HeadRtrIntfLink shut -no

    # CSCsz70854
    ml_showSleep 600 -reason "for CEF non-discovery protocol client, static & stub"

    if {![ml_intsUp $TailRtrIntf -sleep $pollInt -max $maxTries]} {
        ml_error "$tN - Not all configured interfaces are up after Tail router\
                    no shutting its interfaces" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "All configured interfaces are up after Tail router\
                        no shutting its interfaces"
    }
    
    if {![ml_intsUp $HeadRtrIntfLink -sleep $pollInt -max $maxTries]} {
        ml_error "$tN - Not all configured interfaces are up after Head router\
                    shutting its interfaces" -pause
        set testResult "fail"
        aetest::goto cleanup
    } else {
        ml_success "All configured interfaces are up after Head router\
                        no shutting its interfaces"
    }
    
  
    # Check BFD adjacency for IPv6
    for {set i 1} {$i <= $max_v6_addr} {incr i} {
        if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$i]\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
            ml_success "IPv6 interface - [set tail_v6_addr$i] formed\
                            BFD adjacency"
        } else {
            ml_error "$tN - IPv6 interfaces - [set tail_v6_addr$i] does not\
                            formed BFD adjacency" -pause
            set testResult "fail"
            aetest::goto cleanup
        }
    }

    ml_showSleep 5 -reason "IPv4 link to settle down for MCP testbed"
    # Check BFD adjacency for IPv4
    if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
        ml_success "IPv4 interface - $tail_v4_addr formed BFD adjacency"
    } else {
        ml_error "$tN - IPv4 interface - $tail_v4_addr does not formed\
                        BFD adjacency" -pause
        set testResult "fail"
        aetest::goto cleanup
    }
    

    ###################################
    ml_testStep 4
    ################
    # Remove a remote ipv6 interface one at a time and verify all BFD\
    # ipv6 and ipv4 neighbors are still up except that ipv6 address being\
    # removed.  Restore that same ipv6 address back, and verify that all\
    # BFD ipv6 and ipv4 neighbor adjacecy go back to up states"

    # Check BFD adjacency for IPv6
    for {set i 1} {$i <= $max_v6_addr} {incr i} {
      set tail_v6_addr_and_mask$i [set tail_v6_addr$i][set tail_v6_addr_mask$i]

        # Remote removing ipv6 address one a time, first ipv6 address 
        # is link-local 

        if { $i != 1 } {
            $TailRtrIntf config "no ipv6 address [set tail_v6_addr_and_mask$i]"
        } else {
            $TailRtrIntf config "no ipv6 address [set tail_v6_addr$i]\
                                    link-local"             
        }
        
        
        # BFD adjacency go down only on the address being removed, others\
        # bfd sessions should still stay up
        
        for {set j 1} {$j <= $max_v6_addr} {incr j} {
            # Check BFD adjacency for IPv6
            if { $i != $j} {
                if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$j]\
                        active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
                    ml_success "IPv6 interface - [set tail_v6_addr$j] BFD\
                                adjacency still staying up, unaffected by\
                                remote removing other ipv6 address on the\
                                same intf"
                } else {
                    ml_error "$tN - IPv6 interface - [set tail_v6_addr$j] BFD\
                                    adjacency should stay up even the remote\
                                    removing other ipv6 address on the same\
                                    interface" -pause
                    set testResult "fail"
                    aetest::goto cleanup
                }
            } else {
                if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$j]\
                        active -sleepTime 5 -maxBfdTries 3] == $ERROR} {
                    ml_success "IPv6 interface - [set tail_v6_addr$j] BFD\
                                adjacency go down, because remote removing\
                                this ipv6 address on the same intf"
                } else {
                    ml_error "$tN - IPv6 interface - [set tail_v6_addr$j] BFD\
                                    adjacency should go down because remote\
                                    removing this ipv6 address on the same\
                                    interface" -pause
                    set testResult "fail"
                    aetest::goto cleanup
                }
            }                

            # Check BFD adjacency for IPv4
            if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
                        active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
                ml_success "IPv4 interface - $tail_v4_addr BFD adjacency stay\
                            up and unaffected by remote removing ipv6 address\
                            on the same intf"
            } else {
                ml_error "$tN - IPv4 interface - $tail_v4_addr BFD adjacency\
                                should still stay up even remote removing ipv6\
                                address on the same intf" -pause
                set testResult "fail"
                aetest::goto cleanup
            }
        }
        
        # Restoring ipv6 address one a time, first ipv6 address is link-local
        if { $i != 1 } {
            $TailRtrIntf config "ipv6 address [set tail_v6_addr_and_mask$i]" 
        } else {
            $TailRtrIntf config "ipv6 address [set tail_v6_addr$i] link-local"
        }

        # BFD adjacency should restore and all BFD sessions should go up state.
        for {set j 1} {$j <= $max_v6_addr} {incr j} {
            
            ml_showSleep 120 -reason "for ipv6 address to be restored" 
            # Check BFD adjacency for IPv6
            if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$j]\
                    active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
                ml_success "IPv6 interface - [set tail_v6_addr$j] BFD\
                            adjacency stay up, after remote restoring back\
                            this ipv6 address on the same intf"
            } else {
                ml_error "$tN - IPv6 interface - [set tail_v6_addr$j] BFD\
                            adjacency should stay up after remote restoring\
                            back this ipv6 address on the same intf" -pause
                set testResult "fail"
                aetest::goto cleanup
            }
        }
        
        # Check BFD adjacency for IPv4
        if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
            ml_success "IPv4 interface - $tail_v4_addr BFD adjacency stay up\
                        and unaffected by remote removing this ipv6 address\
                        on the same intf"
        } else {
            ml_error "$tN - IPv4 interface - $tail_v4_addr BFD adjacency\
                        should still stay up even remote removing this ipv6\
                        address on the same intf" -pause
            set testResult "fail"
            aetest::goto cleanup
        }
    }; #end of ipv6 loop

    
    ###################################
    ml_testStep 5
    ################
    # Remove a remote ipv4 interface and verify all BFD ipv6 and ipv4
    # neighbors are still up except that ipv4 address being removed
    # Restore that same ipv4 address back, and verify that all BFD ipv6
    # ipv4 neighbor adjacecy go back to up states"

    # Remote shutting down ipv4 address 
    $TailRtrIntf config "no ip address $tail_v4_addr $tail_v4_addr_mask"    

    # BFD adjacency for ipv6 should stay up state, even remote removing
    # ipv4 address on the same intf
    
        for {set i 1} {$i <= $max_v6_addr} {incr i} {
            
            # Check BFD adjacency for IPv6
            if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$i]\
                    active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
                ml_success "IPv6 interface - [set tail_v6_addr$i] BFD\
                            adjacency stay up, after remote removing this\
                            ipv4 address on the same intf"
            } else {
                ml_error "$tN - IPv6 interface - [set tail_v6_addr$i] BFD\
                            adjacency should stay up after remote removing\
                            this ipv4 address on the same intf" -pause
                set testResult "fail"
                aetest::goto cleanup
            }
        }

        # Check BFD adjacency for IPv4
        if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
                active -sleepTime 5 -maxBfdTries 3] == $ERROR} {
            ml_success "IPv4 interface - $tail_v4_addr BFD adjacency go down\
                        because remote removing this ipv4 address on the same\
                        interface"
        } else {
            ml_error "$tN - IPv4 interface - $tail_v4_addr BFD adjacency\
                        should go down because remote removing this ipv4\
                        address on the same intf" -pause
            set testResult "fail"
            aetest::goto cleanup
        }

    # Remote restore back the same ipv4 address 
        
    $TailRtrIntf config "ip address $tail_v4_addr $tail_v4_addr_mask"    

    # BFD adjacency for ipv6 should stay up state, even remote restoring
    # ipv4 address on the same intf
     
        for {set i 1} {$i <= $max_v6_addr} {incr i} {
            
            # Check BFD adjacency for IPv6
            if {[ml_verifyBfdNeighborIpv6Up $HeadRtr [set tail_v6_addr$i]\
                    active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
                ml_success "IPv6 interface - [set tail_v6_addr$i] BFD\
                            adjacency stay up, after remote restoring this\
                            ipv4 address on the same intf"
            } else {
                ml_error "$tN - IPv6 interface - [set tail_v6_addr$i] BFD\
                            adjacency should stay up after remote restoring\
                            this ipv4 address on the same intf" -pause
                set testResult "fail"
                aetest::goto cleanup
            }
        }


        # Check BFD adjacency for IPv4
        if {[ml_verifyBfdNeighborIpv4Up $HeadRtr $tail_v4_addr\
                active -sleepTime 5 -maxBfdTries 3] == $SUCCESS} {
            ml_success "IPv4 interface - $tail_v4_addr BFD adjacency go up\
                        because remote restoring this ipv4 address on the\
                        same intf"
        } else {
            ml_error "$tN - IPv4 interface - $tail_v4_addr BFD adjacency\
                        should go up because remote restoring this ipv4\
                        address on the same intf" -pause
            set testResult "fail"
            aetest::goto cleanup
        }


    }; #end of section test


    aetest::section cleanup {
        ml_testResult $testResult
    }

}; #end of testcase


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
        ml_debug "Topology will not be unconfigured due to input\
                  file or suite-line arguement for unconfigure set to 0"
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

