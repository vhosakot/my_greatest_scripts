#--------------------------------------------------------------------------
# Title:  get_cisco_ixn2x_info.tcl
#--------------------------------------------------------------------------
# Author:        Chris Gillis, Agilent Technologies
# Modified:      11 Apr 2010 - Howard Rowland, Ixia - added support for Fusion XM chassis
#
# Controller list updated April 19, 2011
#--------------------------------------------------------------------------
# Synopsis:
#  Script to quickly survey an IxN2X system and capture the vital information
#--------------------------------------------------------------------------
#--------------------------------------------------------------------------
# Initialize variables
#--------------------------------------------------------------------------
#!/bin/sh
# \
exec $AUTOTEST/bin/tclsh "$0" ${1+"$@"}


set this_script get_n2x_info

#--------------------------------------------------------------------------
# Main body
#--------------------------------------------------------------------------
package require AgtClient
# package require registry 1.0

# Log File Names
set n2xFile "/users/ccrannel/n2xScanOutput.txt"

set controllerList [list \
10.86.29.161 \
10.86.29.164 \
10.86.29.141 \
10.86.29.169 \
10.86.29.245]


# Open Log File
if {[catch {open $n2xFile w} agtFd_]} {
    puts "Problem opening $AgtTraceFileName: $agtFd_"
    set agtFd_ 0
}


#--------------------------------------------------------------------------
# Controller information
#--------------------------------------------------------------------------
foreach controller $controllerList {
   AgtSetServerHostname $controller
   
   puts -nonewline $agtFd_ "IxN2X $controller  "

    if { [catch {AgtGetVersion} errMsg] } {
        puts $agtFd_ "Cannot connect to controller\n $errMsg\n\n\n\n"
        continue
    }
   set systemId [SmInvoke AgtLicenseManager2 GetSystemId]
   puts $agtFd_  "System ID: $systemId"
   
   
   #--------------------------------------------------------------------------
   # License information
   #--------------------------------------------------------------------------
   if { [catch {SmInvoke AgtLicenseManager2 ListLicenseAppNames} appList] } {
      puts $agtFd_ "Failed to get License names..."
   }
   
   puts $agtFd_ "\nLicenses --------------------------------------------------------------------"
   foreach appName $appList {
      if { [catch {SmInvoke AgtLicenseManager2 GetApplicationLicenseInfo $appName} licInfo] } {
         puts $agtFd_ "$licInfo"
      }
      set licensed   [lindex $licInfo 2]
      set expiryDate [lindex $licInfo 3]
      puts $agtFd_ "License: [format "%-30s" $appName]   Type: [format "%-10s" $licensed]  Expiry: [format "%-10s" $expiryDate]"
   }
   
   #--------------------------------------------------------------------------
   # Chassis information
   #--------------------------------------------------------------------------
   proc ConvertBinStringToDec {numberBin} {
       # Check for valid bianry input string
       regexp -nocase {([^01]*)} $numberBin match nonBinDigit
       if {[string length $nonBinDigit] > 0} {
           puts "ERROR: non-binary value passed to ConvertBinStringToDec"
           return 0
       }
       set numberBin [string trimleft $numberBin 0]
       set numberOfBits [string length $numberBin]
       set currentBit 0
       set numberDec 0
       while {$currentBit < $numberOfBits} {
           if {[string index $numberBin [expr $numberOfBits - $currentBit - 1]] == 1} {
               set numberDec [expr $numberDec + int(pow(2,$currentBit))]
           }
           incr currentBit
       }
       return $numberDec
   }
   
   proc ConvertDecStringToBin {numberDec} {
       # Check for valid bianry input string
       regexp -nocase {([^0-9]*)} $numberDec match nonDecDigit
       if {[string length $nonDecDigit] > 0} {
           puts "ERROR: non-decimal value passed to ConvertDecStringToBin $numberDec"
           return 0
       }
       set numberDec [string trimleft $numberDec 0]
       set divisor $numberDec
       set remainder 0
       set binNum ""
       while {$divisor > 0} {
           set remainder [expr $divisor%2]
           set divisor [expr round($divisor/2)]
           if {$remainder} {
               set binNum "1$binNum"
           } else {
               set binNum "0$binNum"
           }
       }
       
       return $binNum
   }
   
   proc ConvertHexStringToBin {numberHex} {
       # Check for valid hexadecimal input value
       regexp -nocase {(^0x)?([0-9a-fA-F]*([^0-9a-fA-F]*).*)$} $numberHex match \
           prefix hexDigit nonHexDigit
       if {([string length $nonHexDigit] > 0) || ([string length $hexDigit] == 0)} {
           puts "ERROR: non-hex value passed to ConvertHexStrToBin $numberHex"
           return 0
       }
       set numberHex [string trimleft $numberHex 0x]
       set numberOfNibbles [string length $numberHex]
       set currentNibble 0
       set numberBin ""
       # split number into 32 bit chunks
       if {$numberOfNibbles > 1} {
           set lowNibble [string index $numberHex  end]
           append numberBin [ConvertHexStringToBin [string range $numberHex 0 end-1]]
       } else {
           set lowNibble $numberHex
       }
       set currentNibbleBin [format %u 0x$lowNibble]
       set currentNibbleBin [ConvertDecStringToBin $currentNibbleBin]
       # trim to 4 bits
       set currentNibbleBin [string range $currentNibbleBin end-3 end]
       while {[string length $currentNibbleBin] < 4} {
           set currentNibbleBin "0$currentNibbleBin"
       }
       append numberBin $currentNibbleBin
       
       return $numberBin
   }
   
   proc DecodeSerialNumber { serialNumberEncodedHex } {
      array set amcCountryCode       \
          [list                      \
             AU              00001  \
             CA              00011  \
             CN              00101  \
             DE              01000  \
             HK              01010  \
             IN              01011  \
             JP              10000  \
             KR              10001  \
             MY              10011  \
             SG              11000  \
             TW              11010  \
             UK              11110  \
             US              11111  \
           ]

      # Check for valid hexadecimal input, note that Ixia Fusion XM chassis return ASCII string for serial number

      regexp -nocase {(^0x)?([0-9a-fA-F]*([^0-9a-fA-F]*).*)$} $serialNumberEncodedHex match prefix hexDigit nonHexDigit

      if {([string length $nonHexDigit] > 0) || ([string length $hexDigit] < 10)} {
         if {[string range $serialNumberEncodedHex 0 1] == "XM"} {
             # Chassis is Ixia XM type, serial number already in proper ASCII string format
             return $serialNumberEncodedHex
         }

         puts  "ERROR: Encoded serial number must be in hexadecimal format"
         return "Invalid"
      }

      if {$serialNumberEncodedHex == "0xfffffffffff"} {
         puts  "ERROR: Encoded serial number is invalid: $serialNumberEncodedHex"
         return "Invalid"
      }

      #variable ::AmcSerialCode::amcCountryCode
      # Get rid of any leading "0x" in the serial number
      set serialNumberEncodedHex [string trimleft $serialNumberEncodedHex 0x]
      # Convert serial number to binary
      set serialNumberEncodedBin [ConvertHexStringToBin $serialNumberEncodedHex]
      # Make sure serial number is 11 nibbles long. Pad with zeros on the front 
      # if it is not. Check that serial number is <= 44 bits in length

      if {[string length $serialNumberEncodedBin] > 44} {
         puts "ERROR: serialNumberEncodedHex\nSerial number is not in AMC encoded format"
         return 0
      }

      while {[string length $serialNumberEncodedBin] < 44} {
         set serialNumberEncodedBin "0$serialNumberEncodedBin"
      }

      # Split the serial number into fields
      set countryBin  [string range $serialNumberEncodedBin 0 4]
      set yearBin     [string range $serialNumberEncodedBin 5 9]
      set weekBin     [string range $serialNumberEncodedBin 10 15]
      set productBin  [string range $serialNumberEncodedBin 16 29]
      set sequenceBin [string range $serialNumberEncodedBin 30 43]
       
      set countryCodeList [array get amcCountryCode]
      set countryCodeTextIndex [lsearch -glob $countryCodeList $countryBin]
      if {$countryCodeTextIndex == -1} {
         puts "ERROR: unknown country code"
         return 0
      }
      set country [lindex $countryCodeList [expr $countryCodeTextIndex-1]]
       
      # set Year
      set year [expr [ConvertBinStringToDec $yearBin]+2001-1960]
       
      # set Week
      set week [ConvertBinStringToDec $weekBin] 
      # append a leading 0 if the week is < 10
      if {[string length $week] < 2} {
         set week "0$week"
      }
      
      # set product
      # Split productBin into two 7 bit binary numbers
      set amcProductBinChar1 [string range $productBin 0 6]
      set amcProductBinChar2 [string range $productBin 7 13]
      # Convert both chars to 8 bit binary numbers, to allow use of format 
      # command to convert to ASCII
      set amcProductBinChar1 "0$amcProductBinChar1"
      set amcProductBinChar2 "0$amcProductBinChar2"
      # convert each number to an ASCII char
      set amcProductChar1 [binary format B8 $amcProductBinChar1]
      set amcProductChar2 [binary format B8 $amcProductBinChar2]
      # concatenate the two chars into a product code
      set product "$amcProductChar1$amcProductChar2"
       
      # set amcSequence
      # Split amcSequenceBin into two 7 bit binary numbers
      set amcSequenceBinChar1 [string range $sequenceBin 0 6]
      set amcSequenceBinChar2 [string range $sequenceBin 7 13]
      # Convert both chars to 8 bit binary numbers, to allow use of format 
      # command to convert to ASCII
      set amcSequenceBinChar1 "0$amcSequenceBinChar1"
      set amcSequenceBinChar2 "0$amcSequenceBinChar2"
      # convert each number to an ASCII char
      set amcSequenceChar1 [binary format B8 $amcSequenceBinChar1]
      set amcSequenceChar2 [binary format B8 $amcSequenceBinChar2]
      # concatenate the two chars into a product code
      set sequence "$amcSequenceChar1$amcSequenceChar2"
       
      # Now concatenate all components into a standard serial number, CCYYWWSSUU
      set amcSerialNumber "$country$year$week$product$sequence"
       
      return $amcSerialNumber
   }
   
   set chassisList {}
   if { [catch {SmInvoke AgtModuleManager ListChassis} chassisList] } {
      puts $agtFd_ "Unable to communicate with resource manager"
   }
   set chassisList [lsort $chassisList]
   
   puts $agtFd_ "\nChassis ---------------------------------------------------------------------"
   foreach chassis $chassisList {
      set serialNumber 0
      if { [catch {SmInvoke AgtModuleManager GetChassisSerialNumber $chassis} serialNumber] } {
         set serialNumber "N/A"
      }
      set decodedSerialNumber [DecodeSerialNumber $serialNumber]
      #puts "decode=$decodedSerialNumber sn=$serialNumber"
      #GetChassisControllerUpgradeInfo ChassisNumber -> CardList HardwareVersion CurrentSoftwareVersion NewSoftwareVersion ProgramBlade UpgradeRequired AutoUpgradeSupported DownloadFile 
      if { [catch {SmInvoke AgtModuleManager GetChassisControllerUpgradeInfo $chassis} chassisInfo] } {
         puts $agtFd_ "ERROR retrieving chassis info..."
      }
      set firmWare [lindex $chassisInfo 2]
      puts $agtFd_ "Chassis: [format "%-2s" $chassis]  Serial: [format "%-12s" $decodedSerialNumber]   Firmware: [format "%-12s" $firmWare]"
   }
   #--------------------------------------------------------------------------
   # Card information
   #--------------------------------------------------------------------------
   puts $agtFd_ "\nTest Cards ------------------------------------------------------------------"
   set cardList [AgtInvoke AgtModuleManager ListModules]
   foreach card $cardList {
      if {$card <= 6500} {
         set serialNumber [AgtInvoke AgtModuleManager GetSerialNumber $card]
         set cardType [AgtInvoke AgtModuleManager GetModuleType $serialNumber]
         puts $agtFd_ "Card:[format "%4s" $card]  Serial: [format "%-12s" $serialNumber]  Type: [format "%-2s" $cardType]"
      }
   }
   #--------------------------------------------------------------------------
   # User and Version information
   #--------------------------------------------------------------------------
   puts $agtFd_ "\nN2X Versions ----------------------------------------------------------------"
   set installedVersions [AgtListSessionVersions RouterTester900]
   puts $agtFd_ "Installed Versions:  "
   foreach version $installedVersions {
      puts $agtFd_ "         $version"
   }
   
   puts $agtFd_ "\nCurrent Sessions ------------------------------------------------------------"
   set sessionList [AgtListOpenSessions]
   foreach session $sessionList {
      set sessionVer [AgtGetSessionVersion $session]
      set sessionLabel [AgtGetSessionLabel $session]
      puts $agtFd_ "Label: [format "%-20s" $sessionLabel]   Version: [format "%-32s" $sessionVer]   Handle: [format "%-2s" $session]"
   }
   puts $agtFd_ "\n\n\n\n"
}


# Close Log Files
if { $agtFd_ != 0 } {
    close $agtFd_
}

